//
//  DSMapBoxCoreAnimationRenderer.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 9/8/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxCoreAnimationRenderer.h"
#import "RMTile.h"
#import "RMTileImage.h"

@interface RMCoreAnimationRenderer (DSMapBoxCoreAnimationRendererExtensions)

- (void)tileAdded:(RMTile)tile WithImage:(RMTileImage *)image;

@end

#pragma mark -

@implementation DSMapBoxCoreAnimationRenderer

- (void)tileAdded:(RMTile)tile WithImage:(RMTileImage *)image
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.1;
    [layer addAnimation:animation forKey:@"sublayers"];

    [super tileAdded:tile WithImage:image];
}

@end