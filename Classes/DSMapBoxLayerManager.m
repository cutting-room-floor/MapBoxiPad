//
//  DSMapBoxLayerManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerManager.h"

#import "DSMapBoxDataOverlayManager.h";

@implementation DSMapBoxLayerManager

@synthesize layers;
@synthesize tileLayers;
@synthesize dataLayers;
@synthesize tileLayerCount;
@synthesize dataLayerCount;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager;
{
    self = [super init];

    if (self != nil)
        dataOverlayManager = [overlayManager retain];

    return self;
}

- (void)dealloc
{
    [dataOverlayManager release];
    [layers release];
    [tileLayers release];
    [dataLayers release];
    
    [super dealloc];
}

#pragma mark -

- (void)moveLayerAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    
}

- (void)archiveLayerAtIndex:(NSUInteger)index
{
    
}

- (void)toggleLayerAtIndex:(NSUInteger)index
{
    
}

@end