//
//  DSMapBoxMarkerCluster.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/5/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class RMMarker;

@interface DSMapBoxMarkerCluster : NSObject
{
    NSMutableArray *markers;
    CLLocationCoordinate2D center;
}

@property (nonatomic, readonly, retain) NSArray *markers;
@property (nonatomic, readonly, assign) CLLocationCoordinate2D center;

- (void)addMarker:(RMMarker *)marker;
- (void)removeMarker:(RMMarker *)marker;

@end