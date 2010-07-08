//
//  DSMapBoxOverlayManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/8/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxOverlayManager.h"

#import "RMMapView.h"
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
    
    [super dealloc];
}

#pragma mark -

- (void)addOverlayForKML:(SimpleKML *)kml
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
            [overlays addObject:overlay];
    }
}

- (void)addOverlayForGeoRSS:(NSString *)rss
{
    NSLog(@"adding %@", rss);
}

- (void)removeAllOverlays
{
    [mapView.contents.markerManager removeMarkers];
    mapView.contents.overlay.sublayers = nil;
    
    [overlays removeAllObjects];
}

- (NSArray *)overlays
{
    return [NSArray arrayWithArray:overlays];
}

@end