//
//  RMInteractiveSource.m
//  MapBoxiPad
//
//  Created by Justin Miller on 6/22/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "RMInteractiveSource.h"

#import "RMMapView.h"
#import "RMMapContents.h"
#import "RMLatLong.h"

#import "FMDatabase.h"

#import "JSONKit.h"

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#include "zlib.h"

#pragma mark Private Utilities

RMTilePoint RMInteractiveSourceNormalizedTilePointForMapView(CGPoint point, RMMapView *mapView);

RMTilePoint RMInteractiveSourceNormalizedTilePointForMapView(CGPoint point, RMMapView *mapView)
{
    // determine renderer scroll layer sub-layer touched
    //
    CALayer *rendererLayer = [mapView.contents.renderer valueForKey:@"layer"];
    CALayer *tileLayer     = [rendererLayer hitTest:point];
    
    // convert touch to sub-layer
    //
    CGPoint layerPoint = [tileLayer convertPoint:point fromLayer:rendererLayer];
    
    // normalize tile touch to 256px
    //
    // TODO: assert that tile side length is 256
    //
    float normalizedX = (layerPoint.x / tileLayer.bounds.size.width)  * 256;
    float normalizedY = (layerPoint.y / tileLayer.bounds.size.height) * 256;

    // determine lat & lon of touch
    //
    RMLatLong touchLocation = [mapView.contents pixelToLatLong:point];
    
    // use lat & lon to determine TMS tile (per http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
    //
    int tileZoom = (int)(roundf(mapView.contents.zoom));
    
    int tileX = (int)(floor((touchLocation.longitude + 180.0) / 360.0 * pow(2.0, tileZoom)));
    int tileY = (int)(floor((1.0 - log(tan(touchLocation.latitude * M_PI / 180.0) + 1.0 / \
                                       cos(touchLocation.latitude * M_PI / 180.0)) / M_PI) / 2.0 * pow(2.0, tileZoom)));
    
    tileY = pow(2.0, tileZoom) - tileY - 1.0;
    
    RMTile tile = {
        .zoom = tileZoom,
        .x    = tileX,
        .y    = tileY,
    };
    
    RMTilePoint tilePoint;
    
    tilePoint.tile   = tile;
    tilePoint.offset = CGPointMake(normalizedX, normalizedY);
    
    return tilePoint;
}

@interface RMInteractiveSource : NSObject

+ (NSString *)keyNameForPoint:(CGPoint)point inGrid:(NSDictionary *)grid;
+ (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)type forPoint:(CGPoint)point inMapView:(RMMapView *)mapView;

@end

@implementation RMInteractiveSource

+ (NSString *)keyNameForPoint:(CGPoint)point inGrid:(NSDictionary *)grid
{
    NSString *keyName = nil;

    if ([grid objectForKey:@"grid"] && [grid objectForKey:@"keys"])
    {
        NSArray *rows = [grid objectForKey:@"grid"];
        NSArray *keys = [grid objectForKey:@"keys"];
    
        if (rows && [rows isKindOfClass:[NSArray class]] && keys && [keys isKindOfClass:[NSArray class]])
        {
            if ([rows count] > 0)
            {
                // get grid coordinates per https://github.com/mapbox/mbtiles-spec/blob/master/1.1/utfgrid.md
                //
                int factor = 256 / [rows count];
                int row    = point.y / factor;
                int col    = point.x / factor;
                
                if (row < [rows count])
                {
                    NSString *line = [rows objectAtIndex:row];
                    
                    if (col < [line length])
                    {
                        unichar theChar = [line characterAtIndex:col];
                        unsigned short decoded = theChar;
                        
                        if (decoded >= 93)
                            decoded--;
                        
                        if (decoded >=35)
                            decoded--;
                        
                        decoded = decoded - 32;
                        
                        if (decoded < [keys count])
                            keyName = [keys objectAtIndex:decoded];
                    }
                }
            }
        }
    }

    return keyName;
}

+ (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView
{
    NSString *formattedOutput = nil;
    
    id <RMTileSource>source = mapView.contents.tileSource;
    
    NSDictionary *interactivityDictionary = [(id <RMInteractiveSource>)source interactivityDictionaryForPoint:point inMapView:mapView];
    NSString     *formatterJavascript     = [(id <RMInteractiveSource>)source interactivityFormatterJavascript];
    
    if (interactivityDictionary && formatterJavascript)
    {
        UIWebView *formatter = [[[UIWebView alloc] initWithFrame:CGRectZero] autorelease];
        
        NSString  *keyJSON = [interactivityDictionary objectForKey:@"keyJSON"];
        
        [formatter stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var data   = %@;", keyJSON]];
        [formatter stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var format = %@;", formatterJavascript]];
        
        NSString *format;
        
        switch (outputType)
        {
            case RMInteractiveSourceOutputTypeTeaser:
                format = @"teaser";
                break;

            case RMInteractiveSourceOutputTypeFull:
            default:
                format = @"full";
                break;
        }
        
        [formatter stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var options = { format: '%@' }", format]];
        
        formattedOutput = [formatter stringByEvaluatingJavaScriptFromString:@"format(options, data);"];
    }
    
    return formattedOutput;
}

@end

@interface NSData (RMInteractiveSource)

- (NSData *)gzipInflate;

@end

@implementation NSData (RMInteractiveSource)

- (NSData *)gzipInflate
{
    // from http://cocoadev.com/index.pl?NSDataCategory
    //
    if ([self length] == 0) return self;
    
    unsigned full_length = [self length];
    unsigned half_length = [self length] / 2;
    
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO;
    int status;
    
    z_stream strm;
    strm.next_in = (Bytef *)[self bytes];
    strm.avail_in = [self length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done)
    {
        // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length])
            [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = [decompressed length] - strm.total_out;
        
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END) done = YES;
        else if (status != Z_OK) break;
    }
    if (inflateEnd (&strm) != Z_OK) return nil;
    
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return [NSData dataWithData: decompressed];
    }
    else return nil;
}

@end

#pragma mark -
#pragma mark MBTiles Interactivity

@implementation RMMBTilesTileSource (RMMBTilesTileSourceInteractive)

- (NSString *)description
{
    return [NSString stringWithFormat:@"MBTiles: %@, zooms %i-%i, %@", 
               [self shortName], 
               (int)[self minZoom], 
               (int)[self maxZoom], 
               ([self supportsInteractivity] ? @"supports interactivity" : @"no interactivity")];
}

- (BOOL)supportsInteractivity
{
    return ([self interactivityFormatterJavascript] && [[self interactivityFormatterJavascript] length]);
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
{
    RMTilePoint tilePoint = RMInteractiveSourceNormalizedTilePointForMapView(point, mapView);
    
    FMResultSet *results = [db executeQuery:@"select grid from grids where zoom_level = ? and tile_column = ? and tile_row = ?", 
                               [NSNumber numberWithShort:tilePoint.tile.zoom], 
                               [NSNumber numberWithUnsignedInt:tilePoint.tile.x], 
                               [NSNumber numberWithUnsignedInt:tilePoint.tile.y]];
    
    if ([db hadError])
        return nil;
    
    [results next];
    
    NSData *gridData = nil;
    
    if ([results hasAnotherRow])
        gridData = [results dataForColumnIndex:0];
    
    [results close];
    
    if (gridData)
    {
        NSData *inflatedData = [gridData gzipInflate];
        NSString *gridString = [[[NSString alloc] initWithData:inflatedData encoding:NSUTF8StringEncoding] autorelease];
        
        id grid = [gridString objectFromJSONString];
        
        if (grid && [grid isKindOfClass:[NSDictionary class]])
        {
            NSString *keyName = [RMInteractiveSource keyNameForPoint:tilePoint.offset inGrid:grid];
            
            if (keyName)
            {
                // get JSON for this grid point
                //
                results = [db executeQuery:@"select key_json from grid_data where zoom_level = ? and tile_column = ? and tile_row = ? and key_name = ?", 
                              [NSNumber numberWithShort:tilePoint.tile.zoom],
                              [NSNumber numberWithShort:tilePoint.tile.x],
                              [NSNumber numberWithShort:tilePoint.tile.y],
                              keyName];
                
                if ([db hadError])
                    return nil;
                
                [results next];
                
                NSString *jsonString = nil;
                
                if ([results hasAnotherRow])
                    jsonString = [results stringForColumn:@"key_json"];
                
                [results close];
                
                if (jsonString)
                {
                    return [NSDictionary dictionaryWithObjectsAndKeys:keyName,    @"keyName",
                                                                      jsonString, @"keyJSON", 
                                                                      nil];
                }
            }
        }
    }
    
    return nil;    
}

- (NSString *)interactivityFormatterJavascript
{
    FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'formatter'"];
    
    if ([db hadError])
        return nil;
    
    [results next];
    
    NSString *js = nil;
    
    if ([results hasAnotherRow])
        js = [results stringForColumn:@"value"];
    
    [results close];
    
    return js;
}

- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView
{
    if ([self supportsInteractivity])
        return [RMInteractiveSource formattedOutputOfType:outputType forPoint:point inMapView:mapView];
    
    return nil;
}

@end

#pragma mark -
#pragma mark TileStream Interactivity

@implementation RMTileStreamSource (RMTileStreamSourceInteractive)

- (NSString *)description
{
    return [NSString stringWithFormat:@"TileStream: %@, zooms %i-%i, %@", 
               [self shortName], 
               (int)[self minZoom], 
               (int)[self maxZoom], 
               ([self supportsInteractivity] ? @"supports interactivity" : @"no interactivity")];
}

- (BOOL)supportsInteractivity
{
    return ([self interactivityFormatterJavascript] && [[self interactivityFormatterJavascript] length]);
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
{
    if ([self.infoDictionary objectForKey:@"gridURL"])
    {
        RMTilePoint tilePoint = RMInteractiveSourceNormalizedTilePointForMapView(point, mapView);
        
        NSInteger zoom = tilePoint.tile.zoom;
        NSInteger x    = tilePoint.tile.x;
        NSInteger y    = tilePoint.tile.y;
        
        NSString *gridURLString = [self.infoDictionary objectForKey:@"gridURL"];
        
        gridURLString = [gridURLString stringByReplacingOccurrencesOfString:@"{z}" withString:[[NSNumber numberWithInteger:zoom] stringValue]];
        gridURLString = [gridURLString stringByReplacingOccurrencesOfString:@"{x}" withString:[[NSNumber numberWithInteger:x]    stringValue]];
        gridURLString = [gridURLString stringByReplacingOccurrencesOfString:@"{y}" withString:[[NSNumber numberWithInteger:y]    stringValue]];

        // ensure JSONP format
        //
        if ( ! [gridURLString hasSuffix:@"?callback=grid"])
            gridURLString = [gridURLString stringByAppendingString:@"?callback=grid"];

        // get the data for this tile
        //
        NSData *gridData = [NSData dataWithContentsOfURL:[NSURL URLWithString:gridURLString]];
        
        if (gridData)
        {
            NSMutableString *gridString = [[[NSMutableString alloc] initWithData:gridData encoding:NSUTF8StringEncoding] autorelease];
            
            // remove JSONP 'grid(' and ');' bits
            //
            if ([gridString hasPrefix:@"grid("])
            {
                [gridString replaceCharactersInRange:NSMakeRange(0, 5)                       withString:@""];
                [gridString replaceCharactersInRange:NSMakeRange([gridString length] - 2, 2) withString:@""];
            }
            
            id grid = [gridString objectFromJSONString];
            
            if (grid && [grid isKindOfClass:[NSDictionary class]])
            {
                NSString *keyName = [RMInteractiveSource keyNameForPoint:tilePoint.offset inGrid:grid];
                
                if (keyName)
                {
                    NSDictionary *data = [grid objectForKey:@"data"];
                    
                    if (data)                    
                        return [NSDictionary dictionaryWithObjectsAndKeys:keyName,                                  @"keyName",
                                                                          [[data objectForKey:keyName] JSONString], @"keyJSON",
                                                                          nil];
                }
            }
        }
    }
    
    return nil;    
}

- (NSString *)interactivityFormatterJavascript
{
    if ([self.infoDictionary objectForKey:@"formatter"])
        return [self.infoDictionary objectForKey:@"formatter"];
    
    return nil;
}

- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView
{
    if ([self supportsInteractivity])
        return [RMInteractiveSource formattedOutputOfType:outputType forPoint:point inMapView:mapView];
    
    return nil;
}

@end

#pragma mark -
#pragma mark Cached Source Interactivity

@implementation RMCachedTileSource (RMCachedTileSourceInteractive)

- (BOOL)supportsInteractivity
{
    /**
     * Cached tile sources have an internal, underlying `tileSource` that
     * points to the original source. Check if that is a supported type
     * and if so, if it supports interactivity.
     */

    NSArray *supportedClasses = [NSArray arrayWithObjects:[RMMBTilesTileSource class], [RMTileStreamSource class], nil];
    
    if ([supportedClasses containsObject:[tileSource class]] && [tileSource conformsToProtocol:@protocol(RMInteractiveSource)])
        return [(id <RMInteractiveSource>)tileSource supportsInteractivity];
    
    return NO;
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inMapView:(RMMapView *)mapView;
{
    if ([self supportsInteractivity])
        return [(id <RMInteractiveSource>)tileSource interactivityDictionaryForPoint:point inMapView:mapView];
    
    return nil;
}

- (NSString *)interactivityFormatterJavascript
{
    if ([self supportsInteractivity])
        return [(id <RMInteractiveSource>)tileSource interactivityFormatterJavascript];
    
    return nil;
}

- (NSString *)formattedOutputOfType:(RMInteractiveSourceOutputType)outputType forPoint:(CGPoint)point inMapView:(RMMapView *)mapView
{
    if ([self supportsInteractivity])
        return [RMInteractiveSource formattedOutputOfType:outputType forPoint:point inMapView:mapView];
    
    return nil;
}

@end