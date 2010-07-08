//
//  DSMapBoxOverlayManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/8/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kPlacemarkAlpha  0.7f

@class RMMapView;
@class SimpleKML;

@interface DSMapBoxOverlayManager : NSObject
{
    RMMapView *mapView;
    NSMutableArray *overlays;
}

- (id)initWithMapView:(RMMapView *)inMapView;
- (void)addOverlayForKML:(SimpleKML *)kml;
- (void)addOverlayForGeoRSS:(NSString *)rss;
- (void)removeAllOverlays;
- (NSArray *)overlays;

@end