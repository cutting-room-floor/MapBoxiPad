//
//  DSMapBoxTileSetManager.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxTileSetManager.h"

@interface DSMapBoxTileSetManager (DSMapBoxTileSetManagerPrivate)

- (NSString *)documentsFolderPathString;
- (NSArray *)alternateTileSetPaths;
- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL;

@end

#pragma mark -

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
        _defaultTileSetURL = [_activeTileSetURL retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_activeTileSetURL  release];
    [_defaultTileSetURL release];
    
    [super dealloc];
}

#pragma mark -

- (NSString *)documentsFolderPathString
{
    NSArray *userPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    return [userPaths objectAtIndex:0];
}

- (NSArray *)alternateTileSetPaths
{
    NSArray *docsContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self documentsFolderPathString] error:NULL];
    
    NSArray *alternateFileNames = [docsContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF ENDSWITH '.mbtiles'"]];

    NSMutableArray *results = [NSMutableArray array];
    
    for (NSString *fileName in alternateFileNames)
        [results addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", [self documentsFolderPathString], fileName]]];
    
    return [NSArray arrayWithArray:results];
}

- (NSString *)displayNameForTileSetAtURL:(NSURL *)tileSetURL
{
    NSString *base = [[[tileSetURL relativePath] componentsSeparatedByString:@"/"] lastObject];
    
    NSArray *parts = [[base stringByReplacingOccurrencesOfString:@".mbtiles" withString:@""] componentsSeparatedByString:@"_"];
    
    NSAssert([parts count] == 3, @"Unable to parse tile set name");
    
    NSString *displayName = [[parts objectAtIndex:0] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    NSString *versionName = [[parts objectAtIndex:2] isEqualToString:@"v1"] ? @"" : [NSString stringWithFormat:@" (%@)", [parts objectAtIndex:2]];
    
    return [NSString stringWithFormat:@"%@%@", displayName, versionName];
}

#pragma mark -

- (BOOL)isUsingDefaultTileSet
{
    return [_activeTileSetURL isEqual:_defaultTileSetURL];
}

- (NSString *)defaultTileSetName
{
    return [self displayNameForTileSetAtURL:_defaultTileSetURL];
}

- (NSUInteger)tileSetCount
{
    return [[self alternateTileSetPaths] count] + 1;
}

- (NSArray *)tileSetNames
{
    NSMutableArray *alternateDisplayNames = [NSMutableArray array];
    
    for (NSURL *alternatePath in [self alternateTileSetPaths])
        [alternateDisplayNames addObject:[self displayNameForTileSetAtURL:alternatePath]];
    
    [alternateDisplayNames sortUsingSelector:@selector(compare:)];

    [alternateDisplayNames insertObject:[self defaultTileSetName] atIndex:0];
    
    return [NSArray arrayWithArray:alternateDisplayNames];
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
    return [self displayNameForTileSetAtURL:_activeTileSetURL];
}

- (NSArray *)activeDownloads
{
    return [NSArray arrayWithObject:@"test download goes here"];
}

- (void)makeTileSetWithNameActive:(NSString *)tileSetName
{
    NSLog(@"activating %@", tileSetName);
}

@end