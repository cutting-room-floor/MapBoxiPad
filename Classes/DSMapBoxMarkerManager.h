//
//  DSMapBoxMarkerManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/4/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "RMMarkerManager.h"

#define kDSPlacemarkAlpha 0.7f

@interface DSMapBoxMarkerManager : RMMarkerManager
{
    BOOL clusteringEnabled;
    NSMutableArray *clusters;
}

@property (nonatomic, assign) BOOL clusteringEnabled;

- (void)addMarker:(RMMarker *)marker AtLatLong:(CLLocationCoordinate2D)point recalculatingImmediately:(BOOL)flag;
- (void)removeMarker:(RMMarker *)marker recalculatingImmediately:(BOOL)flag;
- (void)recalculateClusters;

@end