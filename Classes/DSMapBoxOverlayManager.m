//
//  DSMapBoxOverlayManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/8/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxOverlayManager.h"

#import "DSMapBoxBalloonController.h"
#import "DSMapBoxFeedParser.h"

#import <CoreLocation/CoreLocation.h>

#import "RMMapView.h"
#import "RMProjection.h"
#import "RMMarkerManager.h"
#import "RMLayerCollection.h"
#import "RMPath.h"

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

@implementation DSMapBoxOverlayManager

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
    [animationTimer release];
    
    [super dealloc];
}

#pragma mark -

- (NSArray *)addOverlayForKML:(SimpleKML *)kml
{
    if ([kml.feature isKindOfClass:[SimpleKMLContainer class]])
    {
        NSMutableArray *overlay = [NSMutableArray array];
        
        for (SimpleKMLFeature *feature in ((SimpleKMLContainer *)kml.feature).features)
        {
            if ([feature isKindOfClass:[SimpleKMLPlacemark class]] && 
                ((SimpleKMLPlacemark *)feature).point              &&
                ((SimpleKMLPlacemark *)feature).style              && 
                ((SimpleKMLPlacemark *)feature).style.iconStyle)
            {
                UIImage *icon = ((SimpleKMLPlacemark *)feature).style.iconStyle.icon;
                
                RMMarker *marker;
                
                if (((SimpleKMLPlacemark *)feature).style.balloonStyle)
                {
                    marker = [[[RMMarker alloc] initWithUIImage:icon] autorelease];
                    
                    // we setup a balloon for later
                    //
                    marker.data = [NSDictionary dictionaryWithObjectsAndKeys:marker,                        @"marker",
                                                                             feature,                       @"placemark",
                                                                             [NSNumber numberWithBool:YES], @"hasBalloon",
                                                                             nil];
                }
                else
                {
                    marker = [[[RMMarker alloc] initWithUIImage:[icon imageWithAlphaComponent:kPlacemarkAlpha]] autorelease];
                    
                    // we store the original icon & alpha value for later use in the pulse animation
                    //
                    marker.data = [NSDictionary dictionaryWithObjectsAndKeys:marker,                                     @"marker", 
                                                                             feature.name,                               @"label", 
                                                                             icon,                                       @"icon",
                                                                             [NSNumber numberWithFloat:kPlacemarkAlpha], @"alpha",
                                                                             nil];
                }
                
                [[[RMMarkerManager alloc] initWithContents:mapView.contents] autorelease];
                
                [mapView.contents.markerManager addMarker:marker AtLatLong:((SimpleKMLPlacemark *)feature).point.coordinate];
                
                [overlay addObject:marker];
            }
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
                }
                
                [mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
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
                }
                
                [mapView.contents.overlay addSublayer:path];
                
                [overlay addObject:path];
            }
        }
        
        if ([overlay count])
        {
            [overlays addObject:overlay];

            return [NSArray arrayWithArray:overlay];
        }
    }
    
    return [NSArray array];
}

- (NSArray *)addOverlayForGeoRSS:(NSString *)rss
{
    NSMutableArray *overlay = [NSMutableArray array];
    
    UIImage *image = [[[UIImage imageNamed:@"georss_circle.png"] imageWithWidth:32.0 height:32.0] imageWithAlphaComponent:kPlacemarkAlpha];

    NSArray *items = [DSMapBoxFeedParser itemsForFeed:rss];
    
    for (NSDictionary *item in items)
    {
        NSString *balloonBlurb = [NSString stringWithFormat:@"%@<br/><br/><em>%@</em><br/><br/><a href=\"%@\">more</a>", 
                                     [item objectForKey:@"description"], 
                                     [item objectForKey:@"date"], 
                                     [item objectForKey:@"link"]];
        
        RMMarker *marker = [[[RMMarker alloc] initWithUIImage:image] autorelease];
        
        marker.data = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"hasBalloon",
                                                                 [item objectForKey:@"title"],  @"title",
                                                                 balloonBlurb,                  @"description",
                                                                 nil];
        
        [[[RMMarkerManager alloc] initWithContents:mapView.contents] autorelease];
        
        CLLocationCoordinate2D coordinate;
        coordinate.latitude  = [[item objectForKey:@"latitude"]  floatValue];
        coordinate.longitude = [[item objectForKey:@"longitude"] floatValue];
        
        [mapView.contents.markerManager addMarker:marker AtLatLong:coordinate];
        
        [overlay addObject:marker];
    }
    
    if ([overlay count])
    {
        [overlays addObject:overlay];

        return [NSArray arrayWithArray:overlay];
    }
    
    return [NSArray array];
}

- (void)removeAllOverlays
{
    [mapView.contents.markerManager removeMarkers];
    mapView.contents.overlay.sublayers = nil;
    
    stripeView.hidden = YES;
    stripeViewLabel.text = @"";
    
    [overlays removeAllObjects];
}

- (NSArray *)overlays
{
    return [NSArray arrayWithArray:overlays];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    stripeView.hidden = NO;
    
    stripeViewLabel.text = [lastMarkerInfo objectForKey:@"label"];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    
    CGPoint oldCenter = stripeViewLabel.center;
    stripeViewLabel.center  = CGPointMake(oldCenter.x + 200, oldCenter.y);
    
    oldCenter = stripeView.center;
    stripeView.center = CGPointMake(oldCenter.x + 200, oldCenter.y);
    
    [UIView commitAnimations];
}

- (void)pulse:(NSTimer *)aTimer
{
    // we go after the stored marker metadata since you can't get the original sized image nor the alpha from an RMMarker
    //
    RMMarker *marker = [lastMarkerInfo  objectForKey:@"marker"];
    UIImage  *image  = [lastMarkerInfo  objectForKey:@"icon"];
    CGFloat   alpha  = [[lastMarkerInfo objectForKey:@"alpha"] floatValue];
    
    if (alpha >= kPlacemarkAlpha)
        alpha = 0.1;
    
    else
        alpha = alpha + 0.1;
    
    [marker replaceUIImage:[image imageWithAlphaComponent:alpha]];
    
    [lastMarkerInfo setObject:[NSNumber numberWithFloat:alpha] forKey:@"alpha"];
}

#pragma mark -

- (void)tapOnMarker:(RMMarker *)marker onMap:(RMMapView *)map
{
    // don't respond to clicks on currently highlighted marker
    //
    if ([stripeViewLabel.text isEqualToString:[((NSDictionary *)marker.data) objectForKey:@"label"]])
        return;
    
    NSDictionary *markerData = ((NSDictionary *)marker.data);
    
    if ([markerData objectForKey:@"hasBalloon"]) // balloon popover
    {
        DSMapBoxBalloonController *balloonController = [[[DSMapBoxBalloonController alloc] initWithNibName:nil bundle:nil] autorelease];
        CGRect attachPoint;
        
        if ([markerData objectForKey:@"placemark"]) // KML placemark
        {
            SimpleKMLPlacemark *placemark = (SimpleKMLPlacemark *)[markerData objectForKey:@"placemark"];
            
            balloonController.name        = placemark.name;
            balloonController.description = placemark.featureDescription;
            
            attachPoint = CGRectMake([mapView.contents latLongToPixel:placemark.point.coordinate].x,
                                     [mapView.contents latLongToPixel:placemark.point.coordinate].y, 
                                     1, 
                                     1);
        }
        else // GeoRSS item
        {
            balloonController.name        = [markerData objectForKey:@"title"];
            balloonController.description = [markerData objectForKey:@"description"];
            
            RMLatLong latLong = [mapView.contents.projection pointToLatLong:marker.projectedLocation];
            
            attachPoint = CGRectMake([mapView.contents latLongToPixel:latLong].x,
                                     [mapView.contents latLongToPixel:latLong].y, 
                                     1, 
                                     1);
        }
        
        UIPopoverController *balloonPopover = [[UIPopoverController alloc] initWithContentViewController:balloonController]; // released by delegate
        
        balloonPopover.popoverContentSize = CGSizeMake(320, 320);
        balloonPopover.delegate = self;
        
        [balloonPopover presentPopoverFromRect:attachPoint
                                        inView:mapView 
                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                      animated:NO];
    }
    else // balloon-less label on animated stripe
    {
        // return last marker to full alpha
        //
        if (lastMarkerInfo)
        {
            [animationTimer invalidate];
            [animationTimer release];
            
            RMMarker *lastMarker      = [lastMarkerInfo objectForKey:@"marker"];
            UIImage  *lastMarkerImage = [lastMarkerInfo objectForKey:@"icon"];
            
            [lastMarker replaceUIImage:[lastMarkerImage imageWithAlphaComponent:kPlacemarkAlpha]];
        }
        
        // load stripe if needed
        //
        if ( ! stripeView)
        {
            [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxOverlayStripeView" owner:self options:nil];
            
            stripeViewLabel.text = @"";
            stripeView.hidden = YES;
            
            [mapView addSubview:stripeView];
            
            stripeView.frame = CGRectMake(mapView.frame.origin.x - 10, 
                                          mapView.frame.size.height - stripeView.frame.size.height - 10, 
                                          stripeView.frame.size.width, 
                                          stripeView.frame.size.height);
        }
        
        // animate label swap
        //
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
        
        if ([stripeViewLabel.text isEqualToString:@""])
            [UIView setAnimationDuration:0.0];
        
        CGPoint oldCenter  = stripeViewLabel.center;
        stripeViewLabel.center  = CGPointMake(oldCenter.x - 200, oldCenter.y);
        
        oldCenter  = stripeView.center;
        stripeView.center = CGPointMake(oldCenter.x - 200, oldCenter.y);
        
        [UIView commitAnimations];
        
        // update last marker & fire off pulse animation on this one
        //
        [lastMarkerInfo release];
        lastMarkerInfo = [[NSMutableDictionary dictionaryWithDictionary:((NSDictionary *)marker.data)] retain];
        
        animationTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                           target:self
                                                         selector:@selector(pulse:)
                                                         userInfo:nil
                                                          repeats:YES] retain];
    }
}

#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [popoverController release];
}

@end