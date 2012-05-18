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
#import "DSMapBoxPopoverController.h"
#import "DSMapBoxGeoJSONParser.h"

#import <CoreLocation/CoreLocation.h>

#import "RMMapView.h"
#import "RMProjection.h"
#import "RMAnnotation.h"
#import "RMQuadTree.h"
#import "RMMarker.h"
#import "RMPath.h"
#import "RMGlobalConstants.h"
#import "RMInteractiveSource.h"
#import "RMCompositeSource.h"

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

#define kDSPlacemarkAlpha            0.9f
#define kDSPathShadowBlur            10.0f
#define kDSPathShadowOffset          CGSizeMake(3, 3)
#define kDSPathDefaultLineWidth      2.0f
#define kDSPointAnnotationTypeName   @"kDSPointAnnotationType"
#define kDSLineAnnotationTypeName    @"kDSLineStringAnnotationType"
#define kDSPolygonAnnotationTypeName @"kDSPolygonAnnotationType"
#define kDSOverlayAnnotationTypeName @"kDSOverlayAnnotationType"

@interface DSMapBoxDataOverlayManager ()

@property (nonatomic, strong) RMMapView *mapView;
@property (nonatomic, strong) DSMapBoxPopoverController *balloon;
@property (nonatomic, assign) float lastKnownZoom;

@end

#pragma mark -

@implementation DSMapBoxDataOverlayManager

@synthesize mapView;
@synthesize balloon;
@synthesize lastKnownZoom;

- (id)initWithMapView:(RMMapView *)inMapView
{
    self = [super init];

    if (self != nil)
    {
        mapView  = inMapView;
        
        lastKnownZoom = mapView.zoom;
    }
    
    return self;
}

#pragma mark -

- (NSArray *)addOverlayForKML:(SimpleKML *)kml
{
    // collect supported features that we're going to plot
    //
    NSMutableSet *features = [NSMutableSet set];
    
    if ([kml.feature isKindOfClass:[SimpleKMLContainer class]])
    {
        SimpleKMLContainer *container = (SimpleKMLContainer *)kml.feature;
        
        // get placemarks at all depths (mostly working around Folder nesting)
        //
        [features addObjectsFromArray:container.flattenedPlacemarks];
        
        // add any other top-level features (e.g., GroundOverlay)
        //
        [features addObjectsFromArray:container.features];
    }
    else if ([kml.feature isKindOfClass:[SimpleKMLGroundOverlay class]])
    {
        [features addObject:kml.feature];
    }
        
    // iterate & handle supported features
    //
    NSMutableArray *annotationsToAdd = [NSMutableArray array];
    
    for (SimpleKMLFeature *feature in features)
    {
        // placemarks will become RMMarkers with popups
        //
        if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && ((SimpleKMLPlacemark *)feature).point)
        {
            UIImage *icon = nil;
            
            if (((SimpleKMLPlacemark *)feature).style && ((SimpleKMLPlacemark *)feature).style.iconStyle)
                icon = ((SimpleKMLPlacemark *)feature).style.iconStyle.icon;
            
            if (((SimpleKMLPlacemark *)feature).style.balloonStyle)
            {
                // TODO: style the balloon according to the given style
            }
            
            CLLocationCoordinate2D coordinate = ((SimpleKMLPlacemark *)feature).point.coordinate;
            
            RMAnnotation *pointAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:coordinate andTitle:nil];
            
            pointAnnotation.annotationType = kDSPointAnnotationTypeName;
            
            pointAnnotation.userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:feature,      @"placemark",
                                                                                         [kml source], @"source",
                                                                                         nil];

            if (icon)
                [pointAnnotation.userInfo setObject:icon forKey:@"icon"];
            
            [annotationsToAdd addObject:pointAnnotation];
        }
        
        // line strings will become RMPaths
        //
        else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && ((SimpleKMLPlacemark *)feature).lineString)
        {
            SimpleKMLLineString *lineString = ((SimpleKMLPlacemark *)feature).lineString;

            RMAnnotation *lineStringAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:((CLLocation *)[lineString.coordinates objectAtIndex:0]).coordinate andTitle:nil]; // FIXME what coord do we use here? 
            
            lineStringAnnotation.annotationType = kDSLineAnnotationTypeName;
            
            lineStringAnnotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:feature,      @"lineString",
                                                                                       [kml source], @"source", 
                                                                                       nil];
                        
            [lineStringAnnotation setBoundingBoxFromLocations:lineString.coordinates];
            
            lineStringAnnotation.clusteringEnabled = NO;

            [annotationsToAdd addObject:lineStringAnnotation];
        }
        
        // polygons will become RMPaths
        //
        else if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && ((SimpleKMLPlacemark *)feature).polygon)
        {
            SimpleKMLLinearRing *outerBoundary = ((SimpleKMLPlacemark *)feature).polygon.outerBoundary;
            
            RMAnnotation *polygonAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:((CLLocation *)[outerBoundary.coordinates objectAtIndex:0]).coordinate andTitle:nil];
            
            polygonAnnotation.annotationType = kDSPolygonAnnotationTypeName;
            
            polygonAnnotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:feature,      @"polygon",
                                                                                    [kml source], @"source", 
                                                                                    nil];
                        
            [polygonAnnotation setBoundingBoxFromLocations:outerBoundary.coordinates];

            polygonAnnotation.clusteringEnabled = NO;
            
            [annotationsToAdd addObject:polygonAnnotation];
        }
    
        // overlays will become direct map layers
        //
        else if ([feature isKindOfClass:[SimpleKMLGroundOverlay class]] && ((SimpleKMLGroundOverlay *)feature).icon)
        {
            // get overlay, create layer, and get bounds
            //
            SimpleKMLGroundOverlay *groundOverlay = (SimpleKMLGroundOverlay *)feature;
            
            RMAnnotation *groundOverlayAnnotation = [RMAnnotation annotationWithMapView:self.mapView coordinate:CLLocationCoordinate2DMake(groundOverlay.north, groundOverlay.east) andTitle:nil];
            
            groundOverlayAnnotation.annotationType = kDSOverlayAnnotationTypeName;
            
            groundOverlayAnnotation.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:feature,      @"groundOverlay",
                                                                                          [kml source], @"source", 
                                                                                          nil];
            
            [groundOverlayAnnotation setBoundingBoxCoordinatesSouthWest:CLLocationCoordinate2DMake(groundOverlay.south, groundOverlay.west) 
                                                              northEast:CLLocationCoordinate2DMake(groundOverlay.north, groundOverlay.east)];
            
            [annotationsToAdd addObject:groundOverlayAnnotation];
        }
    }

    [self.mapView addAnnotations:annotationsToAdd];
    
    return annotationsToAdd;
}

- (NSArray *)addOverlayForGeoRSS:(NSString *)rss
{
    return nil;
    
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
        
        RMMarker *marker = [[RMMarker alloc] initWithUIImage:image];
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude  = [[item objectForKey:@"latitude"]  floatValue];
        coordinate.longitude = [[item objectForKey:@"longitude"] floatValue];

        CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        
        // create a generic point with the RSS item's attributes plus location for clustering
        //
        marker.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[item objectForKey:@"title"], @"title",
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
        
        [overlay addObject:marker];
    }
    
    if ([overlay count])
    {
        // calculate bounds showing all points plus a 10% border on the edges
        //
        RMSphericalTrapezium overlayBounds = { 
            .northEast = {
                .latitude  = maxLat + (0.1 * (maxLat - minLat)),
                .longitude = maxLon + (0.1 * (maxLon - minLon))
            },
            .southWest = {
                .latitude  = minLat - (0.1 * (maxLat - minLat)),
                .longitude = minLon - (0.1 * (maxLat - minLat))
            }
        };
        
        //return overlayBounds;
    }
    
    //return [self.mapView latitudeLongitudeBoundingBox];
}

- (NSArray *)addOverlayForGeoJSON:(NSString *)json
{
    return nil;
    
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
            
            RMMarker *marker = [[RMMarker alloc] initWithUIImage:image];
            
            CLLocation *location = [[item objectForKey:@"geometries"] objectAtIndex:0];
            
            CLLocationCoordinate2D coordinate = location.coordinate;
            
            // create a generic point with the GeoJSON item's properties plus location for clustering
            //
            marker.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Point %@", [item objectForKey:@"id"]], @"title",
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
            
            [overlay addObject:marker];
        }
        else if ([[item objectForKey:@"type"] intValue] == DSMapBoxGeoJSONGeometryTypeLineString)
        {
            RMPath *path = [[RMPath alloc] initWithView:self.mapView];
            
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
                    [path moveToCoordinate:geometry.coordinate];
                    
                    hasStarted = YES;
                }

                else
                    [path addLineToCoordinate:geometry.coordinate];
            }
            
//            [self.mapView.contents.overlay addSublayer:path];
            
            [overlay addObject:path];
        }
        else if ([[item objectForKey:@"type"] intValue] == DSMapBoxGeoJSONGeometryTypePolygon)
        {
            for (NSArray *linearRing in [item objectForKey:@"geometries"])
            {
                RMPath *path = [[RMPath alloc] initWithView:self.mapView];
                
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
                        [path moveToCoordinate:point.coordinate];
                        
                        hasStarted = YES;
                    }
                    
                    else
                        [path addLineToCoordinate:point.coordinate];
                }
                
                [path closePath];
                
//                [self.mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
        }
    }
    
    if ([overlay count])
    {
        // calculate bounds showing all points plus a 10% border on the edges
        //
        RMSphericalTrapezium overlayBounds = { 
            .northEast = {
                .latitude  = maxLat + (0.1 * (maxLat - minLat)),
                .longitude = maxLon + (0.1 * (maxLon - minLon))
            },
            .southWest = {
                .latitude  = minLat - (0.1 * (maxLat - minLat)),
                .longitude = minLon - (0.1 * (maxLat - minLat))
            }
        };
        
        //return overlayBounds;
    }
    
    //return [self.mapView latitudeLongitudeBoundingBox];
}

- (void)removeAllOverlays
{
    [self.mapView removeAllAnnotations];
    
    if (self.balloon.popoverVisible)
        [self.balloon dismissPopoverAnimated:NO];
}

- (void)removeOverlayWithSource:(NSString *)source
{
    NSArray *annotationsToRemove = [self.mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.userInfo.source = %@", source]];
    
    [self.mapView removeAnnotations:annotationsToRemove];
    
    if (self.balloon.popoverVisible)
        [self.balloon dismissPopoverAnimated:NO];
}

#pragma mark -

- (void)singleTapOnMap:(RMMapView *)map at:(CGPoint)point
{
    // Hack to dismiss interactivity when tapping on interactive
    // map view, despite it being the only popover passthrough view.
    // Adding, say, the top toolbar to passthrough results in multiple
    // popovers possibly being displayed (ex: interactivity + layers UI),
    // which is grounds for App Store rejection. Easiest thing for now
    // is just to assume all map views (currently main & TileStream 
    // preview) have a top toolbar and account for that. 
    //
    // See https://github.com/developmentseed/MapBoxiPad/issues/52
    //
    if (point.y > 44 && [map supportsInteractivity])
    {
        // try full, then teaser content
        //
        NSString *formattedOutput = [map formattedOutputOfType:RMInteractiveSourceOutputTypeFull forPoint:point];
        
        if ( ! formattedOutput || ! [formattedOutput length])
            formattedOutput = [map formattedOutputOfType:RMInteractiveSourceOutputTypeTeaser forPoint:point];
        
        // display/"move" popup if we have content
        //
        if (formattedOutput && [formattedOutput length])
        {
            if (self.balloon.popoverVisible)
                [self.balloon dismissPopoverAnimated:NO];
            
            DSMapBoxBalloonController *balloonController = [[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil];
            
            self.balloon = [[DSMapBoxPopoverController alloc] initWithContentViewController:[[UIViewController alloc] initWithNibName:nil bundle:nil]];
            
            self.balloon.passthroughViews = [NSArray arrayWithObject:self.mapView];
            self.balloon.delegate = self;
            
            balloonController.name        = @"";
            balloonController.description = formattedOutput;
            
            self.balloon.popoverContentSize = CGSizeMake(320, 160);
            
            [self.balloon setContentViewController:balloonController];
            
            [self.balloon presentPopoverFromRect:CGRectMake(point.x, point.y, 1, 1) 
                                          inView:map
                                        animated:YES];
            
            [TestFlight passCheckpoint:@"tapped interactive layer"];
            
            return;
        }
    }
    
    // dismiss if non-interactive or no content
    //
    if (self.balloon.popoverVisible)
        [self.balloon dismissPopoverAnimated:YES];
}

- (void)tapOnAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map;
{
    if (self.balloon.popoverVisible)
        [self.balloon dismissPopoverAnimated:NO];
    
    NSDictionary *annotationInfo = ((NSDictionary *)annotation.userInfo);
    
    DSMapBoxBalloonController *balloonController = [[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil];
    CGRect attachPoint;
    
    // init with generic view controller
    //
    self.balloon = [[DSMapBoxPopoverController alloc] initWithContentViewController:[[UIViewController alloc] initWithNibName:nil bundle:nil]];
    
    self.balloon.passthroughViews = [NSArray arrayWithObject:self.mapView];
    self.balloon.delegate = self;
    
    // KML placemarks have their own title & description
    //
    if ([annotationInfo objectForKey:@"placemark"])
    {
        SimpleKMLPlacemark *placemark = (SimpleKMLPlacemark *)[annotationInfo objectForKey:@"placemark"];
        
        balloonController.name        = placemark.name;
        balloonController.description = placemark.featureDescription;
        
        attachPoint = CGRectMake([self.mapView coordinateToPixel:placemark.point.coordinate].x,
                                 [self.mapView coordinateToPixel:placemark.point.coordinate].y, 
                                 1,
                                 1);
        
        self.balloon.popoverContentSize = CGSizeMake(320, 160);
    }
    
    // GeoRSS points have a title & description from the feed
    //
    else
    {
        balloonController.name        = [annotationInfo objectForKey:@"title"];
        balloonController.description = [annotationInfo objectForKey:@"description"];
        
        CLLocationCoordinate2D latLong = [self.mapView projectedPointToCoordinate:annotation.projectedLocation];
        
        attachPoint = CGRectMake([self.mapView coordinateToPixel:latLong].x,
                                 [self.mapView coordinateToPixel:latLong].y, 
                                 1, 
                                 1);
        
        self.balloon.popoverContentSize = CGSizeMake(320, 160);
    }
    
    // replace with balloon view controller
    //
    [self.balloon setContentViewController:balloonController];
    
    [self.balloon presentPopoverFromRect:attachPoint
                                  inView:self.mapView
                                animated:YES];
    
    [TestFlight passCheckpoint:@"tapped on marker"];
}

- (void)tapOnLabelForAnnotation:(RMAnnotation *)annotation onMap:(RMMapView *)map
{
    [self tapOnAnnotation:annotation onMap:map];
}

- (void)mapViewRegionDidChange:(RMMapView *)map
{
    // popover handling
    //
    if (self.balloon.popoverVisible)
    {
        if (self.lastKnownZoom != map.zoom)
        {
            // dismiss popover if the user has zoomed
            //
            [self.balloon dismissPopoverAnimated:NO];
        }
        else
        {
            // determine screen point to keep popover at same lat/long
            //
            RMProjectedPoint oldProjectedPoint      = self.balloon.projectedPoint;
            CLLocationCoordinate2D oldAttachLatLong = [map projectedPointToCoordinate:oldProjectedPoint];
            CGPoint newAttachPoint                  = [map coordinateToPixel:oldAttachLatLong];
            
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
    
//    // out-of-zoom-bounds warnings
//    //
//    if ([map.tileSource isKindOfClass:[RMMBTilesSource class]])
//    {
//        RMMBTilesSource *source = (RMMBTilesSource *)map.tileSource;
//        
//        NSInteger newTag;
//        
//        if (map.zoom > [source maxZoomNative] || map.zoom < [source minZoomNative])
//        {
//            newTag = 0; // out of bounds
//            
//            // Only warn once per bounds limit crossing. We use tag as a way to 
//            // mark which layer we're warning the user about.
//            //
//            if (map.tag != newTag)
//                [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxZoomBoundsReached object:map];
//        }
//        
//        else
//            newTag = 1; // in bounds
//        
//        map.tag = newTag;
//    }
    
    self.lastKnownZoom = map.zoom;
}

- (RMMapLayer *)mapView:(RMMapView *)mapView layerForAnnotation:(RMAnnotation *)annotation
{
    if ([annotation.annotationType isEqualToString:kRMClusterAnnotationTypeName])
    {
        RMQuadTreeNode *quadTreeNode = annotation.userInfo;
        
        CGFloat size = 44.0 + (50.0 * (((CGFloat)[quadTreeNode.clusteredAnnotations count]) / (CGFloat)[quadTreeNode.clusterAnnotation.mapView.annotations count]));
        
        UIImage *image = [[[UIImage imageNamed:@"circle.png"] imageWithAlphaComponent:0.7] imageWithWidth:size height:size];
        
        RMMarker *clusterMarker = [[RMMarker alloc] initWithUIImage:image];
        
        NSString *labelText      = [NSString stringWithFormat:@"%i",        [quadTreeNode.clusteredAnnotations count]];
        NSString *touchLabelText = [NSString stringWithFormat:@"%i Points", [quadTreeNode.clusteredAnnotations count]];
        
        // build up summary of clustered points
        //
        NSMutableArray *descriptions = [NSMutableArray array];
        
        for (RMMarker *clusterMarker in quadTreeNode.clusteredAnnotations)
        {
            NSDictionary *clusterMarkerData = ((NSDictionary *)clusterMarker.userInfo);
            
            if ([clusterMarkerData objectForKey:@"placemark"])
            {
                SimpleKMLPlacemark *placemark = (SimpleKMLPlacemark *)[clusterMarkerData objectForKey:@"placemark"];
                
                [descriptions addObject:placemark.name];
            }
            
            else if ([clusterMarkerData objectForKey:@"title"])
                [descriptions addObject:[clusterMarkerData objectForKey:@"title"]];
        }
        
        [descriptions sortUsingSelector:@selector(compare:)];
        
        // build the cluster marker
        //
        clusterMarker.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:touchLabelText,                                                     @"title",
                                                                            [descriptions componentsJoinedByString:@", "],                      @"description",
                                                                            [NSNumber numberWithInt:[quadTreeNode.clusteredAnnotations count]], @"count",
                                                                            nil];
        
        [clusterMarker changeLabelUsingText:labelText
                                       font:[RMMarker defaultFont]
                            foregroundColor:[UIColor whiteColor]
                            backgroundColor:[UIColor clearColor]];
        
        clusterMarker.zPosition = -1;
        
        return clusterMarker;
    }
    else if ([annotation.annotationType isEqualToString:kDSPointAnnotationTypeName])
    {
        UIImage *pointImage = ([annotation.userInfo objectForKey:@"icon"] ? [annotation.userInfo objectForKey:@"icon"] : [[[UIImage imageNamed:@"point.png"] imageWithWidth:44.0 height:44.0] imageWithAlphaComponent:kDSPlacemarkAlpha]); // FIXME optimize reuse
        
        RMMarker *pointMarker = [[RMMarker alloc] initWithUIImage:pointImage];

        return pointMarker;
    }
    else if ([annotation.annotationType isEqualToString:kDSLineAnnotationTypeName])
    {
        SimpleKMLPlacemark *feature = [annotation.userInfo objectForKey:@"lineString"];
        
        RMPath *path = [[RMPath alloc] initWithView:self.mapView];
        
        path.lineColor    = (feature.style.lineStyle.color ? feature.style.lineStyle.color : kMapBoxBlue);
        path.lineWidth    = (feature.style.lineStyle.width ? feature.style.lineStyle.width : kDSPathDefaultLineWidth);
        path.fillColor    = [UIColor clearColor];
        path.shadowBlur   = kDSPathShadowBlur;
        path.shadowOffset = kDSPathShadowOffset;
        
        BOOL hasStarted = NO;
        
        for (CLLocation *location in feature.lineString.coordinates)
        {
            if ( ! hasStarted)
            {
                [path moveToCoordinate:location.coordinate];
                hasStarted = YES;
            }
            
            else
                [path addLineToCoordinate:location.coordinate];
        }
        
        return path;
    }
    else if ([annotation.annotationType isEqualToString:kDSPolygonAnnotationTypeName])
    {
        SimpleKMLPlacemark *feature = [annotation.userInfo objectForKey:@"polygon"];
        
        RMPath *path = [[RMPath alloc] initWithView:self.mapView];
        
        path.lineColor = (feature.style.lineStyle.color ? feature.style.lineStyle.color : kMapBoxBlue);
        
        if (feature.style.polyStyle.fill)
            path.fillColor = feature.style.polyStyle.color;
        
        else
            path.fillColor = [UIColor clearColor];
        
        path.lineWidth    = (feature.style.lineStyle.width ? feature.style.lineStyle.width : kDSPathDefaultLineWidth);
        path.shadowBlur   = kDSPathShadowBlur;
        path.shadowOffset = kDSPathShadowOffset;
        
        SimpleKMLLinearRing *outerBoundary = feature.polygon.outerBoundary;
        
        BOOL hasStarted = NO;
        
        for (CLLocation *location in outerBoundary.coordinates)
        {
            if ( ! hasStarted)
            {
                [path moveToCoordinate:location.coordinate];
                hasStarted = YES;
            }
            
            else
                [path addLineToCoordinate:location.coordinate];
        }
        
        return path;
    }
    else if ([annotation.annotationType isEqualToString:kDSOverlayAnnotationTypeName])
    {
        SimpleKMLGroundOverlay *groundOverlay = [annotation.userInfo objectForKey:@"groundOverlay"];
        
        CLLocationCoordinate2D ne = CLLocationCoordinate2DMake(groundOverlay.north, groundOverlay.east);
        CLLocationCoordinate2D nw = CLLocationCoordinate2DMake(groundOverlay.north, groundOverlay.west);
        CLLocationCoordinate2D se = CLLocationCoordinate2DMake(groundOverlay.south, groundOverlay.east);
        
        CGPoint nePoint = [self.mapView coordinateToPixel:ne];
        CGPoint nwPoint = [self.mapView coordinateToPixel:nw];
        CGPoint sePoint = [self.mapView coordinateToPixel:se];
        
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
        RMMapLayer *overlayLayer = [RMMapLayer layer];
        
        overlayLayer.frame = overlayRect;
        
        overlayLayer.contents = (id)[overlayImage CGImage];
        
        return overlayLayer; // FIXME doesn't scale with map
    }
    
    return nil;
}

#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.balloon = nil;
}

@end