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
#import "DSTiledLayerMapView.h"
#import "DSMapBoxTileSetManager.h"

#import "RMProjection.h"
#import "RMTileLoader.h"
#import "RMMercatorToTileProjection.h"
#import "RMMapView.h"
#import "RMMercatorToScreenProjection.h"

#import "RMOpenStreetMapSource.h"
#import "RMCachedTileSource.h"

NSString *const DSMapContentsZoomBoundsReached = @"DSMapContentsZoomBoundsReached";

@interface DSMapContents (DSMapContentsPrivate)

- (void)postZoom;
- (void)recalculateClustersIfNeeded;
- (void)stopRecalculatingClusters;
- (void)checkOutOfZoomBoundsAnimated:(BOOL)animated;

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
        
        // bounds warning bookmark
        //
        mapView.tag = 1;

        [self checkOutOfZoomBoundsAnimated:NO];
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
    // Adjust delta as necessary to constrain latitude, but not longitude.
    //
    // This is largely borrowed from -[RMMapView setConstraintsSW:NE:] and -[RMMapView moveBy:]
    //
    RMProjectedRect sourceBounds = [self.mercatorToScreenProjection projectedBounds];
    RMProjectedSize XYDelta      = [self.mercatorToScreenProjection projectScreenSizeToXY:delta];

    CGSize sizeRatio = CGSizeMake(((delta.width == 0)  ? 0 : XYDelta.width  / delta.width),
                                  ((delta.height == 0) ? 0 : XYDelta.height / delta.height));

    RMProjectedRect destinationBounds = sourceBounds;
    
    destinationBounds.origin.northing -= XYDelta.height;
    destinationBounds.origin.easting  -= XYDelta.width; 
    
    BOOL constrained = NO;
    
    RMProjectedPoint SWconstraint = [self.projection latLongToPoint:CLLocationCoordinate2DMake(kLowerLatitudeBounds, 0)];
    RMProjectedPoint NEconstraint = [self.projection latLongToPoint:CLLocationCoordinate2DMake(kUpperLatitudeBounds, 0)];
    
    if (destinationBounds.origin.northing < SWconstraint.northing)
    {
        destinationBounds.origin.northing = SWconstraint.northing;
        constrained = YES;
    }
    
    if (destinationBounds.origin.northing + sourceBounds.size.height > NEconstraint.northing)
    {
        destinationBounds.origin.northing = NEconstraint.northing - destinationBounds.size.height;
        constrained = YES;
    }

    if (constrained) 
    {
        XYDelta.height = sourceBounds.origin.northing - destinationBounds.origin.northing;
        XYDelta.width  = sourceBounds.origin.easting  - destinationBounds.origin.easting;
        
        delta = CGSizeMake(((sizeRatio.width == 0)  ? 0 : XYDelta.width  / sizeRatio.width), 
                           ((sizeRatio.height == 0) ? 0 : XYDelta.height / sizeRatio.height));
    }

    [self stopRecalculatingClusters];
        
    [super moveBy:delta];
        
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents moveBy:delta];
        
    [self recalculateClustersIfNeeded];
}

- (void)setZoom:(float)zoom
{
    [self stopRecalculatingClusters];
    
    // borrowed from super
    //
    float scale = [mercatorToTileProjection calculateScaleFromZoom:zoom];
    
    [self setMetersPerPixel:scale];
    //
    // end borrowed code
    
    // check for going out of zoom bounds
    //
    [self checkOutOfZoomBoundsAnimated:YES];
    
    // trigger overlays, if any
    //
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
        return;
    
    [self stopRecalculatingClusters];
    
    // call super
    //
    [super zoomByFactor:zoomFactor near:pivot animated:NO withCallback:callback];

    // check for going out of zoom bounds
    //
    [self checkOutOfZoomBoundsAnimated:YES];
    
    // trigger overlays, if any
    //
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

- (void)zoomWithLatLngBoundsNorthEast:(CLLocationCoordinate2D)ne SouthWest:(CLLocationCoordinate2D)se
{
    [self stopRecalculatingClusters];
    
    // call super
    //
    [super zoomWithLatLngBoundsNorthEast:ne SouthWest:se];

    // check for going out of zoom bounds
    //
    [self checkOutOfZoomBoundsAnimated:YES];
    
    // trigger overlays, if any
    //
    if (self.layerMapViews)
        for (RMMapView *layerMapView in layerMapViews)
            [layerMapView.contents zoomWithLatLngBoundsNorthEast:ne SouthWest:se];
    
    [self recalculateClustersIfNeeded];
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

- (void)setTileSource:(id <RMTileSource>)newTileSource
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
    {
        [tileSource release];
        tileSource = [newTileSource retain];
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

- (void)postZoom
{
    RMProjectedPoint currentTopLeftProj      = [mercatorToScreenProjection projectScreenPointToXY:CGPointMake(0, 0)];
    RMLatLong        currentTopLeftCoord     = [projection pointToLatLong:currentTopLeftProj];

    CGPoint          currentBottomRightPoint = CGPointMake([mercatorToScreenProjection screenBounds].size.width, 
                                                           [mercatorToScreenProjection screenBounds].size.height);
    
    RMProjectedPoint currentBottomRightProj  = [mercatorToScreenProjection projectScreenPointToXY:currentBottomRightPoint];
    RMLatLong        currentBottomRightCoord = [projection pointToLatLong:currentBottomRightProj];
    
    RMProjectedPoint newCenterProj;
    
    BOOL needsRefresh = NO;
    
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
        
        newCenterProj.easting  = newTopLeftProj.easting  + (([mercatorToScreenProjection screenBounds].size.width  * self.metersPerPixel) / 2);
        newCenterProj.northing = newTopLeftProj.northing - (([mercatorToScreenProjection screenBounds].size.height * self.metersPerPixel) / 2);

        needsRefresh = YES;
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
        
        newCenterProj.easting  = newBottomRightProj.easting  - (([mercatorToScreenProjection screenBounds].size.width  * self.metersPerPixel) / 2);
        newCenterProj.northing = newBottomRightProj.northing + (([mercatorToScreenProjection screenBounds].size.height * self.metersPerPixel) / 2);
        
        needsRefresh = YES;
    }
    
    if (needsRefresh)
    {
        [self moveToProjectedPoint:newCenterProj];

        // temp fix for #23 to avoid tile artifacting
        //
        [tileLoader reload];
    }
    
}

- (void)checkOutOfZoomBoundsAnimated:(BOOL)animated
{
    if ([self.tileSource isKindOfClass:[RMMBTilesTileSource class]])
    {
        RMMBTilesTileSource *source = (RMMBTilesTileSource *)self.tileSource;
        
        CGFloat newAlpha;
        
        if (self.zoom > [source maxZoomNative] || self.zoom < [source minZoomNative])
        {
            newAlpha = 0.0;

            // Only warn once per bounds limit crossing. Do this for
            // base layers as well, so use tag since we don't actually
            // change their alpha value. 
            //
            if (mapView.tag != (NSInteger)newAlpha)
                [[NSNotificationCenter defaultCenter] postNotificationName:DSMapContentsZoomBoundsReached object:self];
        }
        
        else
            newAlpha = 1.0;
        
        // update for next time
        //
        mapView.tag = (NSInteger)newAlpha;
        
//        if (newAlpha != mapView.alpha && [source layerType] == RMMBTilesLayerTypeOverlay)
//        {
//            // only actually change overlays
//            //
//            if (animated)
//                [UIView beginAnimations:nil context:nil];
//            
//            mapView.alpha = newAlpha;
//            
//            if (animated)
//                [UIView commitAnimations];
//        }
    }
}

@end