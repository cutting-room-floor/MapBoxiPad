//
//  SimpleKMLBalloonStyle.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#balloonstyle
//

#import "SimpleKMLSubStyle.h"

@interface SimpleKMLBalloonStyle : SimpleKMLSubStyle
{
    UIColor *backgroundColor;
    UIColor *textColor;
}

@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *textColor;

@end