//
//  UIImage+DSExtensions.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "UIImage+DSExtensions.h"

@implementation UIImage (UIImage_DSExtensions)

+ (UIImage *)resizeImage:(UIImage *)image width:(NSUInteger)width height:(NSUInteger)height
{
    CGImageRef imageRef = [image CGImage];

    CGImageAlphaInfo alphaInfo = kCGImageAlphaPremultipliedLast;
	
	CGContextRef bitmap = CGBitmapContextCreate(NULL, 
                                                width, 
                                                height, 
                                                CGImageGetBitsPerComponent(imageRef), 
                                                4 * width, 
                                                CGImageGetColorSpace(imageRef), 
                                                alphaInfo);
    
	CGContextDrawImage(bitmap, CGRectMake(0, 0, width, height), imageRef);

	CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);

	UIImage *result = [UIImage imageWithCGImage:newImageRef];
    
	CGContextRelease(bitmap);
	
    CGImageRelease(newImageRef);
    
	return result;
}

+ (UIImage *)setImage:(UIImage *)image toAlpha:(CGFloat)alpha
{
    UIGraphicsBeginImageContext(image.size);
    
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
	
	return result;
}

@end