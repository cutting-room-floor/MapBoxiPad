//
//  DSMapBoxTileSourceInfiniteZoom.h
//  MapBoxiPad
//
//  Created by Justin Miller on 8/25/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "RMMBTilesSource.h"
#import "RMMapBoxSource.h"

@interface RMMBTilesSource (DSMapBoxTileSourceInfiniteZoom)

- (float)minZoomNative;
- (float)maxZoomNative;

@end

@interface RMMapBoxSource (DSMapBoxTileSourceInfiniteZoom)

- (float)minZoomNative;
- (float)maxZoomNative;

@end