//
//  DSMapContents.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/21/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "RMMapContents.h"

extern NSString *const DSMapContentsZoomBoundsReached;

@interface DSMapContents : RMMapContents
{
}

@property (nonatomic, retain) NSArray *layerMapViews;

@end