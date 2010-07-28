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

#import "UIApplication_Additions.h"

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
            NSString *name = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:tileSetPath];
            
            [mutableTileLayers addObject:[NSDictionary dictionaryWithObjectsAndKeys:tileSetPath,                  @"path",
                                                                                    name,                         @"name",
                                                                                    [NSNumber numberWithBool:NO], @"selected",
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
    NSMutableArray *entities = [NSMutableArray array];
    
    NSArray *docs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPathString] error:NULL];
    
    for (NSString *path in docs)
    {
        path = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], path];
        
        if ([[path pathExtension] isEqualToString:@"kml"] && ! [[entities valueForKeyPath:@"path"] containsObject:path])
        {
            NSString *description = [NSString stringWithFormat:@"%i Points", ([[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"<Point>"] count] - 1)];
            
            NSMutableDictionary *entity = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                                          @"path", 
                                                                                            [path lastPathComponent],                      @"name",
                                                                                            description,                                   @"description",
                                                                                            [NSNumber numberWithInt:DSMapBoxLayerTypeKML], @"type",
                                                                                            [NSNumber numberWithBool:NO],                  @"selected",
                                                                                            nil];
            
            [entities addObject:entity];
        }
        else if ([[path pathExtension] isEqualToString:@"rss"] && ! [[entities valueForKeyPath:@"path"] containsObject:path])
        {
            NSString *description = [NSString stringWithFormat:@"%i Points", ([[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"georss:point"] count] - 1)];
            
            NSMutableDictionary *entity = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                                             @"path", 
                                                                                            [path lastPathComponent],                         @"name",
                                                                                            description,                                      @"description",
                                                                                            [NSNumber numberWithInt:DSMapBoxLayerTypeGeoRSS], @"type",
                                                                                            [NSNumber numberWithBool:NO],                     @"selected",
                                                                                            nil];
            
            [entities addObject:entity];
        }
    }
    
    [entities sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
    
    return [NSArray arrayWithArray:entities];
    
    // TODO: check state in dataOverlayManager.overlays
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
    NSLog(@"move %i from %i to %i", layerType, fromIndex, toIndex);
}

- (void)archiveLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)index
{
    NSLog(@"archive %i at %i", layerType, index);
}

- (void)toggleLayerOfType:(DSMapBoxLayerType)layerType atIndex:(NSUInteger)index
{
    NSLog(@"toggle %i at %i", layerType, index);
}

@end