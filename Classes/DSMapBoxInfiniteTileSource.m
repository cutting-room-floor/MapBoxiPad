//
//  DSMapBoxInfiniteTileSource.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 4/22/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxInfiniteTileSource.h"

#import "RMTileImage.h"
#import "RMProjection.h"
#import "RMFractalTileProjection.h"

@implementation DSMapBoxInfiniteTileSource

- (id)init
{
	if ( ! [super initWithTileSetURL:nil])
		return nil;
	
    [tileProjection release];
    
	tileProjection = [[RMFractalTileProjection alloc] initFromProjection:[self projection] 
                                                          tileSideLength:kDSMapBoxInifiniteTileSize 
                                                                 maxZoom:kDSMapBoxInifiniteMaxTileZoom
                                                                 minZoom:kDSMapBoxInifiniteMinTileZoom];
    
	return self;
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
    return [RMTileImage dummyTile:tile];
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
    return kDSMapBoxInifiniteMinTileZoom;
}

- (float)maxZoom
{
    return kDSMapBoxInifiniteMaxTileZoom;
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
    return kDSMapBoxInfiniteLatLonBoundingBox;
}

- (BOOL)coversFullWorld
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"*** didReceiveMemoryWarning in %@", [self class]);
}

- (NSString *)uniqueTilecacheKey
{
    return NSStringFromClass([self class]);
}

- (NSString *)shortName
{
    return @"Infinite tile source";
}

- (NSString *)longDescription
{
    return @"Placeholder infinite tile source with no limits";
}

- (NSString *)shortAttribution
{
    return nil;
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
    return NO;
}

- (NSDictionary *)interactivityDictionaryForPoint:(CGPoint)point inTile:(RMTile)tile
{
    return nil;
}

- (NSString *)interactivityFormatterJavascript
{
    return nil;
}

@end