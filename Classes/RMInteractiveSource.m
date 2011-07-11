//
//  RMInteractiveSource.m
//  MapBoxiPad
//
//  Created by Justin Miller on 6/22/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "RMInteractiveSource.h"

#import "JSONKit.h"

#import "FMDatabase.h"

#include "zlib.h"

@implementation RMMBTilesTileSource (RMInteractiveSource)

- (NSString *)description
{
    return [NSString stringWithFormat:@"MBTiles: %@, zooms %i-%i, %@, %@", 
               [self shortName], 
               (int)[self minZoomNative], 
               (int)[self maxZoomNative], 
               ([self coversFullWorld] ? @"full world" : @"partial world"),
               ([self supportsInteractivity] ? @"supports interactivity" : @"no interactivity")];
}

- (BOOL)supportsInteractivity
{
    return ([self interactivityFormatterJavascript] != nil);
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile
{
    FMResultSet *results = [db executeQuery:@"select grid from grids where zoom_level = ? and tile_column = ? and tile_row = ?", 
                               [NSNumber numberWithShort:tile.zoom], 
                               [NSNumber numberWithUnsignedInt:tile.x], 
                               [NSNumber numberWithUnsignedInt:tile.y]];
    
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
            NSArray *rows = [grid objectForKey:@"grid"];
            NSArray *keys = [grid objectForKey:@"keys"];
            
            if (rows && [rows count] > 0)
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
                        
                        NSString *keyName = nil;
                        
                        if (decoded < [keys count])
                            keyName = [keys objectAtIndex:decoded];
                        
                        if (keyName)
                        {
                            // get JSON for this grid point
                            //
                            results = [db executeQuery:@"select key_json from grid_data where zoom_level = ? and tile_column = ? and tile_row = ? and key_name = ?", 
                                          [NSNumber numberWithShort:tile.zoom],
                                          [NSNumber numberWithShort:tile.x],
                                          [NSNumber numberWithShort:tile.y],
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

@end

@implementation RMTileStreamSource (RMInteractiveSource)

- (NSString *)description
{
    return [NSString stringWithFormat:@"TileStream: %@, zooms %i-%i, %@, %@", 
               [self shortName], 
               (int)[self minZoomNative], 
               (int)[self maxZoomNative], 
               ([self coversFullWorld] ? @"full world" : @"partial world"),
               ([self supportsInteractivity] ? @"supports interactivity" : @"no interactivity")];
}

- (BOOL)supportsInteractivity
{
    return ([self interactivityFormatterJavascript] != nil);
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile
{
    if ([self.infoDictionary objectForKey:@"gridURL"])
    {
        NSInteger zoom = tile.zoom;
        NSInteger x    = tile.x;
        NSInteger y    = tile.y;
        
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
                NSArray      *rows = [grid objectForKey:@"grid"];
                NSArray      *keys = [grid objectForKey:@"keys"];
                NSDictionary *data = [grid objectForKey:@"data"];
                
                if (rows && [rows count] > 0)
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
                            
                            NSString *keyName = nil;
                            
                            if (decoded < [keys count])
                                keyName = [keys objectAtIndex:decoded];
                            
                            if (keyName)
                            {
                                return [NSDictionary dictionaryWithObjectsAndKeys:keyName,                                  @"keyName",
                                                                                  [[data objectForKey:keyName] JSONString], @"keyJSON",
                                                                                  nil];
                            }
                        }
                    }
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

@end

@implementation RMCachedTileSource (RMInteractiveSource)

- (BOOL)supportsInteractivity
{
    return ([tileSource isKindOfClass:[RMTileStreamSource class]] && [tileSource conformsToProtocol:@protocol(RMInteractiveSource)] && [(id <RMInteractiveSource>)tileSource supportsInteractivity]);
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile
{
    if ([self supportsInteractivity])
        return [(id <RMInteractiveSource>)tileSource interactivityDictionaryForPoint:point inTile:tile];
    
    return nil;
}

- (NSString *)interactivityFormatterJavascript
{
    if ([self supportsInteractivity])
        return [(id <RMInteractiveSource>)tileSource interactivityFormatterJavascript];
    
    return nil;
}

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

