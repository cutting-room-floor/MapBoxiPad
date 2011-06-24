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
#define kUpperZoomBounds      22.0f
#define kUpperLatitudeBounds  85.0511f
#define kLowerLatitudeBounds -85.0511f
#define kWarningAlpha          0.25f

@class RMMapView;

@interface DSMapContents : RMMapContents
{
    NSArray *layerMapViews;
    RMMapView *mapView;
}

@property (nonatomic, retain) NSArray *layerMapViews;

@end