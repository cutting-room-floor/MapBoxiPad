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
#import "DSMapBoxPopoverController.h"
#import "DSMapContents.h"

#import <CoreLocation/CoreLocation.h>

#import "RMMapView.h"
#import "RMProjection.h"
#import "RMLayerCollection.h"
#import "RMPath.h"
#import "RMLatLong.h"
#import "RMGlobalConstants.h"
#import "RMMBTilesTileSource.h"

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

#define kDSPlacemarkAlpha 0.9f

@implementation DSMapBoxDataOverlayManager

@synthesize mapView;

- (id)initWithMapView:(DSMapView *)inMapView
{
    self = [super init];

    if (self != nil)
    {
        mapView = [inMapView retain];
        overlays = [[NSMutableArray array] retain];
        
        interactivityFormatter = [[UIWebView alloc] initWithFrame:CGRectZero];
        [mapView.superview addSubview:interactivityFormatter];
        [interactivityFormatter loadHTMLString:nil baseURL:nil];
        
        lastKnownZoom = mapView.contents.zoom;
    }
    
    return self;
}

- (void)dealloc
{
    [mapView release];
    [overlays release];
    
    [interactivityFormatter removeFromSuperview];
    [interactivityFormatter release];
    
    [super dealloc];
}

#pragma mark -

- (void)setMapView:(DSMapView *)inMapView
{
    if ([inMapView isEqual:mapView])
        return;
    
    // When tile layers come or go, the top-most one, or else the base layer if none,
    // gets passed here in order to juggle the data overlay layer to it. 
    //    
    RMLayerCollection *newOverlay = inMapView.contents.overlay;
    
    NSArray *layers = [NSArray arrayWithArray:mapView.contents.overlay.sublayers];
    
    for (CALayer *someLayer in layers)
    {  
        [someLayer removeFromSuperlayer];
        [newOverlay addSublayer:someLayer];
    }
    
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
    [((DSMapBoxMarkerManager *)mapView.contents.markerManager) removeMarkersAndClusters];
    mapView.contents.overlay.sublayers = nil;
    
    if (balloon)
    {
        if (balloon.popoverVisible)
            [balloon dismissPopoverAnimated:NO];

        [balloon release];
        balloon = nil;
    }
    
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
                else if ([component isKindOfClass:[RMMapLayer class]])
                    [component removeFromSuperlayer];
                
            [((DSMapBoxMarkerManager *)mapView.contents.markerManager) recalculateClusters];
        }
    }
    
    if (balloon)
    {
        if (balloon.popoverVisible)
            [balloon dismissPopoverAnimated:NO];

        [balloon release];
        balloon = nil;
    }
}

#pragma mark -

- (void)presentInteractivityAtPoint:(CGPoint)point
{
    DSMapView *aMapView         = nil;
    id <RMTileSource>tileSource = nil;
    
    NSArray *layerMapViews = ((DSMapContents *)mapView.contents).layerMapViews;
    
    if ([layerMapViews count])
    {
        // get the first one with interactivity, which was the last-enabled
        // TODO: perhaps maintain actual stacking order? 
        //
        for (DSMapView *aMapView in layerMapViews)
        {
            tileSource = aMapView.contents.tileSource;

            if ([tileSource isKindOfClass:[RMMBTilesTileSource class]] && [((RMMBTilesTileSource *)tileSource) supportsInteractivity])
                break;
        }
    }
    
    if ( ! tileSource)
    {
        // refer to base map view
        //
        aMapView   = mapView;
        tileSource = aMapView.contents.tileSource;
    }

    NSLog(@"querying for interactivity: %@", tileSource);    
    
    if ([tileSource isKindOfClass:[RMMBTilesTileSource class]] && [((RMMBTilesTileSource *)tileSource) supportsInteractivity])
    {
        // determine renderer scroll layer sub-layer touched
        //
        CALayer *rendererLayer = [aMapView.contents.renderer valueForKey:@"layer"];
        CALayer *tileLayer     = [rendererLayer hitTest:point];
        
        // convert touch to sub-layer
        //
        CGPoint layerPoint = [tileLayer convertPoint:point fromLayer:rendererLayer];
        
        // normalize tile touch to 256px
        //
        float normalizedX = (layerPoint.x / tileLayer.bounds.size.width)  * 256;
        float normalizedY = (layerPoint.y / tileLayer.bounds.size.height) * 256;
        
        // determine lat & lon of touch
        //
        CLLocationCoordinate2D touchLocation = [aMapView.contents pixelToLatLong:point];
        
        // use lat & lon to determine TMS tile (per http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
        //
        int tileZoom = (int)(roundf(aMapView.contents.zoom));
        
        int tileX = (int)(floor((touchLocation.longitude + 180.0) / 360.0 * pow(2.0, tileZoom)));
        int tileY = (int)(floor((1.0 - log(tan(touchLocation.latitude * M_PI / 180.0) + 1.0 / \
                                           cos(touchLocation.latitude * M_PI / 180.0)) / M_PI) / 2.0 * pow(2.0, tileZoom)));
        
        tileY = pow(2.0, tileZoom) - tileY - 1.0;
        
        RMTile tile = {
            .zoom = tileZoom,
            .x    = tileX,
            .y    = tileY,
        };
        
        // fetch interactivity data for tile/point & JavaScript formatter source for set
        //
        CGPoint tilePoint = CGPointMake(normalizedX, normalizedY);
        
        NSDictionary *interactivityDictionary = [((RMMBTilesTileSource *)tileSource) interactivityDictionaryForPoint:tilePoint inTile:tile];
        NSString     *formatterJavascript     = [((RMMBTilesTileSource *)tileSource) interactivityFormatterJavascript];
        
        if (interactivityDictionary && formatterJavascript)
        {
            NSString *keyJSON = [interactivityDictionary objectForKey:@"keyJSON"];
            
            [interactivityFormatter stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var data   = %@;", keyJSON]];
            [interactivityFormatter stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"var format = %@;", formatterJavascript]];

            // try full version first
            //
            [interactivityFormatter stringByEvaluatingJavaScriptFromString:@"var options = { format: 'full' }"];

            NSString *formattedOutput = [interactivityFormatter stringByEvaluatingJavaScriptFromString:@"format(options, data);"];
            
            // failing that, try teaser
            //
            if ( ! [formattedOutput length])
            {
                [interactivityFormatter stringByEvaluatingJavaScriptFromString:@"var options = { format: 'teaser' }"];

                formattedOutput = [interactivityFormatter stringByEvaluatingJavaScriptFromString:@"format(options, data);"];
            }
            
            if (formattedOutput && [formattedOutput length])
            {
                if (balloon)
                    [balloon dismissPopoverAnimated:NO];
                
                DSMapBoxBalloonController *balloonController = [[[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil] autorelease];
                
                balloon = [[DSMapBoxPopoverController alloc] initWithContentViewController:[[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease]];
                
                balloon.passthroughViews = [NSArray arrayWithObject:aMapView];
                balloon.delegate = self;
                
                balloonController.name        = @"";
                balloonController.description = formattedOutput;
                
                balloon.popoverContentSize = CGSizeMake(320, 160);
                
                [balloon setContentViewController:balloonController];
                
                [balloon presentPopoverFromRect:CGRectMake(point.x, point.y, 1, 1) 
                                         inView:aMapView 
                       permittedArrowDirections:UIPopoverArrowDirectionAny
                                       animated:YES];
            }
            else if (balloon)
                [balloon dismissPopoverAnimated:YES];
        }
        
        else if (balloon)
            [balloon dismissPopoverAnimated:YES];
    }
    else if (balloon)
        [balloon dismissPopoverAnimated:YES];
}

- (void)hideInteractivityAnimated:(BOOL)animated
{
    if (balloon)
        [balloon dismissPopoverAnimated:animated];
}

#pragma mark -

- (void)tapOnMarker:(RMMarker *)marker onMap:(RMMapView *)map
{
    if (balloon)
        [balloon dismissPopoverAnimated:NO];
    
    NSDictionary *markerData = ((NSDictionary *)marker.data);
    
    DSMapBoxBalloonController *balloonController = [[[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil] autorelease];
    CGRect attachPoint;
    
    // init with generic view controller
    //
    balloon = [[DSMapBoxPopoverController alloc] initWithContentViewController:[[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease]];
    
    balloon.passthroughViews = [NSArray arrayWithObject:mapView];
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
        
        balloon.popoverContentSize = CGSizeMake(320, 160);
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
        
        balloon.popoverContentSize = CGSizeMake(320, 160);
    }
    
    // replace with balloon view controller
    //
    [balloon setContentViewController:balloonController];
    
    [balloon presentPopoverFromRect:attachPoint
                             inView:mapView 
           permittedArrowDirections:UIPopoverArrowDirectionAny
                           animated:YES];
}

- (void)tapOnLabelForMarker:(RMMarker *)marker onMap:(RMMapView *)map
{
    [self tapOnMarker:marker onMap:map];
}

- (void)mapViewRegionDidChange:(RMMapView *)map
{
    if (balloon)
    {
        if (lastKnownZoom != map.contents.zoom)
            [balloon dismissPopoverAnimated:NO];

        else
        {
            RMProjectedPoint oldProjectedPoint = balloon.projectedPoint;
            RMLatLong oldAttachLatLong         = [map.contents.projection pointToLatLong:oldProjectedPoint];
            CGPoint newAttachPoint             = [map.contents latLongToPixel:oldAttachLatLong];
            
            // check that popover won't try to move off-screen; dismiss if so
            //
            CGFloat pX      = newAttachPoint.x;
            CGFloat pY      = newAttachPoint.y;
            CGFloat pWidth  = balloon.popoverContentSize.width;
            CGFloat pHeight = balloon.popoverContentSize.height;
            CGFloat mWidth  = map.bounds.size.width;
            CGFloat mHeight = map.bounds.size.height;
            
            UIPopoverArrowDirection d = balloon.popoverArrowDirection;
            
            CGFloat threshold = 20;
            CGFloat arrowSize = 30;
            
            if (d == UIPopoverArrowDirectionRight && pX > mWidth - threshold                        || // popup on left hitting right edge of map
                d == UIPopoverArrowDirectionRight && pX - arrowSize - pWidth - threshold < 0        || // popup on left hitting left edge of map
                d == UIPopoverArrowDirectionLeft  && pX > mWidth - pWidth - arrowSize - threshold   || // popup on right hitting right edge of map
                d == UIPopoverArrowDirectionLeft  && pX < threshold                                 || // popup on right hitting left edge of map
                d == UIPopoverArrowDirectionDown  && pY > mHeight - threshold                       || // popup on top hitting bottom edge of map
                d == UIPopoverArrowDirectionDown  && pY - pHeight - arrowSize < threshold           || // popup on top hitting top edge of map
                d == UIPopoverArrowDirectionUp    && pY + arrowSize + pHeight > mHeight - threshold || // popup on bottom hitting bottom edge of map
                d == UIPopoverArrowDirectionUp    && pY < threshold                                 || // popup on bottom hitting top edge of map
                d == UIPopoverArrowDirectionRight && pY - (pHeight / 2) < threshold                 || // popup on left hitting top edge of map
                d == UIPopoverArrowDirectionRight && pY + (pHeight / 2) > mHeight - threshold       || // popup on left hitting bottom edge of map
                d == UIPopoverArrowDirectionLeft  && pY - (pHeight / 2) < threshold                 || // popup on right hitting top edge of map
                d == UIPopoverArrowDirectionLeft  && pY + (pHeight / 2) > mHeight - threshold       || // popup on right hitting bottom edge of map
                d == UIPopoverArrowDirectionDown  && pX + (pWidth  / 2) > mWidth  - threshold       || // popup on top hitting right edge of map
                d == UIPopoverArrowDirectionDown  && pX - (pWidth  / 2) < threshold                 || // popup on top hitting left edge of map
                d == UIPopoverArrowDirectionUp    && pX - (pWidth  / 2) < threshold                 || // popup on bottom hitting left edge of map
                d == UIPopoverArrowDirectionUp    && pX + (pWidth  / 2) > mWidth  - threshold)         // popup on bottom hitting rigth edge of map
                
                [balloon dismissPopoverAnimated:NO];

            else
                [balloon presentPopoverFromRect:CGRectMake(newAttachPoint.x, newAttachPoint.y, 1, 1) 
                                         inView:map
                       permittedArrowDirections:balloon.popoverArrowDirection 
                                       animated:NO];
        }
    }
    
    lastKnownZoom = map.contents.zoom;
}

#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [balloon release];
    balloon = nil;
}

@end