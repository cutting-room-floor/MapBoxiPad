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
    UIImage *icon;
}

@property (nonatomic, retain) UIImage *icon; // automatically gets scale & heading applied

@end