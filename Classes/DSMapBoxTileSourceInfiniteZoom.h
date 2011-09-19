//
//  DSMapBoxTileSourceInfiniteZoom.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/25/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

@interface DSMapBoxTileSourceInfiniteZoom : NSObject

+ (BOOL)enableInfiniteZoomForClasses:(NSArray *)classes;

@end

@interface RMMBTilesTileSource (DSMapBoxTileSourceInfiniteZoom)

- (float)minZoomNative;
- (float)maxZoomNative;

@end

@interface RMTileStreamSource (DSMapBoxTileSourceInfiniteZoom)

- (float)minZoomNative;
- (float)maxZoomNative;

@end