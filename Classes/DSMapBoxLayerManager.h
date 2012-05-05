//
//  DSMapBoxLayerManager.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Development Seed. All rights reserved.
//
//  This class manages the behind-the-scenes work of toggling and ordering
//  both tiled map views as well as data overlays, which must be layered 
//  over the top-most map view. 
//
//  That is, KML & GeoRSS overlays, as CALayer subclasses, must always be
//  part of the 'overlay' member of the top-most RMMapView (or subclass)
//  so that they show up on top. They can then be ordered amongst themselves.
//
//  Below that, the RMMapView objects can be ordered above the base map 
//  layer in order to display their tiles in different stacking orders.
//  When they get changed, the data overlays above must get moved to the
//  new top-most map view. 
//

#import "RMFoundation.h"

@class DSMapBoxDataOverlayManager;
@class RMMapView;
@class RMMBTilesTileSource;

#define kDSMapBoxSelectedLayerPredicate [NSPredicate predicateWithFormat:@"SELF.isSelected = YES"]

@protocol DSMapBoxDataLayerHandlerDelegate

@optional

- (void)dataLayerHandler:(id)handler didUpdateTileLayers:(NSArray *)activeTileLayers;
- (void)dataLayerHandler:(id)handler didReorderTileLayers:(NSArray *)activeTileLayers;
- (void)dataLayerHandler:(id)handler didUpdateDataLayers:(NSArray *)activeDataLayers;
- (void)dataLayerHandler:(id)handler didReorderDataLayers:(NSArray *)activeDataLayers;

@required

- (void)dataLayerHandler:(id)handler didFailToHandleDataLayerAtURL:(NSURL *)layerURL;

@end

#pragma mark -

typedef enum {
    DSMapBoxLayerSectionData = 0,
    DSMapBoxLayerSectionTile = 1,
} DSMapBoxLayerSection;

@interface DSMapBoxLayerManager : NSObject

@property (nonatomic, readonly, strong) RMMapView *mapView;
@property (nonatomic, readonly, strong) NSArray *tileLayers;
@property (nonatomic, readonly, strong) NSArray *dataLayers;
@property (nonatomic, weak) id <NSObject, DSMapBoxDataLayerHandlerDelegate>delegate;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager overMapView:(RMMapView *)aMapView;
- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)deleteLayersAtIndexPaths:(NSArray *)indexPaths;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath zoomingIfNecessary:(BOOL)zoomNow;
- (void)reloadLayersFromDisk;
- (void)reorderLayers;
- (void)bringActiveTileLayersToTop:(NSArray *)activeTileLayers dataLayers:(NSArray *)activeDataLayers;

@end