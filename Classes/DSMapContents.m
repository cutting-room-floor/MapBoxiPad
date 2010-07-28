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
#import "RMMapView.h"

@implementation DSMapContents

@synthesize layerMapViews;

- (void)dealloc
{
    [layerMapViews release];
    
    [super dealloc];
}

#pragma mark -

- (void)moveBy:(CGSize)delta
{
    [super moveBy:delta];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents moveBy:delta];
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)pivot animated:(BOOL)animated withCallback:(id <RMMapContentsAnimationCallback>)callback
{
    [super zoomByFactor:zoomFactor near:pivot animated:animated withCallback:callback];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents zoomByFactor:zoomFactor near:pivot animated:animated withCallback:callback];
}

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