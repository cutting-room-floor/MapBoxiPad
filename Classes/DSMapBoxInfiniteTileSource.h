//
//  DSMapBoxInfiniteTileSource.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 4/22/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "RMMBTilesTileSource.h"

#define kDSMapBoxInifiniteTileSize 256
#define kDSMapBoxInifiniteMinTileZoom 0
#define kDSMapBoxInifiniteMaxTileZoom 22
#define kDSMapBoxInfiniteLatLonBoundingBox ((RMSphericalTrapezium){ .northeast = { .latitude =  85, .longitude =  180 }, \
                                                                    .southwest = { .latitude = -85, .longitude = -180 } })

@interface DSMapBoxInfiniteTileSource : RMMBTilesTileSource <RMTileSource>
{
}

- (int)tileSideLength;
- (void)setTileSideLength:(NSUInteger)aTileSideLength;
- (RMTileImage *)tileImage:(RMTile)tile;
- (NSString *)tileURL:(RMTile)tile;
- (NSString *)tileFile:(RMTile)tile;
- (NSString *)tilePath;
- (id <RMMercatorToTileProjection>)mercatorToTileProjection;
- (RMProjection *)projection;
- (float)minZoom;
- (float)maxZoom;
- (void)setMinZoom:(NSUInteger)aMinZoom;
- (void)setMaxZoom:(NSUInteger)aMaxZoom;
- (RMSphericalTrapezium)latitudeLongitudeBoundingBox;
- (BOOL)coversFullWorld;
- (void)didReceiveMemoryWarning;
- (NSString *)uniqueTilecacheKey;
- (NSString *)shortName;
- (NSString *)longDescription;
- (NSString *)shortAttribution;
- (NSString *)longAttribution;
- (void)removeAllCachedImages;

@end