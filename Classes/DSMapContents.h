//
//  DSMapContents.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/21/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "RMMapContents.h"

extern NSString *const DSMapContentsZoomBoundsReached;

@interface DSMapContents : RMMapContents

@property (nonatomic, strong) NSArray *layerMapViews;

- (void)postZoom;

@end