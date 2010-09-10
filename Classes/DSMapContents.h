//
//  DSMapContents.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/21/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "RMMapContents.h"

@interface DSMapContents : RMMapContents
{
    NSArray *layerMapViews;
}

@property (nonatomic, retain) NSArray *layerMapViews;

- (BOOL)canMoveBy:(CGSize)delta;
- (BOOL)canZoomTo:(CGFloat)targetZoom;
- (void)postZoom;

@end