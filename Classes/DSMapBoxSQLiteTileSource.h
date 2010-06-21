//
//  DSMapBoxSQLiteTileSource.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/18/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RMTileSource.h"

@class RMFractalTileProjection;
@class FMDatabase;

#define kDSDefaultTileSize 256
#define kDSDefaultMinTileZoom 0
#define kDSDefaultMaxTileZoom 18
#define kDSDefaultLatLonBoundingBox ((RMSphericalTrapezium){.northeast = {.latitude = 90, .longitude = 180}, .southwest = {.latitude = -90, .longitude = -180}})

@interface DSMapBoxSQLiteTileSource : NSObject <RMTileSource>
{
    RMFractalTileProjection *tileProjection;
    FMDatabase *db;
}

-(id) init;
-(int) tileSideLength;
-(void) setTileSideLength: (NSUInteger) aTileSideLength;
-(RMTileImage *) tileImage: (RMTile) tile;
-(NSString *) tileURL: (RMTile) tile;
-(NSString *) tileFile: (RMTile) tile;
-(NSString *) tilePath;
-(id<RMMercatorToTileProjection>) mercatorToTileProjection;
-(RMProjection*) projection;
-(float) minZoom;
-(float) maxZoom;
-(void) setMinZoom:(NSUInteger) aMinZoom;
-(void) setMaxZoom:(NSUInteger) aMaxZoom;
-(RMSphericalTrapezium) latitudeLongitudeBoundingBox;
-(void) didReceiveMemoryWarning;
-(NSString *)uniqueTilecacheKey;
-(NSString *)shortName;
-(NSString *)longDescription;
-(NSString *)shortAttribution;
-(NSString *)longAttribution;
-(void)removeAllCachedImages;

@end