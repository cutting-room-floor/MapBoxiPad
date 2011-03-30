//
//  DSMapContents.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/21/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapContents.h"
#import "RMMBTilesTileSource.h"
#import "DSMapBoxMarkerManager.h"
#import "DSMapBoxCoreAnimationRenderer.h"
#import "DSTiledLayerMapView.h"
#import "DSMapBoxTileSetManager.h"

#import "RMProjection.h"
#import "RMTileLoader.h"
#import "RMMercatorToTileProjection.h"
#import "RMMapView.h"
#import "RMMercatorToScreenProjection.h"

#import "RMOpenStreetMapSource.h"
#import "RMCachedTileSource.h"

#import <AudioToolbox/AudioToolbox.h>

NSString *const DSMapContentsZoomBoundsReached = @"DSMapContentsZoomBoundsReached";

@interface DSMapContents (DSMapContentsPrivate)

- (BOOL)canMoveBy:(CGSize)delta;
- (BOOL)canZoomTo:(CGFloat)targetZoom limitedByLayer:(RMMapView **)limitedMapView;
- (void)postZoom;
void DSMapContents_SoundCompletionProc (SystemSoundID sound, void *clientData);
- (void)enableBoundsWarning:(NSTimer *)timer;
- (void)recalculateClustersIfNeeded;
- (void)stopRecalculatingClusters;

@end

#pragma mark -

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
        // swap out the marker manager with our custom, clustering one
        //
        [markerManager release];
        markerManager = [[DSMapBoxMarkerManager alloc] initWithContents:self];
        
        mapView = (RMMapView *)newView;
        
        boundsWarningEnabled = YES;

        // for non-overlay map views, swap in the fading renderer, then zoom to refresh it
        //
        if ( ! [newView isMemberOfClass:[DSTiledLayerMapView class]])
        {        
            [self setRenderer:[[[DSMapBoxCoreAnimationRenderer alloc] initWithContent:self] autorelease]];

            if (initialZoomLevel - 1 > minZoomLevel)
            {
                [self zoomByFactor:0.5 near:newView.center];
                [self zoomByFactor:2.0 near:newView.center];
            }
            else if (initialZoomLevel + 1 < maxZoomLevel)
            {
                [self zoomByFactor:2.0 near:newView.center];
                [self zoomByFactor:0.5 near:newView.center];
            }
        }
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
    [self stopRecalculatingClusters];
    
    [super moveToLatLong:latlong];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents moveToLatLong:latlong];

    [self recalculateClustersIfNeeded];
}

- (void)moveToProjectedPoint: (RMProjectedPoint)aPoint
{
    [self stopRecalculatingClusters];
    
    [super moveToProjectedPoint:aPoint];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents moveToProjectedPoint:aPoint];

    [self recalculateClustersIfNeeded];
}

- (void)moveBy:(CGSize)delta
{
    if ([self canMoveBy:delta])
    {
        [self stopRecalculatingClusters];
        
        [super moveBy:delta];
        
        if (self.layerMapViews)
            for (RMMapView *layerMapView in layerMapViews)
                [layerMapView.contents moveBy:delta];
        
        [self recalculateClustersIfNeeded];
    }
}

- (void)setZoom:(float)zoom
{
    [self stopRecalculatingClusters];
    
    [super setZoom:zoom];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents setZoom:zoom];
    
    [self recalculateClustersIfNeeded];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                             selector:@selector(postZoom) 
                                               object:nil];
    
    [self performSelector:@selector(postZoom) 
               withObject:nil 
               afterDelay:0.1];
}

- (void)zoomByFactor:(float)zoomFactor near:(CGPoint)pivot
{
    [self zoomByFactor:zoomFactor near:pivot animated:NO withCallback:nil];
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
    
    DSTiledLayerMapView *limitedMapView = nil;
    
    if ([self canZoomTo:targetZoom limitedByLayer:&limitedMapView])
    {
        [self stopRecalculatingClusters];
        
        [super zoomByFactor:zoomFactor near:pivot animated:NO withCallback:callback];
        
        //NSLog(@"new zoom: %f", self.zoom);
        
        if (self.layerMapViews)
            for (RMMapView *layerMapView in layerMapViews)
                [layerMapView.contents zoomByFactor:zoomFactor near:pivot animated:NO withCallback:callback];
        
        [self recalculateClustersIfNeeded];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self 
                                                 selector:@selector(postZoom) 
                                                   object:nil];

        [self performSelector:@selector(postZoom) 
                   withObject:nil 
                   afterDelay:0.1];
    }
    else if (boundsWarningEnabled && limitedMapView)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:DSMapContentsZoomBoundsReached
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObject:limitedMapView forKey:@"limitedMapView"]];
        
        boundsWarningEnabled = NO;
        
        [NSTimer scheduledTimerWithTimeInterval:2.5
                                         target:self
                                       selector:@selector(enableBoundsWarning:)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)zoomWithLatLngBoundsNorthEast:(CLLocationCoordinate2D)ne SouthWest:(CLLocationCoordinate2D)se
{
    [self stopRecalculatingClusters];
    
    [super zoomWithLatLngBoundsNorthEast:ne SouthWest:se];
    
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents zoomWithLatLngBoundsNorthEast:ne SouthWest:se];
    
    [self recalculateClustersIfNeeded];
}

- (void)enableBoundsWarning:(NSTimer *)timer
{
    boundsWarningEnabled = YES;
}

- (void)recalculateClustersIfNeeded
{
    if ([self.markerManager markers])
        [((DSMapBoxMarkerManager *)self.markerManager) performSelector:@selector(recalculateClusters) 
                                                            withObject:nil 
                                                            afterDelay:0.75];
}

- (void)stopRecalculatingClusters
{
    if ([self.markerManager markers])
        [NSObject cancelPreviousPerformRequestsWithTarget:((DSMapBoxMarkerManager *)self.markerManager) 
                                                 selector:@selector(recalculateClusters) 
                                                   object:nil];
}

- (void)removeAllCachedImages
{
    if ([self.tileSource isKindOfClass:[RMOpenStreetMapSource class]])
        [super removeAllCachedImages];
    
    // no-op since we don't cache
    //
    return;
}

- (void)setTileSource:(RMMBTilesTileSource *)newTileSource
{
    if (tileSource == newTileSource)
        return;

    if ([newTileSource isKindOfClass:[RMOpenStreetMapSource class]])
    {
        RMCachedTileSource *newCachedTileSource = [RMCachedTileSource cachedTileSourceWithSource:newTileSource];
        
        newCachedTileSource = [newCachedTileSource retain];
        [tileSource release];
        tileSource = newCachedTileSource;
    }
    else
        tileSource = [newTileSource retain];

    CGFloat targetZoom = -0.1;
    
    if (self.zoom < [newTileSource minZoom])
        targetZoom = [newTileSource minZoom];

    else if (self.zoom > [newTileSource maxZoom])
        targetZoom = [newTileSource maxZoom];
    
    if (targetZoom >= 0)
    {
        CGFloat zoomDelta  = targetZoom - [self zoom];        
        CGFloat zoomFactor = exp2f(zoomDelta);
        
        [self zoomByFactor:zoomFactor near:mapView.center];
    }
    
    [self setMinZoom:[newTileSource minZoom]];
    [self setMaxZoom:[newTileSource maxZoom]];
    
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

- (BOOL)canZoomTo:(CGFloat)targetZoom limitedByLayer:(RMMapView **)limitedMapView
{
    if (targetZoom > self.maxZoom || targetZoom < self.minZoom)
    {
        if ([[[DSMapBoxTileSetManager defaultManager] activeTileSetURL] isEqual:[[DSMapBoxTileSetManager defaultManager] defaultTileSetURL]])
            *limitedMapView = nil;
        
        else
            *limitedMapView = (RMMapView *)mapView;

        return NO;
    }
    
    if ([self.layerMapViews count])
        for (RMMapView *layerMapView in layerMapViews)
            if (targetZoom > layerMapView.contents.maxZoom || targetZoom < layerMapView.contents.minZoom)
            {
                *limitedMapView = layerMapView;

                return NO;
            }

    *limitedMapView = nil;
    
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