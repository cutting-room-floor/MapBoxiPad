//
//  DSMapBoxLayerManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerManager.h"

#import "DSMapBoxOverlayManager.h";

@implementation DSMapBoxLayerManager

@synthesize layers;
@synthesize tileLayers;
@synthesize dataLayers;
@synthesize tileLayerCount;
@synthesize dataLayerCount;

- (void)dealloc
{
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