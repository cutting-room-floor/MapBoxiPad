//
//  SimpleKML_UIImage.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/1/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (SimpleKML_UIImage)

- (UIImage *)imageWithWidth:(CGFloat)width height:(CGFloat)height;
- (UIImage *)imageWithAlphaComponent:(CGFloat)alpha;

@end