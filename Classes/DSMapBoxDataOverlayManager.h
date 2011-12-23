//
//  DSMapBoxDataOverlayManager.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/8/10.
//  Copyright 2010 Development Seed. All rights reserved.
//
//  This class manages the data layers associated with a map view.
//  Data layers consist of KML, GeoRSS, GeoJSON, and any other CALayer-
//  based overlays placed on the map view and can be ordered relative 
//  to each other in the stack order. 
//
//  DSMapBoxLayerManager manages us (as well as the stacked map views)
//  so that we are always overlaying data on the top-most map view. 
//  That class also takes care of transferring our overlays and 
//  re-associating us with the new top-most map view.
//

#import "DSMapView.h"
#import "RMLatLong.h"

@class SimpleKML;
@class DSMapBoxPopoverController;

@interface DSMapBoxDataOverlayManager : NSObject <RMMapViewDelegate, UIPopoverControllerDelegate, DSMapBoxInteractivityDelegate>

@property (nonatomic, strong) DSMapView *mapView;
@property (nonatomic, strong) NSMutableArray *overlays;

- (id)initWithMapView:(DSMapView *)inMapView;
- (RMSphericalTrapezium)addOverlayForKML:(SimpleKML *)kml;
- (RMSphericalTrapezium)addOverlayForGeoRSS:(NSString *)rss;
- (RMSphericalTrapezium)addOverlayForGeoJSON:(NSString *)json;
- (void)removeAllOverlays;
- (void)removeOverlayWithSource:(NSString *)source;

@end