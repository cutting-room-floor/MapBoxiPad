//
//  DSMapBoxTileSetManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxTileSetManager.h"

@implementation DSMapBoxTileSetManager

static DSMapBoxTileSetManager *defaultManager;

+ (DSMapBoxTileSetManager *)defaultManager
{
    @synchronized(@"DSMapBoxTileSetManager")
    {
        if ( ! defaultManager)
            defaultManager = [[self alloc] init];
    }
    
    return defaultManager;
}

- (id)init
{
    self = [super init];
    
    if (self != nil)
    {
        NSArray *bundledTileSets = [[NSBundle mainBundle] pathsForResourcesOfType:@"mbtiles" inDirectory:nil];
        
        NSAssert([bundledTileSets count] > 0, @"No bundled tile sets found in application");
    }
    
    return self;
}

#pragma mark -

- (BOOL)isUsingDefaultTileSet
{
    return YES;
}

- (NSUInteger)tileSetCount
{
    return 0;
}

- (NSArray *)tileSetNames
{
    return [NSArray array];
}

- (BOOL)importTileSetFromURL:(NSURL *)importURL
{
    return NO;
}

- (BOOL)deleteTileSetWithName:(NSString *)tileSetName
{
    return NO;
}

- (NSString *)activeTileSetName
{
    return nil;
}

- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName
{
    return NO;
}

@end