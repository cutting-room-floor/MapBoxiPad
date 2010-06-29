//
//  SimpleKMLIconStyle.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#iconstyle
//

#import "SimpleKMLColorStyle.h"

@interface SimpleKMLIconStyle : SimpleKMLColorStyle
{
    CGFloat scale;
    NSUInteger heading;
    UIImage *icon;
}

@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) NSUInteger heading;
@property (nonatomic, retain) UIImage *icon;

@end