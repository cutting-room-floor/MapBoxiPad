//
//  DSMapBoxDataOverlayManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/8/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDataOverlayManager.h"

#import "DSMapBoxBalloonController.h"
#import "DSMapBoxFeedParser.h"
#import "DSMapBoxMarkerManager.h"

#import <CoreLocation/CoreLocation.h>

#import "RMMapView.h"
#import "RMProjection.h"
#import "RMLayerCollection.h"
#import "RMPath.h"
#import "RMLatLong.h"
#import "RMGlobalConstants.h"

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
#import "SimpleKML_UIImage.h"

@implementation DSMapBoxDataOverlayManager

@synthesize mapView;

- (id)initWithMapView:(RMMapView *)inMapView
{
    self = [super init];

    if (self != nil)
    {
        mapView = [inMapView retain];
        overlays = [[NSMutableArray array] retain];
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

- (void)setMapView:(RMMapView *)inMapView
{
    RMLayerCollection *newOverlay = [[[RMLayerCollection alloc] initForContents:inMapView.contents] autorelease];
    newOverlay.sublayers = mapView.contents.overlay.sublayers;
    
    inMapView.contents.overlay = newOverlay;
    
    [mapView release];
    mapView = [inMapView retain];
}

- (NSArray *)overlays
{
    return [NSArray arrayWithArray:overlays];
}

#pragma mark -

- (RMSphericalTrapezium)addOverlayForKML:(SimpleKML *)kml
{
    if ([kml.feature isKindOfClass:[SimpleKMLContainer class]])
    {
        NSMutableArray *overlay = [NSMutableArray array];
        
        CGFloat minLat =  kMaxLat;
        CGFloat maxLat = -kMaxLat;
        CGFloat minLon =  kMaxLong;
        CGFloat maxLon = -kMaxLong;
        
        for (SimpleKMLFeature *feature in ((SimpleKMLContainer *)kml.feature).features)
        {
            // draw placemarks as RMMarkers with popups
            //
            if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && 
                ((SimpleKMLPlacemark *)feature).point              &&
                ((SimpleKMLPlacemark *)feature).style              && 
                ((SimpleKMLPlacemark *)feature).style.iconStyle)
            {
                UIImage *icon = ((SimpleKMLPlacemark *)feature).style.iconStyle.icon;
                
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
                
                [((DSMapBoxMarkerManager *)mapView.contents.markerManager) addMarker:marker AtLatLong:coordinate recalculatingImmediately:NO];
                
                [overlay addObject:marker];
            }
            
            // draw lines as RMPaths
            //
            else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] &&
                     ((SimpleKMLPlacemark *)feature).lineString         &&
                     ((SimpleKMLPlacemark *)feature).style              && 
                     ((SimpleKMLPlacemark *)feature).style.lineStyle)
            {
                RMPath *path = [[[RMPath alloc] initWithContents:mapView.contents] autorelease];
                
                path.lineColor = ((SimpleKMLPlacemark *)feature).style.lineStyle.color;
                path.lineWidth = ((SimpleKMLPlacemark *)feature).style.lineStyle.width;
                path.fillColor = [UIColor clearColor];
                
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
                
                [mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
            
            // draw polygons as RMPaths
            //
            else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] &&
                     ((SimpleKMLPlacemark *)feature).polygon            &&
                     ((SimpleKMLPlacemark *)feature).style              &&
                     ((SimpleKMLPlacemark *)feature).style.polyStyle)
            {
                RMPath *path = [[[RMPath alloc] initWithContents:mapView.contents] autorelease];
                
                path.lineColor = ((SimpleKMLPlacemark *)feature).style.lineStyle.color;
                
                if (((SimpleKMLPlacemark *)feature).style.polyStyle.fill)
                    path.fillColor = ((SimpleKMLPlacemark *)feature).style.polyStyle.color;
                
                else
                    path.fillColor = [UIColor clearColor];
                
                path.lineWidth = ((SimpleKMLPlacemark *)feature).style.lineStyle.width;
                
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
                
                [mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
        }
        
        [((DSMapBoxMarkerManager *)mapView.contents.markerManager) recalculateClusters];
        
        if ([overlay count])
        {
            NSDictionary *overlayDict = [NSDictionary dictionaryWithObjectsAndKeys:kml,     @"source", 
                                                                                   overlay, @"overlay",
                                                                                   nil];
            
            [overlays addObject:overlayDict];
            
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
    }
    
    return [mapView.contents latitudeLongitudeBoundingBoxForScreen];
}

- (RMSphericalTrapezium)addOverlayForGeoRSS:(NSString *)rss
{
    NSMutableArray *overlay = [NSMutableArray array];
    
    CGFloat minLat =   90;
    CGFloat maxLat =  -90;
    CGFloat minLon =  180;
    CGFloat maxLon = -180;
    
    UIImage *image = [[[UIImage imageNamed:@"circle.png"] imageWithWidth:44.0 height:44.0] imageWithAlphaComponent:kDSPlacemarkAlpha];

    NSArray *items = [DSMapBoxFeedParser itemsForFeed:rss];
    
    for (NSDictionary *item in items)
    {
        NSString *balloonBlurb = [NSString stringWithFormat:@"%@<br/><br/><em>%@</em><br/><br/><a href=\"%@\">more</a>", 
                                     [item objectForKey:@"description"], 
                                     [item objectForKey:@"date"], 
                                     [item objectForKey:@"link"]];
        
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
        
        [((DSMapBoxMarkerManager *)mapView.contents.markerManager) addMarker:marker AtLatLong:coordinate recalculatingImmediately:NO];
        
        [overlay addObject:marker];
    }
    
    if ([overlay count])
    {
        [((DSMapBoxMarkerManager *)mapView.contents.markerManager) recalculateClusters];
        
        NSDictionary *overlayDict = [NSDictionary dictionaryWithObjectsAndKeys:rss,     @"source", 
                                                                               overlay, @"overlay",
                                                                               nil];
        
        [overlays addObject:overlayDict];
        
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
    
    return [mapView.contents latitudeLongitudeBoundingBoxForScreen];
}

- (void)removeAllOverlays
{
    [mapView.contents.markerManager removeMarkers];
    mapView.contents.overlay.sublayers = nil;
    
    [balloon dismissPopoverAnimated:NO];
    
    [overlays removeAllObjects];
}

- (void)removeOverlayWithSource:(NSString *)source
{
    for (NSDictionary *overlayDict in overlays)
    {
        if (([[overlayDict objectForKey:@"source"] isKindOfClass:[SimpleKML class]] && 
            [[[overlayDict objectForKey:@"source"] valueForKeyPath:@"source"] isEqualToString:source]) ||
            [[overlayDict objectForKey:@"source"] isKindOfClass:[NSString class]] &&
            [[overlayDict objectForKey:@"source"] isEqualToString:source])
        {
            NSArray *components = [overlayDict objectForKey:@"overlay"];
            
            for (id component in components)
                if ([component isKindOfClass:[RMMarker class]])
                    [((DSMapBoxMarkerManager *)mapView.contents.markerManager) removeMarker:component recalculatingImmediately:NO];
                
            [((DSMapBoxMarkerManager *)mapView.contents.markerManager) recalculateClusters];
        }
    }
    
    [balloon dismissPopoverAnimated:NO];
}

#pragma mark -

- (void)tapOnMarker:(RMMarker *)marker onMap:(RMMapView *)map
{
    NSDictionary *markerData = ((NSDictionary *)marker.data);
    
    DSMapBoxBalloonController *balloonController = [[[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil] autorelease];
    CGRect attachPoint;
    
    // init with generic view controller
    //
    balloon = [[UIPopoverController alloc] initWithContentViewController:[[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease]];
    
    balloon.delegate = self;
    
    // KML placemarks have their own title & description
    //
    if ([markerData objectForKey:@"placemark"])
    {
        SimpleKMLPlacemark *placemark = (SimpleKMLPlacemark *)[markerData objectForKey:@"placemark"];
        
        balloonController.name        = placemark.name;
        balloonController.description = placemark.featureDescription;
        
        attachPoint = CGRectMake([mapView.contents latLongToPixel:placemark.point.coordinate].x,
                                 [mapView.contents latLongToPixel:placemark.point.coordinate].y, 
                                 1, 
                                 1);
        
        balloon.popoverContentSize = CGSizeMake(320, 160); // smaller rectangle with less room for description
    }
    
    // GeoRSS points have a title & description from the feed
    //
    else
    {
        balloonController.name        = [markerData objectForKey:@"title"];
        balloonController.description = [markerData objectForKey:@"description"];
        
        RMLatLong latLong = [mapView.contents.projection pointToLatLong:marker.projectedLocation];
        
        attachPoint = CGRectMake([mapView.contents latLongToPixel:latLong].x,
                                 [mapView.contents latLongToPixel:latLong].y, 
                                 1, 
                                 1);
        
        if ([markerData objectForKey:@"isCluster"])
            balloon.popoverContentSize = CGSizeMake(320, 160); // smaller rectangle with less room for big description

        else
            balloon.popoverContentSize = CGSizeMake(320, 320); // square with room for big description
    }
    
    // replace with balloon view controller
    //
    [balloon setContentViewController:balloonController];
    
    [balloon presentPopoverFromRect:attachPoint
                             inView:mapView 
           permittedArrowDirections:UIPopoverArrowDirectionAny
                           animated:YES];
}

#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [popoverController release];
}

@end