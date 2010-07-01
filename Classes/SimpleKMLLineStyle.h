//
//  SimpleKMLLineStyle.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#linestyle
//

#import "SimpleKMLColorStyle.h"

@interface SimpleKMLLineStyle : SimpleKMLColorStyle
{
    CGFloat width;
}

@property (nonatomic, assign) CGFloat width;

@end