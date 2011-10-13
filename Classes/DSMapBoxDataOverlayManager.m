//
//  DSMapBoxDataOverlayManager.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/8/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxDataOverlayManager.h"

#import "DSMapBoxBalloonController.h"
#import "DSMapBoxFeedParser.h"
#import "DSMapBoxMarkerManager.h"
#import "DSMapBoxPopoverController.h"
#import "DSMapContents.h"
#import "DSMapBoxTiledLayerMapView.h"
#import "DSMapBoxGeoJSONParser.h"

#import <CoreLocation/CoreLocation.h>

#import "RMMapView.h"
#import "RMProjection.h"
#import "RMLayerCollection.h"
#import "RMPath.h"
#import "RMLatLong.h"
#import "RMGlobalConstants.h"
#import "RMInteractiveSource.h"

#import "SimpleKML.h"
#import "SimpleKMLFeature.h"
#import "SimpleKMLContainer.h"
#import "SimpleKMLPlacemark.h"
#import "SimpleKMLPoint.h"
#import "SimpleKMLStyle.h"
#import "SimpleKMLIconStyle.h"
#import "SimpleKMLLineString.h"
#import "SimpleKMLPolygon.h"
#import "SimpleKMLLinearRing.h"
#import "SimpleKMLLineStyle.h"
#import "SimpleKMLPolyStyle.h"
#import "SimpleKMLGroundOverlay.h"
#import "SimpleKML_UIImage.h"

#import "UIImage-Extensions.h"

#define kDSPlacemarkAlpha    0.9f
#define kDSPathShadowBlur   10.0f
#define kDSPathShadowOffset CGSizeMake(3, 3)

@interface DSMapBoxDataOverlayManager ()

@property (nonatomic, retain) DSMapBoxPopoverController *balloon;
@property (nonatomic, assign) float lastKnownZoom;

@end

#pragma mark -

@implementation DSMapBoxDataOverlayManager

@synthesize mapView;
@synthesize overlays;
@synthesize balloon;
@synthesize lastKnownZoom;

- (id)initWithMapView:(DSMapView *)inMapView
{
    self = [super init];

    if (self != nil)
    {
        mapView  = [inMapView retain];
        overlays = [[NSMutableArray array] retain];
        
        lastKnownZoom = mapView.contents.zoom;
    }
    
    return self;
}

- (void)dealloc
{
    [mapView release];
    [overlays release];
    
    [super dealloc];
}

#pragma mark -

- (void)setMapView:(DSMapView *)inMapView
{
    if ([inMapView isEqual:self.mapView])
        return;
    
    // When tile layers come or go, the top-most one, or else the base layer if none,
    // gets passed here in order to juggle the data overlay layer to it. 
    //    
    // First we take the clusters & their markers (which we'll redraw anyway).
    //
    [((DSMapBoxMarkerManager *)inMapView.markerManager) takeClustersFromMarkerManager:((DSMapBoxMarkerManager *)self.mapView.markerManager)];

    // Then we take the CALayer-based layers (paths, overlays, etc.)
    //
    RMLayerCollection *newOverlay = inMapView.contents.overlay;
    
    NSArray *sublayers = [NSArray arrayWithArray:self.mapView.contents.overlay.sublayers];
    
    for (CALayer *layer in sublayers)
    {  
        [layer removeFromSuperlayer];
        [newOverlay addSublayer:layer];
        
        // update RMPath contents
        //
        if ([layer respondsToSelector:@selector(setMapContents:)])
            [layer setValue:inMapView.contents forKey:@"mapContents"];
    }
    
    [mapView release];
    mapView = [inMapView retain];
}

#pragma mark -

- (RMSphericalTrapezium)addOverlayForKML:(SimpleKML *)kml
{
    NSMutableArray *overlay = [NSMutableArray array];
    
    CGFloat minLat =  kMaxLat;
    CGFloat maxLat = -kMaxLat;
    CGFloat minLon =  kMaxLong;
    CGFloat maxLon = -kMaxLong;

    if ([kml.feature isKindOfClass:[SimpleKMLContainer class]])
    {
        for (SimpleKMLFeature *feature in ((SimpleKMLContainer *)kml.feature).flattenedPlacemarks)
        {
            // draw placemarks as RMMarkers with popups
            //
            if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && 
                ((SimpleKMLPlacemark *)feature).point)
            {
                UIImage *icon;
                
                if (((SimpleKMLPlacemark *)feature).style && ((SimpleKMLPlacemark *)feature).style.iconStyle)
                    icon = ((SimpleKMLPlacemark *)feature).style.iconStyle.icon;
                
                else
                    icon = [[[UIImage imageNamed:@"point.png"] imageWithWidth:44.0 height:44.0] imageWithAlphaComponent:kDSPlacemarkAlpha];
                
                RMMarker *marker;
                
                CLLocation *location = [[[CLLocation alloc] initWithLatitude:((SimpleKMLPlacemark *)feature).point.coordinate.latitude 
                                                                   longitude:((SimpleKMLPlacemark *)feature).point.coordinate.longitude] autorelease];

                if (((SimpleKMLPlacemark *)feature).style.balloonStyle)
                {
                    // TODO: style the balloon according to the given style
                }
                
                marker = [[[RMMarker alloc] initWithUIImage:[icon imageWithAlphaComponent:kDSPlacemarkAlpha]] autorelease];

                marker.data = [NSDictionary dictionaryWithObjectsAndKeys:feature,  @"placemark",
                                                                         location, @"location",
                                                                         nil];

                CLLocationCoordinate2D coordinate = ((SimpleKMLPlacemark *)feature).point.coordinate;
                
                if (coordinate.latitude < minLat)
                    minLat = coordinate.latitude;
                
                if (coordinate.latitude > maxLat)
                    maxLat = coordinate.latitude;
                
                if (coordinate.longitude < minLon)
                    minLon = coordinate.longitude;
                
                if (coordinate.longitude > maxLon)
                    maxLon = coordinate.longitude;
                
                [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) addMarker:marker AtLatLong:coordinate recalculatingImmediately:NO];
                
                [overlay addObject:marker];
            }
            
            // draw lines as RMPaths
            //
            else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] &&
                     ((SimpleKMLPlacemark *)feature).lineString         &&
                     ((SimpleKMLPlacemark *)feature).style              && 
                     ((SimpleKMLPlacemark *)feature).style.lineStyle)
            {
                RMPath *path = [[[RMPath alloc] initWithContents:self.mapView.contents] autorelease];
                
                path.lineColor    = ((SimpleKMLPlacemark *)feature).style.lineStyle.color;
                path.lineWidth    = ((SimpleKMLPlacemark *)feature).style.lineStyle.width;
                path.fillColor    = [UIColor clearColor];
                path.shadowBlur   = kDSPathShadowBlur;
                path.shadowOffset = kDSPathShadowOffset;
                
                SimpleKMLLineString *lineString = ((SimpleKMLPlacemark *)feature).lineString;
                
                BOOL hasStarted = NO;
                
                for (CLLocation *coordinate in lineString.coordinates)
                {
                    if ( ! hasStarted)
                    {
                        [path moveToLatLong:coordinate.coordinate];
                        hasStarted = YES;
                    }
                    
                    else
                        [path addLineToLatLong:coordinate.coordinate];
                
                    // this could be possibly be done per-path instead of per-point using
                    // a bounding box but I wasn't having much luck with it & it's 
                    // probably only worth it on very large & complicated paths
                    //
                    if (coordinate.coordinate.latitude < minLat)
                        minLat = coordinate.coordinate.latitude;
                    
                    if (coordinate.coordinate.latitude > maxLat)
                        maxLat = coordinate.coordinate.latitude;
                    
                    if (coordinate.coordinate.longitude < minLon)
                        minLon = coordinate.coordinate.longitude;
                    
                    if (coordinate.coordinate.longitude > maxLon)
                        maxLon = coordinate.coordinate.longitude;
                }
                
                [self.mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
            
            // draw polygons as RMPaths
            //
            else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] &&
                     ((SimpleKMLPlacemark *)feature).polygon            &&
                     ((SimpleKMLPlacemark *)feature).style              &&
                     ((SimpleKMLPlacemark *)feature).style.polyStyle)
            {
                RMPath *path = [[[RMPath alloc] initWithContents:self.mapView.contents] autorelease];
                
                path.lineColor = ((SimpleKMLPlacemark *)feature).style.lineStyle.color;
                
                if (((SimpleKMLPlacemark *)feature).style.polyStyle.fill)
                    path.fillColor = ((SimpleKMLPlacemark *)feature).style.polyStyle.color;
                
                else
                    path.fillColor = [UIColor clearColor];
                
                path.lineWidth    = ((SimpleKMLPlacemark *)feature).style.lineStyle.width;
                path.shadowBlur   = kDSPathShadowBlur;
                path.shadowOffset = kDSPathShadowOffset;

                SimpleKMLLinearRing *outerBoundary = ((SimpleKMLPlacemark *)feature).polygon.outerBoundary;
                
                BOOL hasStarted = NO;
                
                for (CLLocation *coordinate in outerBoundary.coordinates)
                {
                    if ( ! hasStarted)
                    {
                        [path moveToLatLong:coordinate.coordinate];
                        hasStarted = YES;
                    }
                    
                    else
                        [path addLineToLatLong:coordinate.coordinate];
                
                    // this could be possibly be done per-path instead of per-point using
                    // a bounding box but I wasn't having much luck with it & it's 
                    // probably only worth it on very large & complicated paths
                    //
                    if (coordinate.coordinate.latitude < minLat)
                        minLat = coordinate.coordinate.latitude;
                    
                    if (coordinate.coordinate.latitude > maxLat)
                        maxLat = coordinate.coordinate.latitude;
                    
                    if (coordinate.coordinate.longitude < minLon)
                        minLon = coordinate.coordinate.longitude;
                    
                    if (coordinate.coordinate.longitude > maxLon)
                        maxLon = coordinate.coordinate.longitude;
                }
                
                [self.mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
        }
        
        [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) recalculateClusters];
        
    }
    else if ([kml.feature isKindOfClass:[SimpleKMLGroundOverlay class]])
    {
        // get overlay, create layer, and get bounds
        //
        SimpleKMLGroundOverlay *groundOverlay = (SimpleKMLGroundOverlay *)kml.feature;
        
        RMMapLayer *overlayLayer = [RMMapLayer layer];

        RMLatLong ne = CLLocationCoordinate2DMake(groundOverlay.north, groundOverlay.east);
        RMLatLong nw = CLLocationCoordinate2DMake(groundOverlay.north, groundOverlay.west);
        RMLatLong se = CLLocationCoordinate2DMake(groundOverlay.south, groundOverlay.east);
        RMLatLong sw = CLLocationCoordinate2DMake(groundOverlay.south, groundOverlay.west);
        
        CGPoint nePoint = [self.mapView.contents latLongToPixel:ne];
        CGPoint nwPoint = [self.mapView.contents latLongToPixel:nw];
        CGPoint sePoint = [self.mapView.contents latLongToPixel:se];
        
        // rotate & size image as necessary
        //
        UIImage *overlayImage = groundOverlay.icon;
        
        CGSize originalSize = overlayImage.size;
        
        if (groundOverlay.rotation)
            overlayImage = [overlayImage imageRotatedByDegrees:-groundOverlay.rotation];
        
        // account for rotated corners now sticking out
        //
        CGFloat xFactor = (nePoint.x - nwPoint.x) / originalSize.width;
        CGFloat yFactor = (sePoint.y - nePoint.y) / originalSize.height;
        
        CGFloat xDelta  = (overlayImage.size.width  - originalSize.width)  * xFactor;
        CGFloat yDelta  = (overlayImage.size.height - originalSize.height) * yFactor;
        
        CGRect overlayRect = CGRectMake(nwPoint.x - (xDelta / 2), nwPoint.y - (yDelta / 2), nePoint.x - nwPoint.x + xDelta, sePoint.y - nePoint.y + yDelta);
        
        overlayImage = [overlayImage imageWithWidth:overlayRect.size.width height:overlayRect.size.height];
        
        // size & place layer with image
        //
        overlayLayer.frame = overlayRect;
        
        overlayLayer.contents = (id)[overlayImage CGImage];
        
        // update reported bounds & store for later
        //
        if (sw.latitude < minLat)
            minLat = sw.latitude;
        
        if (nw.latitude > maxLat)
            maxLat = nw.latitude;
        
        if (sw.longitude < minLon)
            minLon = sw.longitude;
        
        if (nw.longitude > maxLon)
            maxLon = nw.longitude;
    
        [self.mapView.contents.overlay addSublayer:overlayLayer];
    
        [overlay addObject:overlayLayer];
    }
    
    if ([overlay count])
    {
        NSDictionary *overlayDict = [NSDictionary dictionaryWithObjectsAndKeys:kml,     @"source", 
                                                                               overlay, @"overlay",
                                                                               nil];
        
        [self.overlays addObject:overlayDict];
        
        // calculate bounds showing all points plus a 10% border on the edges
        //
        RMSphericalTrapezium overlayBounds = { 
            .northeast = {
                .latitude  = maxLat + (0.1 * (maxLat - minLat)),
                .longitude = maxLon + (0.1 * (maxLon - minLon))
            },
            .southwest = {
                .latitude  = minLat - (0.1 * (maxLat - minLat)),
                .longitude = minLon - (0.1 * (maxLat - minLat))
            }
        };
        
        return overlayBounds;
    }
    
    return [self.mapView.contents latitudeLongitudeBoundingBoxForScreen];
}

- (RMSphericalTrapezium)addOverlayForGeoRSS:(NSString *)rss
{
    NSMutableArray *overlay = [NSMutableArray array];
    
    CGFloat minLat =   90;
    CGFloat maxLat =  -90;
    CGFloat minLon =  180;
    CGFloat maxLon = -180;
    
    UIImage *image = [[[UIImage imageNamed:@"point.png"] imageWithWidth:44.0 height:44.0] imageWithAlphaComponent:kDSPlacemarkAlpha];

    NSArray *items = [DSMapBoxFeedParser itemsForFeed:rss];
    
    for (NSDictionary *item in items)
    {
        NSString *balloonBlurb = [NSString stringWithFormat:@"%@<br/><br/><em>%@</em>", 
                                     [item objectForKey:@"description"], 
                                     [item objectForKey:@"date"]];
        
        if ([[item objectForKey:@"link"] length])
            balloonBlurb = [NSString stringWithFormat:@"%@<br/><br/><a href=\"%@\">more</a>", balloonBlurb, [item objectForKey:@"link"]];
        
        RMMarker *marker = [[[RMMarker alloc] initWithUIImage:image] autorelease];
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude  = [[item objectForKey:@"latitude"]  floatValue];
        coordinate.longitude = [[item objectForKey:@"longitude"] floatValue];

        CLLocation *location = [[[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude] autorelease];
        
        // create a generic point with the RSS item's attributes plus location for clustering
        //
        marker.data = [NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"title"], @"title",
                                                                 balloonBlurb,                 @"description",
                                                                 location,                     @"location",
                                                                 nil];
                
        if (coordinate.latitude < minLat)
            minLat = coordinate.latitude;

        if (coordinate.latitude > maxLat)
            maxLat = coordinate.latitude;

        if (coordinate.longitude < minLon)
            minLon = coordinate.longitude;
        
        if (coordinate.longitude > maxLon)
            maxLon = coordinate.longitude;
        
        [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) addMarker:marker AtLatLong:coordinate recalculatingImmediately:NO];
        
        [overlay addObject:marker];
    }
    
    if ([overlay count])
    {
        [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) recalculateClusters];
        
        NSDictionary *overlayDict = [NSDictionary dictionaryWithObjectsAndKeys:rss,     @"source", 
                                                                               overlay, @"overlay",
                                                                               nil];
        
        [self.overlays addObject:overlayDict];
        
        // calculate bounds showing all points plus a 10% border on the edges
        //
        RMSphericalTrapezium overlayBounds = { 
            .northeast = {
                .latitude  = maxLat + (0.1 * (maxLat - minLat)),
                .longitude = maxLon + (0.1 * (maxLon - minLon))
            },
            .southwest = {
                .latitude  = minLat - (0.1 * (maxLat - minLat)),
                .longitude = minLon - (0.1 * (maxLat - minLat))
            }
        };
        
        return overlayBounds;
    }
    
    return [self.mapView.contents latitudeLongitudeBoundingBoxForScreen];
}

- (RMSphericalTrapezium)addOverlayForGeoJSON:(NSString *)json
{
    NSMutableArray *overlay = [NSMutableArray array];
    
    CGFloat minLat =   90;
    CGFloat maxLat =  -90;
    CGFloat minLon =  180;
    CGFloat maxLon = -180;
    
    UIImage *image = [[[UIImage imageNamed:@"point.png"] imageWithWidth:44.0 height:44.0] imageWithAlphaComponent:kDSPlacemarkAlpha];
    
    NSArray *items = [DSMapBoxGeoJSONParser itemsForGeoJSON:json];
    
    for (NSDictionary *item in items)
    {
        if ([[item objectForKey:@"type"] intValue] == DSMapBoxGeoJSONGeometryTypePoint)
        {
            NSMutableString *balloonBlurb = [NSMutableString string];
            
            for (NSString *key in [[item objectForKey:@"properties"] allKeys])
                [balloonBlurb appendString:[NSString stringWithFormat:@"%@: %@<br/>", key, [[item objectForKey:@"properties"] objectForKey:key]]];
            
            RMMarker *marker = [[[RMMarker alloc] initWithUIImage:image] autorelease];
            
            CLLocation *location = [[item objectForKey:@"geometries"] objectAtIndex:0];
            
            CLLocationCoordinate2D coordinate = location.coordinate;
            
            // create a generic point with the GeoJSON item's properties plus location for clustering
            //
            marker.data = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Point %@", [item objectForKey:@"id"]], @"title",
                                                                     balloonBlurb,                                                       @"description",
                                                                     location,                                                           @"location",
                                                                     nil];
            
            if (coordinate.latitude < minLat)
                minLat = coordinate.latitude;
            
            if (coordinate.latitude > maxLat)
                maxLat = coordinate.latitude;
            
            if (coordinate.longitude < minLon)
                minLon = coordinate.longitude;
            
            if (coordinate.longitude > maxLon)
                maxLon = coordinate.longitude;
            
            [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) addMarker:marker AtLatLong:coordinate recalculatingImmediately:NO];
            
            [overlay addObject:marker];
        }
        else if ([[item objectForKey:@"type"] intValue] == DSMapBoxGeoJSONGeometryTypeLineString)
        {
            RMPath *path = [[[RMPath alloc] initWithContents:self.mapView.contents] autorelease];
            
            path.lineColor    = kMapBoxBlue;
            path.fillColor    = [UIColor clearColor];
            path.lineWidth    = 10.0;
            path.shadowBlur   = kDSPathShadowBlur;
            path.shadowOffset = kDSPathShadowOffset;

            BOOL hasStarted = NO;
            
            for (CLLocation *geometry in [item objectForKey:@"geometries"])
            {
                if ( ! hasStarted)
                {
                    [path moveToLatLong:geometry.coordinate];
                    
                    hasStarted = YES;
                }

                else
                    [path addLineToLatLong:geometry.coordinate];
            }
            
            [self.mapView.contents.overlay addSublayer:path];
            
            [overlay addObject:path];
        }
        else if ([[item objectForKey:@"type"] intValue] == DSMapBoxGeoJSONGeometryTypePolygon)
        {
            for (NSArray *linearRing in [item objectForKey:@"geometries"])
            {
                RMPath *path = [[[RMPath alloc] initWithContents:self.mapView.contents] autorelease];
                
                path.lineColor    = kMapBoxBlue;
                path.fillColor    = [UIColor clearColor];
                path.lineWidth    = 10.0;
                path.shadowBlur   = kDSPathShadowBlur;
                path.shadowOffset = kDSPathShadowOffset;

                BOOL hasStarted = NO;
                
                for (CLLocation *point in [linearRing subarrayWithRange:NSMakeRange(0, [linearRing count] - 1)])
                {
                    if ( ! hasStarted)
                    {
                        [path moveToLatLong:point.coordinate];
                        
                        hasStarted = YES;
                    }
                    
                    else
                        [path addLineToLatLong:point.coordinate];
                }
                
                [path closePath];
                
                [self.mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
        }
    }
    
    if ([overlay count])
    {
        [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) recalculateClusters];
        
        NSDictionary *overlayDict = [NSDictionary dictionaryWithObjectsAndKeys:json,    @"source", 
                                                                               overlay, @"overlay",
                                                                               nil];
        
        [self.overlays addObject:overlayDict];
        
        // calculate bounds showing all points plus a 10% border on the edges
        //
        RMSphericalTrapezium overlayBounds = { 
            .northeast = {
                .latitude  = maxLat + (0.1 * (maxLat - minLat)),
                .longitude = maxLon + (0.1 * (maxLon - minLon))
            },
            .southwest = {
                .latitude  = minLat - (0.1 * (maxLat - minLat)),
                .longitude = minLon - (0.1 * (maxLat - minLat))
            }
        };
        
        return overlayBounds;
    }
    
    return [self.mapView.contents latitudeLongitudeBoundingBoxForScreen];
}

- (void)removeAllOverlays
{
    [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) removeMarkersAndClusters];
    self.mapView.contents.overlay.sublayers = nil;
    
    if (self.balloon && self.balloon.popoverVisible)
        [self.balloon dismissPopoverAnimated:NO];
    
    [self.overlays removeAllObjects];
}

- (void)removeOverlayWithSource:(NSString *)source
{
    NSDictionary *overlayToRemove = nil;
    
    for (NSDictionary *overlayDict in self.overlays)
    {
        if (([[overlayDict objectForKey:@"source"] isKindOfClass:[SimpleKML class]] && 
            [[[overlayDict objectForKey:@"source"] valueForKeyPath:@"source"] isEqualToString:source]) ||
            ([[overlayDict objectForKey:@"source"] isKindOfClass:[NSString class]] &&
            [[overlayDict objectForKey:@"source"] isEqualToString:source]))
        {
            NSArray *components = [overlayDict objectForKey:@"overlay"];
            
            for (id component in components)
                if ([component isKindOfClass:[RMMarker class]])
                    [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) removeMarker:component recalculatingImmediately:NO];
                else if ([component isKindOfClass:[RMMapLayer class]])
                    [component removeFromSuperlayer];
                
            [((DSMapBoxMarkerManager *)self.mapView.contents.markerManager) recalculateClusters];
            
            overlayToRemove = overlayDict;
            
            break;
        }
    }
    
    if (overlayToRemove)
        [self.overlays removeObject:overlayToRemove];
    
    if (self.balloon && self.balloon.popoverVisible)
        [self.balloon dismissPopoverAnimated:NO];
}

#pragma mark -

- (void)presentInteractivityAtPoint:(CGPoint)point
{
    // We get here without knowing which layer to query. So, find 
    // the top-most layer that supports interactivity, then query 
    // it for interactivity.
    //
    // In the future, we could, depending on performance, query
    // all layers, top-down, until we get *results*. But this would
    // potentially delay local sources while we query every 
    // remote source above it, coming up empty. 
    //
    DSMapView *interactiveMapView = nil;

    if ([self.mapView isKindOfClass:[DSMapBoxTiledLayerMapView class]])
    {
        // if we get here, tile layers are enabled
        //
        DSMapView *masterMapView = ((DSMapBoxTiledLayerMapView *)self.mapView).masterView;
        NSArray *peerMapViews = ((DSMapContents *)masterMapView.contents).layerMapViews;
        
        // find top-most interactive one
        //
        for (DSMapView *peerMapView in [[peerMapViews reverseObjectEnumerator] allObjects])
        {
            if ([peerMapView.contents.tileSource conformsToProtocol:@protocol(RMInteractiveSource)] && [(id <RMInteractiveSource>)peerMapView.contents.tileSource supportsInteractivity])
            {
                interactiveMapView = peerMapView;
                
                break;
            }
        }
    }
    else
    {
        // no tile layers; just check our (base) map - previews, for example
        //
        if ([self.mapView.contents.tileSource conformsToProtocol:@protocol(RMInteractiveSource)] && [(id <RMInteractiveSource>)self.mapView.contents.tileSource supportsInteractivity])
            interactiveMapView = self.mapView;
    }
    
    if (interactiveMapView)
    {
        NSLog(@"querying for interactivity: %@", interactiveMapView.contents.tileSource);

        NSString *formattedOutput = [(id <RMInteractiveSource>)interactiveMapView.contents.tileSource formattedOutputOfType:RMInteractiveSourceOutputTypeFull 
                                                                                                                   forPoint:point 
                                                                                                                  inMapView:interactiveMapView];
        
        if ( ! formattedOutput || ! [formattedOutput length])
            formattedOutput = [(id <RMInteractiveSource>)interactiveMapView.contents.tileSource formattedOutputOfType:RMInteractiveSourceOutputTypeTeaser 
                                                                                                             forPoint:point 
                                                                                                            inMapView:interactiveMapView];

        if (formattedOutput && [formattedOutput length])
        {
            if (self.balloon)
                [self.balloon dismissPopoverAnimated:NO];
            
            DSMapBoxBalloonController *balloonController = [[[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil] autorelease];
            
            self.balloon = [[[DSMapBoxPopoverController alloc] initWithContentViewController:[[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease]] autorelease];
            
            self.balloon.passthroughViews = [NSArray arrayWithObject:self.mapView.topMostMapView];
            self.balloon.delegate = self;
            
            balloonController.name        = @"";
            balloonController.description = formattedOutput;
            
            self.balloon.popoverContentSize = CGSizeMake(320, 160);
            
            [self.balloon setContentViewController:balloonController];
            
            [self.balloon presentPopoverFromRect:CGRectMake(point.x, point.y, 1, 1) 
                                          inView:self.mapView.topMostMapView
                                        animated:YES];
            
            [TESTFLIGHT passCheckpoint:@"tapped interactive layer"];
        }

        else if (self.balloon)
            [self.balloon dismissPopoverAnimated:YES];
    }

    else if (self.balloon)
        [self.balloon dismissPopoverAnimated:YES];
}

- (void)hideInteractivityAnimated:(BOOL)animated
{
    if (self.balloon)
        [self.balloon dismissPopoverAnimated:animated];
}

#pragma mark -

- (void)tapOnMarker:(RMMarker *)marker onMap:(RMMapView *)map
{
    if (self.balloon)
        [self.balloon dismissPopoverAnimated:NO];
    
    NSDictionary *markerData = ((NSDictionary *)marker.data);
    
    DSMapBoxBalloonController *balloonController = [[[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil] autorelease];
    CGRect attachPoint;
    
    // init with generic view controller
    //
    self.balloon = [[[DSMapBoxPopoverController alloc] initWithContentViewController:[[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease]] autorelease];
    
    self.balloon.passthroughViews = [NSArray arrayWithObject:self.mapView.topMostMapView];
    self.balloon.delegate = self;
    
    // KML placemarks have their own title & description
    //
    if ([markerData objectForKey:@"placemark"])
    {
        SimpleKMLPlacemark *placemark = (SimpleKMLPlacemark *)[markerData objectForKey:@"placemark"];
        
        balloonController.name        = placemark.name;
        balloonController.description = placemark.featureDescription;
        
        attachPoint = CGRectMake([self.mapView.contents latLongToPixel:placemark.point.coordinate].x,
                                 [self.mapView.contents latLongToPixel:placemark.point.coordinate].y, 
                                 1,
                                 1);
        
        self.balloon.popoverContentSize = CGSizeMake(320, 160);
    }
    
    // GeoRSS points have a title & description from the feed
    //
    else
    {
        balloonController.name        = [markerData objectForKey:@"title"];
        balloonController.description = [markerData objectForKey:@"description"];
        
        RMLatLong latLong = [self.mapView.contents.projection pointToLatLong:marker.projectedLocation];
        
        attachPoint = CGRectMake([self.mapView.contents latLongToPixel:latLong].x,
                                 [self.mapView.contents latLongToPixel:latLong].y, 
                                 1, 
                                 1);
        
        self.balloon.popoverContentSize = CGSizeMake(320, 160);
    }
    
    // replace with balloon view controller
    //
    [self.balloon setContentViewController:balloonController];
    
    [self.balloon presentPopoverFromRect:attachPoint
                                  inView:self.mapView.topMostMapView
                                animated:YES];
    
    [TESTFLIGHT passCheckpoint:@"tapped on marker"];
}

- (void)tapOnLabelForMarker:(RMMarker *)marker onMap:(RMMapView *)map
{
    [self tapOnMarker:marker onMap:map];
}

- (void)mapViewRegionDidChange:(RMMapView *)map
{
    if (self.balloon)
    {
        if (self.lastKnownZoom != map.contents.zoom)
        {
            // dismiss popover if the user has zoomed
            //
            [self.balloon dismissPopoverAnimated:NO];
        }
        else
        {
            // determine screen point to keep popover at same lat/long
            //
            RMProjectedPoint oldProjectedPoint = self.balloon.projectedPoint;
            RMLatLong oldAttachLatLong         = [map.contents.projection pointToLatLong:oldProjectedPoint];
            CGPoint newAttachPoint             = [map.contents latLongToPixel:oldAttachLatLong];
            
            // check that popover won't try to move off-screen; dismiss if so
            //
            CGFloat pX      = newAttachPoint.x;
            CGFloat pY      = newAttachPoint.y;
            CGFloat pWidth  = self.balloon.popoverContentSize.width;
            CGFloat pHeight = self.balloon.popoverContentSize.height;
            CGFloat mWidth  = map.bounds.size.width;
            CGFloat mHeight = map.bounds.size.height;
            
            UIPopoverArrowDirection d = self.balloon.arrowDirection;
            
            CGFloat threshold = 50;
            CGFloat arrowSize = 30;
            
            if ((d == UIPopoverArrowDirectionDown  && pY > mHeight - threshold)                       || // popup on top hitting bottom edge of map
                (d == UIPopoverArrowDirectionDown  && pY - pHeight - arrowSize < threshold)           || // popup on top hitting top edge of map
                (d == UIPopoverArrowDirectionUp    && pY + arrowSize + pHeight > mHeight - threshold) || // popup on bottom hitting bottom edge of map
                (d == UIPopoverArrowDirectionUp    && pY < threshold)                                 || // popup on bottom hitting top edge of map
                (d == UIPopoverArrowDirectionDown  && pX + (pWidth  / 2) > mWidth  - threshold)       || // popup on top hitting right edge of map
                (d == UIPopoverArrowDirectionDown  && pX - (pWidth  / 2) < threshold)                 || // popup on top hitting left edge of map
                (d == UIPopoverArrowDirectionUp    && pX - (pWidth  / 2) < threshold)                 || // popup on bottom hitting left edge of map
                (d == UIPopoverArrowDirectionUp    && pX + (pWidth  / 2) > mWidth  - threshold))         // popup on bottom hitting right edge of map
                
                [self.balloon dismissPopoverAnimated:NO];

            else
            {
                // Re-present the popover, which has the effect of moving it with the map.
                //
                // See http://developer.apple.com/library/ios/#qa/qa1694/_index.html
                //
                [self.balloon presentPopoverFromRect:CGRectMake(newAttachPoint.x, newAttachPoint.y, 1, 1) 
                                              inView:self.balloon.presentingView
                            permittedArrowDirections:d
                                            animated:NO];
            }
        }
    }
    
    self.lastKnownZoom = map.contents.zoom;
}

#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.balloon = nil;
}

@end