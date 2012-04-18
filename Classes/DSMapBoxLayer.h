//
//  DSMapBoxLayer.h
//  MapBoxiPad
//
//  Created by Justin Miller on 4/18/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

typedef enum {
    DSMapBoxLayerTypeTile    = 0,
    DSMapBoxLayerTypeKML     = 1,
    DSMapBoxLayerTypeKMZ     = 2,
    DSMapBoxLayerTypeGeoRSS  = 4,
    DSMapBoxLayerTypeGeoJSON = 8,
} DSMapBoxLayerType;

@interface DSMapBoxLayer : NSObject

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *attribution;
@property (nonatomic, strong) NSNumber *filesize;
@property (nonatomic, strong) NSString *source;
@property (nonatomic, strong) NSArray *overlay;
@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, assign, getter=isDownloadable) BOOL downloadable;
@property (nonatomic, assign) DSMapBoxLayerType type;

@end