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

static NSString *const DSMapBoxDocumentsChangedNotification = @"DSMapBoxDocumentsChangedNotification";

@class DSMapBoxDataOverlayManager;
@class DSMapView;
@class RMMBTilesTileSource;

@protocol DSMapBoxDataLayerHandlerDelegate

- (void)dataLayerHandler:(id)handler didUpdateTileLayers:(NSArray *)activeTileLayers;
- (void)dataLayerHandler:(id)handler didUpdateDataLayers:(NSArray *)activeDataLayers;
- (void)dataLayerHandler:(id)handler didFailToHandleDataLayerAtURL:(NSURL *)layerURL;

@end

#pragma mark -

typedef enum {
    DSMapBoxLayerTypeTile    = 0,
    DSMapBoxLayerTypeKML     = 1,
    DSMapBoxLayerTypeKMZ     = 2,
    DSMapBoxLayerTypeGeoRSS  = 4,
    DSMapBoxLayerTypeGeoJSON = 8,
} DSMapBoxLayerType;

typedef enum {
    DSMapBoxLayerSectionData = 0,
    DSMapBoxLayerSectionTile = 1,
} DSMapBoxLayerSection;

@interface DSMapBoxLayerManager : NSObject
{
}

@property (nonatomic, readonly, retain) DSMapView *baseMapView;
@property (nonatomic, readonly, retain) NSArray *tileLayers;
@property (nonatomic, readonly, retain) NSArray *dataLayers;
@property (nonatomic, assign) id <NSObject, DSMapBoxDataLayerHandlerDelegate>delegate;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager overBaseMapView:(DSMapView *)mapView;
- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)deleteLayerAtIndexPath:(NSIndexPath *)indexPath;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath zoomingIfNecessary:(BOOL)zoomNow;
- (void)reorderLayerDisplay;

@end