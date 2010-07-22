//
//  DSMapContents.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/21/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapContents.h"
#import "DSMapBoxSQLiteTileSource.h"

#import "RMProjection.h"
#import "RMTileLoader.h"
#import "RMMercatorToTileProjection.h"

@implementation DSMapContents

- (void)removeAllCachedImages
{
    // no-op since we don't cache
    //
    return;
}

- (void)setTileSource:(DSMapBoxSQLiteTileSource *)newTileSource
{
	if (tileSource == newTileSource)
		return;
	
    tileSource = [newTileSource retain];
    
    NSAssert(([tileSource minZoom] - minZoom) <= 1.0, @"Graphics & memory are overly taxed if [contents minZoom] is more than 1.5 smaller than [tileSource minZoom]");
	
	[projection release];
	projection = [[tileSource projection] retain];
	
	[mercatorToTileProjection release];
	mercatorToTileProjection = [[tileSource mercatorToTileProjection] retain];
    
	[imagesOnScreen setTileSource:tileSource];
    
    [tileLoader reset];
	[tileLoader reload];
}

@end