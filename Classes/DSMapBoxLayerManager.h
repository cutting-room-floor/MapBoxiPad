//
//  DSMapBoxLayerManager.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    DSMapBoxLayerTypeTile,
    DSMapBoxLayerTypeKML,
    DSMapBoxLayerTypeGeoRSS,
} DSMapBoxLayerType;

@interface DSMapBoxLayerManager : NSObject
{
    NSArray *layers;
    NSArray *tileLayers;
    NSArray *dataLayers;
    NSUInteger *tileLayerCount;
    NSUInteger *dataLayerCount;
}

@property (nonatomic, readonly, retain) NSArray *layers;
@property (nonatomic, readonly, retain) NSArray *tileLayers;
@property (nonatomic, readonly, retain) NSArray *dataLayers;
@property (nonatomic, readonly, assign) NSUInteger *tileLayerCount;
@property (nonatomic, readonly, assign) NSUInteger *dataLayerCount;

- (void)moveLayerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
- (void)archiveLayerAtIndex:(NSUInteger)index;
- (void)toggleLayerAtIndex:(NSUInteger)index;
//- (void)setAlpha:(CGFloat)alpha forLayerAtIndex:(NSUInteger)index;

@end