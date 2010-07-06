//
//  SimpleKMLPolyStyle.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/2/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#polystyle
//

#import "SimpleKMLColorStyle.h"

@interface SimpleKMLPolyStyle : SimpleKMLColorStyle
{
    BOOL fill;
    BOOL outline;
}

@property (nonatomic, assign) BOOL fill;
@property (nonatomic, assign) BOOL outline;

@end