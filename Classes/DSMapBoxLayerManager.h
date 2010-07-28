//
//  DSMapBoxLayerManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  This class manages the behind-the-scenes work of toggling and ordering
//  both tiled map views as well as data overlays, which must be layered 
//  over the top-most map view. 
//
//  That is, KML & GeoRSS overlays, as CALayer subclasses, must always be
//  part of the 'overlay' member of the top-most RMMapView (or subclass)
//  so that they show up on top. They can then be ordered among themselves.
//
//  Below that, the RMMapView objects can be ordered above the base map 
//  layer in order to display their tiles in different stacking orders.
//  When they get changed, the data overlays above must get moved to the
//  new top-most map view. 
//

#import <UIKit/UIKit.h>

@class DSMapBoxDataOverlayManager;

typedef enum {
    DSMapBoxLayerTypeTile   = 0,
    DSMapBoxLayerTypeKML    = 1,
    DSMapBoxLayerTypeGeoRSS = 2,
} DSMapBoxLayerType;

@interface DSMapBoxLayerManager : NSObject
{
    DSMapBoxDataOverlayManager *dataOverlayManager;
    NSArray *tileLayers;
    NSArray *dataLayers;
}

@property (nonatomic, readonly, retain) NSArray *tileLayers;
@property (nonatomic, readonly, retain) NSArray *dataLayers;
@property (nonatomic, readonly, assign) NSUInteger tileLayerCount;
@property (nonatomic, readonly, assign) NSUInteger dataLayerCount;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager;
- (void)moveLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)archiveLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)index;
- (void)toggleLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)index;

@end