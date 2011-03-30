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

static NSString *const DSMapBoxDocumentsChangedNotification = @"DSMapBoxDocumentsChangedNotification";

@class DSMapBoxDataOverlayManager;
@class DSMapView;
@class RMMBTilesTileSource;

@protocol DSDataLayerHandlerDelegate

- (void)dataLayerHandler:(id)handler didFailToHandleDataLayerAtPath:(NSString *)path;

@end

#pragma mark -

typedef enum {
    DSMapBoxLayerTypeTile   = 0,
    DSMapBoxLayerTypeKML    = 1,
    DSMapBoxLayerTypeKMZ    = 2,
    DSMapBoxLayerTypeGeoRSS = 4,
} DSMapBoxLayerType;

typedef enum {
    DSMapBoxLayerSectionBase = 0,
    DSMapBoxLayerSectionTile = 1,
    DSMapBoxLayerSectionData = 2,
} DSMapBoxLayerSection;

@interface DSMapBoxLayerManager : NSObject
{
    DSMapBoxDataOverlayManager *dataOverlayManager;
    DSMapView *baseMapView;
    NSArray *baseLayers;
    NSArray *tileLayers;
    NSArray *dataLayers;
    id <NSObject, DSDataLayerHandlerDelegate>delegate;
}

@property (nonatomic, retain) DSMapView *baseMapView;
@property (nonatomic, readonly, retain) NSArray *baseLayers;
@property (nonatomic, readonly, retain) NSArray *tileLayers;
@property (nonatomic, readonly, retain) NSArray *dataLayers;
@property (nonatomic, readonly, assign) NSUInteger baseLayerCount;
@property (nonatomic, readonly, assign) NSUInteger tileLayerCount;
@property (nonatomic, readonly, assign) NSUInteger dataLayerCount;
@property (nonatomic, assign) id <NSObject, DSDataLayerHandlerDelegate>delegate;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager overBaseMapView:(DSMapView *)mapView;
- (float)minimumPossibleZoomLevel;
- (float)maximumPossibleZoomLevel;
- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)archiveLayerAtIndexPath:(NSIndexPath *)indexPath;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath zoomingIfNecessary:(BOOL)zoomNow;

@end