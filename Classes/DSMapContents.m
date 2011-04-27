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

- (BOOL)canZoomTo:(CGFloat)targetZoom limitedByLayer:(RMMapView **)limitedMapView;
- (void)postZoom;
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
    
    if (zoom != [self zoom])
        NSLog(@"DSMapContents changing zoom %f => %f", [self zoom], zoom);
    
    // borrowed from super
    //
    float scale = [mercatorToTileProjection calculateScaleFromZoom:zoom];
    
    [self setMetersPerPixel:scale];
    //
    // end borrowed code
    
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
    
    DSTiledLayerMapView *limitedMapView = nil;
    
    if ([self canZoomTo:targetZoom limitedByLayer:&limitedMapView])
    {
        [self stopRecalculatingClusters];
        
        [super zoomByFactor:zoomFactor near:pivot animated:NO withCallback:callback];
        
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

@end