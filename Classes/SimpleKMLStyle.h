//
//  SimpleKMLStyle.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#style
//

#import "SimpleKMLStyleSelector.h"

@class SimpleKMLIconStyle;
@class SimpleKMLLineStyle;
@class SimpleKMLPolyStyle;
@class SimpleKMLBalloonStyle;

@interface SimpleKMLStyle : SimpleKMLStyleSelector
{
    SimpleKMLIconStyle *iconStyle;
    SimpleKMLLineStyle *lineStyle;
    SimpleKMLPolyStyle *polyStyle;
    SimpleKMLBalloonStyle *balloonStyle;
}

@property (nonatomic, retain) SimpleKMLIconStyle *iconStyle;
@property (nonatomic, retain) SimpleKMLLineStyle *lineStyle;
@property (nonatomic, retain) SimpleKMLPolyStyle *polyStyle;
@property (nonatomic, retain) SimpleKMLBalloonStyle *balloonStyle;

@end