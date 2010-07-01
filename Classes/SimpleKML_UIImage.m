//
//  SimpleKML_UIImage.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/1/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKML_UIImage.h"

@implementation UIImage (SimpleKML_UIImage)

- (UIImage *)imageWithWidth:(CGFloat)width height:(CGFloat)height
{
    CGImageRef imageRef = [self CGImage];
    
    CGImageAlphaInfo alphaInfo = kCGImageAlphaPremultipliedLast;
	
	CGContextRef bitmap = CGBitmapContextCreate(NULL, 
                                                round(width), 
                                                round(height), 
                                                CGImageGetBitsPerComponent(imageRef), 
                                                4 * round(width), 
                                                CGImageGetColorSpace(imageRef), 
                                                alphaInfo);
    
	CGContextDrawImage(bitmap, CGRectMake(0, 0, round(width), round(height)), imageRef);
    
	CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    
	UIImage *result = [UIImage imageWithCGImage:newImageRef];
    
	CGContextRelease(bitmap);
	
    CGImageRelease(newImageRef);
    
	return result;
}

- (UIImage *)imageWithAlphaComponent:(CGFloat)alpha
{
    UIGraphicsBeginImageContext(self.size);
    
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height) blendMode:kCGBlendModeNormal alpha:alpha];
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
	
	return result;
}

@end