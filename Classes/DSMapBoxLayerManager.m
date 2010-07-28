//
//  DSMapBoxLayerManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerManager.h"

#import "DSMapBoxDataOverlayManager.h";
#import "DSMapBoxTileSetManager.h"

@implementation DSMapBoxLayerManager

@synthesize tileLayers;
@synthesize dataLayers;
@synthesize tileLayerCount;
@synthesize dataLayerCount;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager;
{
    self = [super init];

    if (self != nil)
    {
        dataOverlayManager = [overlayManager retain];

        NSArray *tileSetPaths = [[DSMapBoxTileSetManager defaultManager] alternateTileSetPaths];
        
        NSMutableArray *mutableTileLayers = [NSMutableArray array];
        
        for (NSURL *tileSetPath in tileSetPaths)
        {
            [mutableTileLayers addObject:[NSDictionary dictionaryWithObjectsAndKeys:tileSetPath,                  @"path",
                                                                                    [NSNumber numberWithBool:NO], @"visible",
                                                                                    nil]];
        }
        
        tileLayers = [[NSArray arrayWithArray:mutableTileLayers] retain];
    }

    return self;
}

- (void)dealloc
{
    [dataOverlayManager release];
    [tileLayers release];
    
    [super dealloc];
}

#pragma mark -

- (NSArray *)dataLayers
{
    return dataOverlayManager.overlays;
}

- (NSUInteger)tileLayerCount
{
    return [tileLayers count];
}

- (NSUInteger)dataLayerCount
{
    return [self.dataLayers count];
}

#pragma mark -

- (void)moveLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    
}

- (void)archiveLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)index
{
    
}

- (void)toggleLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)index
{
    
}

@end