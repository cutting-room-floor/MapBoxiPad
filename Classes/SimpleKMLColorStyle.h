//
//  SimpleKMLColorStyle.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#colorstyle
//

#import "SimpleKMLSubStyle.h"

@interface SimpleKMLColorStyle : SimpleKMLSubStyle
{
    UIColor *color;
}

@property (nonatomic, retain) UIColor *color;

@end