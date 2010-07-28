//
//  DSMapBoxDataOverlayManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/8/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  This class manages the data layers associated with a map view.
//  Data layers consist of KML, GeoRSS, and any other CALayer-based
//  overlays placed on the map view and can be ordered relative to 
//  each other in the stack order. 
//
//  DSMapBoxLayerManager manages us (as well as the stacked map views)
//  so that we are always overlaying data on the top-most map view. 
//  That class also takes care of transferring our overlays and 
//  re-associating us with the new top-most map view.
//

#import <UIKit/UIKit.h>

#import "RMMapView.h"
#import "RMLatLong.h"

#define kPlacemarkAlpha 0.7f

@class RMMapView;
@class SimpleKML;

@interface DSMapBoxDataOverlayManager : NSObject <RMMapViewDelegate, UIPopoverControllerDelegate>
{
    RMMapView *mapView;
    NSMutableArray *overlays;
    IBOutlet UIView *stripeView;
    IBOutlet UILabel *stripeViewLabel;
    NSMutableDictionary *lastMarkerInfo;
    NSTimer *animationTimer;
}

@property (nonatomic, retain) RMMapView *mapView;

- (id)initWithMapView:(RMMapView *)inMapView;
- (RMSphericalTrapezium)addOverlayForKML:(SimpleKML *)kml;
- (RMSphericalTrapezium)addOverlayForGeoRSS:(NSString *)rss;
- (void)removeAllOverlays;
- (void)removeOverlayWithSource:(NSString *)source;
- (NSArray *)overlays;

@end