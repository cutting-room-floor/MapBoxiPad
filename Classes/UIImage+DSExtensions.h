//
//  UIImage+DSExtensions.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (UIImage_DSExtensions)

+ (UIImage *)resizeImage:(UIImage *)image width:(NSUInteger)width height:(NSUInteger)height;
+ (UIImage *)setImage:(UIImage *)image toAlpha:(CGFloat)alpha;

@end