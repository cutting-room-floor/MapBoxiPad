//
//  DSMapBoxTileSource.m
//  SimpleMap
//
//  Created by Justin R. Miller on 6/15/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxTileSource.h"

@implementation DSMapBoxTileSource

-(NSString*) tileURL: (RMTile) tile
{
	NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
			  @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f", 
			  self, tile.zoom, self.minZoom, self.maxZoom);
    
    NSLog(@"in: %i, %i, %i", tile.zoom, tile.x, tile.y);
    
    NSInteger zoom = tile.zoom;
    NSInteger x    = tile.x;
    NSInteger y    = pow(2, zoom) - tile.y - 1;

    NSLog(@"out: %i, %i, %i", zoom, x, y);

    NSString *path = [NSString stringWithFormat:@"http://mapbox.dev/world-light/%d/%d/%d.png", zoom, x, y];
    
    //NSLog(@"loading %@", path);
    
    return path;
}

-(float) minZoom
{
    return 0.0;
}

-(float) maxZoom
{
    return 10.0;
}

-(NSString*) uniqueTilecacheKey
{
	return @"MapBox";
}

-(NSString *)shortName
{
	return @"MapBox";
}
-(NSString *)longDescription
{
	return @"MapBox: more info goes here";
}
-(NSString *)shortAttribution
{
	return @"© MapBox";
}
-(NSString *)longAttribution
{
	return @"Map data © MapBox.";
}

@end