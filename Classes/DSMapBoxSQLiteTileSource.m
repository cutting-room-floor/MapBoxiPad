//
//  DSMapBoxSQLiteTileSource.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/18/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxSQLiteTileSource.h"
#import "RMTileImage.h"
#import "RMProjection.h"
#import "RMFractalTileProjection.h"
#import "FMDatabase.h"
#import "DSMapBoxTileSetManager.h"

@interface DSMapBoxSQLiteTileSource (DSMapBoxSQLiteTileSourcePrivate)

- (void)reload:(NSNotification *)notification;

@end

#pragma mark -

@implementation DSMapBoxSQLiteTileSource

- (id)init
{
    return [self initWithTileSetAtURL:[[DSMapBoxTileSetManager defaultManager] activeTileSetURL]];
}

- (id)initWithTileSetAtURL:(NSURL *)tileSetURL
{
	if ( ! [super init])
		return nil;
	
	tileProjection = [[RMFractalTileProjection alloc] initFromProjection:[self projection] 
                                                          tileSideLength:kDSDefaultTileSize 
                                                                 maxZoom:kDSDefaultMaxTileZoom 
                                                                 minZoom:kDSDefaultMinTileZoom];
	
    db = [[FMDatabase databaseWithPath:[tileSetURL relativePath]] retain];
    
    if ( ! [db open])
        return nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reload:)
                                                 name:DSMapBoxTileSetChangedNotification
                                               object:nil];
    
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxTileSetChangedNotification object:nil];
    
	[tileProjection release];
    
    [db close];
    [db release];
    
	[super dealloc];
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
    NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f", 
			  self, tile.zoom, self.minZoom, self.maxZoom);

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
    FMResultSet *results = [db executeQuery:@"select min(zoom_level) from tiles"];
    
    if ([db hadError])
        return kDSDefaultMinTileZoom;
    
    [results next];
    
    double minZoom = [results doubleForColumnIndex:0];
    
    [results close];
    
    return (float)minZoom;
}

- (float)maxZoom
{
    FMResultSet *results = [db executeQuery:@"select max(zoom_level) from tiles"];
    
    if ([db hadError])
        return kDSDefaultMaxTileZoom;

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
    return kDSDefaultLatLonBoundingBox;
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"*** didReceiveMemoryWarning in %@", [self class]);
}

- (NSString *)uniqueTilecacheKey
{
    return [[[[DSMapBoxTileSetManager defaultManager] activeTileSetURL] path] lastPathComponent];
}

- (NSString *)shortName
{
    return @"MapBoxSQLite";
}

- (NSString *)longDescription
{
    return @"MapBox local SQLite store";
}

- (NSString *)shortAttribution
{
    return @"© Development Seed";
}

- (NSString *)longAttribution
{
    return @"Map data © Development Seed";
}

- (void)removeAllCachedImages
{
    NSLog(@"*** removeAllCachedImages in %@", [self class]);
}

#pragma mark -

- (void)reload:(NSNotification *)notification
{
    [db close];
    [db release];
    
    db = [[FMDatabase databaseWithPath:[[[DSMapBoxTileSetManager defaultManager] activeTileSetURL] relativePath]] retain];
    
    [db open];
}

@end