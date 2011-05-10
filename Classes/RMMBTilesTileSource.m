//
//  RMMBTilesTileSource.m
//
//  Created by Justin R. Miller on 6/18/10.
//  Copyright 2010, Code Sorcery Workshop, LLC and Development Seed, Inc.
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//  
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//  
//      * Neither the names of Code Sorcery Workshop, LLC or Development Seed,
//        Inc., nor the names of its contributors may be used to endorse or
//        promote products derived from this software without specific prior
//        written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RMMBTilesTileSource.h"
#import "RMTileImage.h"
#import "RMProjection.h"
#import "RMFractalTileProjection.h"

#import "FMDatabase.h"

#import "NSDictionary_JSONExtensions.h"

#include <zlib.h>

#pragma mark -

@interface NSData (NSData_gzipInflate)

- (NSData *)gzipInflate;

@end

#pragma mark -

@implementation NSData (NSData_gzipInflate)

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

@implementation RMMBTilesTileSource

- (id)initWithTileSetURL:(NSURL *)tileSetURL
{
	if ( ! [super init])
		return nil;
	
	tileProjection = [[RMFractalTileProjection alloc] initFromProjection:[self projection] 
                                                          tileSideLength:kMBTilesDefaultTileSize 
                                                                 maxZoom:kMBTilesDefaultMaxTileZoom 
                                                                 minZoom:kMBTilesDefaultMinTileZoom];
	
    db = [[FMDatabase databaseWithPath:[tileSetURL relativePath]] retain];
    
    if ( ! [db open])
        return nil;
    
	return self;
}

- (void)dealloc
{
	[tileProjection release];
    
    [db close];
    [db release];
    
	[super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"MBTiles: %@, zooms %i-%i, %@, %@", 
               [self shortName], 
               (int)[self minZoomNative], 
               (int)[self maxZoomNative], 
               ([self coversFullWorld] ? @"full world" : @"partial world"),
               ([self supportsInteractivity] ? @"supports interactivity" : @"no interactivity")];
}

- (int)tileSideLength
{
	return tileProjection.tileSideLength;
}

- (void)setTileSideLength:(NSUInteger)aTileSideLength
{
	[tileProjection setTileSideLength:aTileSideLength];
}

- (RMTileImage *)tileImage:(RMTile)tile
{
    NSInteger zoom = tile.zoom;
    NSInteger x    = tile.x;
    NSInteger y    = pow(2, zoom) - tile.y - 1;

    FMResultSet *results = [db executeQuery:@"select tile_data from tiles where zoom_level = ? and tile_column = ? and tile_row = ?", 
                               [NSNumber numberWithFloat:zoom], 
                               [NSNumber numberWithFloat:x], 
                               [NSNumber numberWithFloat:y]];
    
    if ([db hadError])
        return [RMTileImage dummyTile:tile];
    
    [results next];
    
    NSData *data = [results dataForColumn:@"tile_data"];

    RMTileImage *image;
    
    if ( ! data)
        if ([self layerType] == RMMBTilesLayerTypeBaselayer)
            image = [RMTileImage imageForTile:tile withData:UIImagePNGRepresentation([UIImage imageNamed:@"caution.png"])];

        else
            image = [RMTileImage dummyTile:tile];
    
    else
        image = [RMTileImage imageForTile:tile withData:data];
    
    [results close];
    
    return image;
}

- (NSString *)tileURL:(RMTile)tile
{
    return nil;
}

- (NSString *)tileFile:(RMTile)tile
{
    return nil;
}

- (NSString *)tilePath
{
    return nil;
}

- (id <RMMercatorToTileProjection>)mercatorToTileProjection
{
	return [[tileProjection retain] autorelease];
}

- (RMProjection *)projection
{
	return [RMProjection googleProjection];
}

- (float)minZoom
{
    return kMBTilesDefaultMinTileZoom;
}

- (float)minZoomNative
{
    FMResultSet *results = [db executeQuery:@"select min(zoom_level) from tiles"];
    
    if ([db hadError])
        return kMBTilesDefaultMinTileZoom;
    
    [results next];
    
    double minZoom = [results doubleForColumnIndex:0];
    
    [results close];
    
    return (float)minZoom;
}

- (float)maxZoom
{
    return kMBTilesDefaultMaxTileZoom;
}

- (float)maxZoomNative
{
    FMResultSet *results = [db executeQuery:@"select max(zoom_level) from tiles"];
    
    if ([db hadError])
        return kMBTilesDefaultMaxTileZoom;

    [results next];
    
    double maxZoom = [results doubleForColumnIndex:0];
    
    [results close];
    
    return (float)maxZoom;
}

- (void)setMinZoom:(NSUInteger)aMinZoom
{
    [tileProjection setMinZoom:aMinZoom];
}

- (void)setMaxZoom:(NSUInteger)aMaxZoom
{
    [tileProjection setMaxZoom:aMaxZoom];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'bounds'"];
    
    if ([db hadError])
        return kMBTilesDefaultLatLonBoundingBox;
    
    [results next];
    
    NSString *boundsString = [results stringForColumnIndex:0];
    
    [results close];
    
    if (boundsString)
    {
        NSArray *parts = [boundsString componentsSeparatedByString:@","];
        
        if ([parts count] == 4)
        {
            RMSphericalTrapezium bounds = {
                .southwest = {
                    .longitude = [[parts objectAtIndex:0] doubleValue],
                    .latitude  = [[parts objectAtIndex:1] doubleValue],
                },
                .northeast = {
                    .longitude = [[parts objectAtIndex:2] doubleValue],
                    .latitude  = [[parts objectAtIndex:3] doubleValue],
                },
            };
            
            return bounds;
        }
    }
    
    return kMBTilesDefaultLatLonBoundingBox;
}

- (BOOL)coversFullWorld
{
    RMSphericalTrapezium ownBounds     = [self latitudeLongitudeBoundingBox];
    RMSphericalTrapezium defaultBounds = kMBTilesDefaultLatLonBoundingBox;
    
    if (ownBounds.southwest.longitude <= defaultBounds.southwest.longitude + 10 && 
        ownBounds.northeast.longitude >= defaultBounds.northeast.longitude - 10)
        return YES;
    
    return NO;
}

- (RMMBTilesLayerType)layerType
{
    FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'type'"];
    
    if ([db hadError])
        return RMMBTilesLayerTypeBaselayer;
    
    [results next];
    
    NSString *type = nil;
    
    if ([results hasAnotherRow])
        type = [results stringForColumn:@"value"];
    
    [results close];
    
    return ([type isEqualToString:@"overlay"] ? RMMBTilesLayerTypeOverlay : RMMBTilesLayerTypeBaselayer);
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"*** didReceiveMemoryWarning in %@", [self class]);
}

- (NSString *)uniqueTilecacheKey
{
    return [NSString stringWithFormat:@"MBTiles%@", [[db databasePath] lastPathComponent]];
}

- (NSString *)shortName
{
    FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'name'"];
    
    if ([db hadError])
        return @"Unknown MBTiles";
    
    [results next];
    
    NSString *shortName = [results stringForColumnIndex:0];
    
    [results close];
    
    return shortName;
}

- (NSString *)longDescription
{
    FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'description'"];
    
    if ([db hadError])
        return @"Unknown MBTiles description";
    
    [results next];
    
    NSString *description = [results stringForColumnIndex:0];
    
    [results close];
    
    return [NSString stringWithFormat:@"%@ - %@", [self shortName], description];
}

- (NSString *)shortAttribution
{
    FMResultSet *results = [db executeQuery:@"select value from metadata where name = 'attribution'"];
    
    if ([db hadError])
        return @"Unknown MBTiles attribution";
    
    [results next];
    
    NSString *attribution = [results stringForColumnIndex:0];
    
    [results close];
    
    return attribution;
}

- (NSString *)longAttribution
{
    return [NSString stringWithFormat:@"%@ - %@", [self shortName], [self shortAttribution]];
}

- (void)removeAllCachedImages
{
    NSLog(@"*** removeAllCachedImages in %@", [self class]);
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
        
        NSError *error = nil;
        
        NSDictionary *grid = [NSDictionary dictionaryWithJSONString:gridString error:&error];

        if (grid && ! error)
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