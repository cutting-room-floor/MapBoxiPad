//
//  DSMapContents.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/21/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "RMMapContents.h"

extern NSString *const DSMapContentsZoomBoundsReached;

#define kLowerZoomBounds       2.5f
#define kUpperLatitudeBounds  85.0f
#define kLowerLatitudeBounds -60.0f
#define kWarningAlpha          0.25f

@class RMMapView;

@interface DSMapContents : RMMapContents
{
    NSArray *layerMapViews;
    RMMapView *mapView;
    BOOL boundsWarningEnabled;
}

@property (nonatomic, retain) NSArray *layerMapViews;

@end