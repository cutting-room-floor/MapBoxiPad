//
//  DSMapBoxMarkerManager.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/4/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "RMMarkerManager.h"

@interface DSMapBoxMarkerManager : RMMarkerManager
{
    NSMutableArray *clusters;
}

@property (nonatomic, assign) BOOL clusteringEnabled;
@property (nonatomic, readonly, retain) NSArray *clusters;

- (void)addMarker:(RMMarker *)marker AtLatLong:(CLLocationCoordinate2D)point recalculatingImmediately:(BOOL)flag;
- (void)removeMarkersAndClusters;
- (void)removeMarker:(RMMarker *)marker recalculatingImmediately:(BOOL)flag;
- (void)recalculateClusters;
- (void)takeClustersFromMarkerManager:(DSMapBoxMarkerManager *)markerManager;

@end