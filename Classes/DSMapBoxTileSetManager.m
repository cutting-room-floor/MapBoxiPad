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
        
        NSString *path = [[bundledTileSets sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
        
        _activeTileSetURL  = [[NSURL fileURLWithPath:path] retain];
        _activeTileSetName = [[[[_activeTileSetURL path] componentsSeparatedByString:@"/"] lastObject] retain];
        
        NSAssert([self activeTileSetName], @"Unable to read default tile set name");
    }
    
    return self;
}

- (void)dealloc
{
    [_activeTileSetURL  release];
    [_activeTileSetName release];
    
    [super dealloc];
}

#pragma mark -

- (BOOL)isUsingDefaultTileSet
{
    return YES;
}

- (NSUInteger)tileSetCount
{
    return 1;
}

- (NSArray *)tileSetNames
{
    return [NSArray arrayWithObject:_activeTileSetName];
}

- (BOOL)importTileSetFromURL:(NSURL *)importURL
{
    return NO;
}

- (BOOL)deleteTileSetWithName:(NSString *)tileSetName
{
    return NO;
}

- (NSURL *)activeTileSetURL
{
    return _activeTileSetURL;
}

- (NSString *)activeTileSetName
{
    NSArray *parts = [[_activeTileSetName stringByReplacingOccurrencesOfString:@".mbtiles" withString:@""] componentsSeparatedByString:@"_"];
    
    NSAssert([parts count] == 3, @"Unable to parse tile set name");
    
    NSString *displayName = [[parts objectAtIndex:0] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    NSString *versionName = [[parts objectAtIndex:2] isEqualToString:@"v1"] ? @"" : [NSString stringWithFormat:@" (%@)", [parts objectAtIndex:2]];
    
    return [NSString stringWithFormat:@"%@%@", displayName, versionName];
}

- (BOOL)makeTileSetWithNameActive:(NSString *)tileSetName
{
    return NO;
}

@end