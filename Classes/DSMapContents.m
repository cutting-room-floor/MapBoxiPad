//
//  DSMapContents.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/21/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapContents.h"
#import "DSMapBoxSQLiteTileSource.h"
#import "DSMapBoxMarkerManager.h"

#import "RMProjection.h"
#import "RMTileLoader.h"
#import "RMMercatorToTileProjection.h"
#import "RMMapView.h"
#import "RMMercatorToScreenProjection.h"

#define kLowerZoomBounds       2.5f
#define kUpperLatitudeBounds  85.0f
#define kLowerLatitudeBounds -60.0f

@implementation DSMapContents

@synthesize layerMapViews;

- (id)initWithView:(UIView*)newView
		tilesource:(id<RMTileSource>)newTilesource
	  centerLatLon:(CLLocationCoordinate2D)initialCenter
		 zoomLevel:(float)initialZoomLevel
	  maxZoomLevel:(float)maxZoomLevel
	  minZoomLevel:(float)minZoomLevel
   backgroundImage:(UIImage *)backgroundImage
{
    self = [super initWithView:newView 
                    tilesource:newTilesource 
                  centerLatLon:initialCenter 
                     zoomLevel:initialZoomLevel 
                  maxZoomLevel:maxZoomLevel 
                  minZoomLevel:minZoomLevel 
               backgroundImage:backgroundImage];
    
    if (self)
    {
        [markerManager release];
        
        markerManager = [[DSMapBoxMarkerManager alloc] initWithContents:self];

        self.tileDepth = 3;
    }
    
    return self;
}

- (void)dealloc
{
    [layerMapViews release];
    
    [super dealloc];
}

#pragma mark -

- (void)moveToLatLong: (CLLocationCoordinate2D)latlong
{
    [super moveToLatLong:latlong];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents moveToLatLong:latlong];
}

- (void)moveToProjectedPoint: (RMProjectedPoint)aPoint
{
    [super moveToProjectedPoint:aPoint];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents moveToProjectedPoint:aPoint];
}

- (void)moveBy:(CGSize)delta
{
    if ([self canMoveBy:delta])
    {
        [super moveBy:delta];
        
        if (self.layerMapViews)
            for (RMMapView *layerMapView in layerMapViews)
                [layerMapView.contents moveBy:delta];
    }
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)pivot animated:(BOOL)animated withCallback:(id <RMMapContentsAnimationCallback>)callback
{
    // borrowed from super
    //
    zoomFactor = [self adjustZoomForBoundingMask:zoomFactor];
    float zoomDelta = log2f(zoomFactor);
    float targetZoom = zoomDelta + [self zoom];
    //
    // end borrowed code
	
    if (targetZoom < kLowerZoomBounds)
    {
        //NSLog(@"returning early since target = %f", targetZoom);
        
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:((DSMapBoxMarkerManager *)self.markerManager) selector:@selector(recalculateClusters) object:nil];
    
    [super zoomByFactor:zoomFactor near:pivot animated:animated withCallback:callback];
    
    //NSLog(@"new zoom: %f", self.zoom);
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents zoomByFactor:zoomFactor near:pivot animated:animated withCallback:callback];
    
    if ([self.markerManager markers])
        [((DSMapBoxMarkerManager *)self.markerManager) performSelector:@selector(recalculateClusters) withObject:nil afterDelay:0.1];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(postZoom) object:nil];
    [self performSelector:@selector(postZoom) withObject:nil afterDelay:0.1];
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

#pragma mark -

- (BOOL)canMoveBy:(CGSize)delta
{
    //NSLog(@"=====");

    //NSLog(@"dX: %f", delta.width);
    //NSLog(@"dY: %f", delta.height);
    
    // top left
    //
    RMProjectedPoint currentTopLeftProj  = [mercatorToScreenProjection projectScreenPointToXY:CGPointMake(0, 0)];
    //RMLatLong        currentTopLeftCoord = [projection pointToLatLong:currentTopLeftProj];

    //NSLog(@"current top:  %f", currentTopLeftCoord.latitude);
    //NSLog(@"current left: %f", currentTopLeftCoord.longitude);
    
    RMProjectedPoint proposedTopLeftProj = {
        .easting  = currentTopLeftProj.easting  - (delta.width  * self.metersPerPixel),
        .northing = currentTopLeftProj.northing + (delta.height * self.metersPerPixel),
    };
    
    RMLatLong        proposedTopLeftCoord = [projection pointToLatLong:proposedTopLeftProj];
    
    //NSLog(@"proposed top:  %f", proposedTopLeftCoord.latitude);
    //NSLog(@"proposed left: %f", proposedTopLeftCoord.longitude);
    
    // bottom right
    //
    CGPoint          currentBottomRightPoint = CGPointMake([mercatorToScreenProjection screenBounds].size.width, 
                                                           [mercatorToScreenProjection screenBounds].size.height);
    
    RMProjectedPoint currentBottomRightProj  = [mercatorToScreenProjection projectScreenPointToXY:currentBottomRightPoint];
    //RMLatLong        currentBottomRightCoord = [projection pointToLatLong:currentBottomRightProj];

    //NSLog(@"current bottom:  %f", currentBottomRightCoord.latitude);
    //NSLog(@"current right:   %f", currentBottomRightCoord.longitude);
    
    RMProjectedPoint proposedBottomRightProj = {
        .easting  = currentBottomRightProj.easting  - (delta.width  * self.metersPerPixel),
        .northing = currentBottomRightProj.northing + (delta.height * self.metersPerPixel),
    };
    
    RMLatLong        proposedBottomRightCoord = [projection pointToLatLong:proposedBottomRightProj];
    
    //NSLog(@"proposed bottom:  %f", proposedBottomRightCoord.latitude);
    //NSLog(@"proposed right:   %f", proposedBottomRightCoord.longitude);
    
    // check limits
    //
    if (delta.height > 0 && proposedTopLeftCoord.latitude      >=  kUpperLatitudeBounds)
        return NO;

    if (delta.height < 0 && proposedBottomRightCoord.latitude  <=  kLowerLatitudeBounds)
        return NO;

    return YES;
}

- (void)postZoom
{
    RMProjectedPoint currentTopLeftProj      = [mercatorToScreenProjection projectScreenPointToXY:CGPointMake(0, 0)];
    RMLatLong        currentTopLeftCoord     = [projection pointToLatLong:currentTopLeftProj];

    CGPoint          currentBottomRightPoint = CGPointMake([mercatorToScreenProjection screenBounds].size.width, 
                                                           [mercatorToScreenProjection screenBounds].size.height);
    
    RMProjectedPoint currentBottomRightProj  = [mercatorToScreenProjection projectScreenPointToXY:currentBottomRightPoint];
    RMLatLong        currentBottomRightCoord = [projection pointToLatLong:currentBottomRightProj];
    
    if (currentTopLeftCoord.latitude > kUpperLatitudeBounds)
    {
        RMLatLong newTopLeftCoord = {
            .latitude = kUpperLatitudeBounds,
            .longitude = currentTopLeftCoord.longitude,
        };
        
        RMProjectedPoint newTopLeftProj = {
            .easting = currentTopLeftProj.easting,
            .northing = [projection latLongToPoint:newTopLeftCoord].northing,
        };
        
        RMProjectedPoint newCenterProj = {
            .easting  = newTopLeftProj.easting  + (([mercatorToScreenProjection screenBounds].size.width  * self.metersPerPixel) / 2),
            .northing = newTopLeftProj.northing - (([mercatorToScreenProjection screenBounds].size.height * self.metersPerPixel) / 2),
        };
        
        [self moveToProjectedPoint:newCenterProj];
    }
    else if (currentBottomRightCoord.latitude < kLowerLatitudeBounds)
    {
        RMLatLong newBottomRightCoord = {
            .latitude = kLowerLatitudeBounds,
            .longitude = currentBottomRightCoord.longitude,
        };
        
        RMProjectedPoint newBottomRightProj = {
            .easting = currentBottomRightProj.easting,
            .northing = [projection latLongToPoint:newBottomRightCoord].northing,
        };
        
        RMProjectedPoint newCenterProj = {
            .easting  = newBottomRightProj.easting  - (([mercatorToScreenProjection screenBounds].size.width  * self.metersPerPixel) / 2),
            .northing = newBottomRightProj.northing + (([mercatorToScreenProjection screenBounds].size.height * self.metersPerPixel) / 2),
        };
        
        [self moveToProjectedPoint:newCenterProj];
    }
}

@end