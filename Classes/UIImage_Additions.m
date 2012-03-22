//
//  UIImage_Additions.m
//  MapBoxiPad
//
//  Created by Justin Miller on 3/20/12.
//  Copyright (c) 2012 MapBox / Development Seed. All rights reserved.
//

#import "UIImage_Additions.h"

@implementation UIImage (UIImage_Additions)

- (UIImage *)imageWithTransparentBorderOfWidth:(NSUInteger)borderWidth
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.size.width + borderWidth * 2, self.size.height + borderWidth * 2), NO, 0);
    
    [self drawAtPoint:CGPointMake(borderWidth, borderWidth)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end