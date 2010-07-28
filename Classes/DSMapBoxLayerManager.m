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

#import "SimpleKML.h"

@interface DSMapBoxLayerManager (DSMapBoxLayerManagerPrivate)

- (void)reloadLayers;

@end

#pragma mark -

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

        tileLayers = [[NSArray array] retain];
        dataLayers = [[NSArray array] retain];
        
        [self reloadLayers];
    }

    return self;
}

- (void)dealloc
{
    [dataOverlayManager release];
    [tileLayers release];
    [dataLayers release];
    
    [super dealloc];
}

#pragma mark -

- (NSUInteger)tileLayerCount
{
    return [self.tileLayers count];
}

- (NSUInteger)dataLayerCount
{
    return [self.dataLayers count];
}

#pragma mark -

- (void)reloadLayers
{
    // tile layers
    //
    NSArray *tileSetPaths = [[DSMapBoxTileSetManager defaultManager] alternateTileSetPaths];
    
    NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
    
    for (NSURL *tileSetPath in tileSetPaths)
    {
        if ( ! [[mutableTileLayers valueForKeyPath:@"path"] containsObject:tileSetPath])
        {
            NSString *name        = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:tileSetPath];
            NSString *description = [[tileSetPath relativePath] lastPathComponent];
            
            [mutableTileLayers addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:tileSetPath,                                    @"path",
                                                                                           name,                                           @"name",
                                                                                           description,                                    @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeTile], @"type",
                                                                                           [NSNumber numberWithBool:NO],                   @"selected",
                                                                                           nil]];
        }
    }
    
    [mutableTileLayers sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];

    [tileLayers release];
    tileLayers = [[NSArray arrayWithArray:mutableTileLayers] retain];

    // data layers
    //
    NSMutableArray *mutableDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];
    
    NSArray *docs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPathString] error:NULL];
    
    for (NSString *path in docs)
    {
        path = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], path];
        
        if ([[path pathExtension] isEqualToString:@"kml"] && ! [[mutableDataLayers valueForKeyPath:@"path"] containsObject:path])
        {
            NSString *description = @""; //[NSString stringWithFormat:@"%i Points", ([[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"<Point>"] count] - 1)];
            
            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                                          @"path", 
                                                                                           [path lastPathComponent],                      @"name",
                                                                                           description,                                   @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeKML], @"type",
                                                                                           [NSNumber numberWithBool:NO],                  @"selected",
                                                                                           nil];
            
            [mutableDataLayers addObject:layer];
        }
        else if ([[path pathExtension] isEqualToString:@"rss"] && ! [[mutableDataLayers valueForKeyPath:@"path"] containsObject:path])
        {
            NSString *description = @""; //[NSString stringWithFormat:@"%i Points", ([[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"georss:point"] count] - 1)];
            
            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                                             @"path", 
                                                                                           [path lastPathComponent],                         @"name",
                                                                                           description,                                      @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeGeoRSS], @"type",
                                                                                           [NSNumber numberWithBool:NO],                     @"selected",
                                                                                           nil];
            
            [mutableDataLayers addObject:layer];
        }
    }
    
    [mutableDataLayers sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
    
    [dataLayers release];
    dataLayers = [[NSArray arrayWithArray:mutableDataLayers] retain];
    
    // TODO: check state in dataOverlayManager.overlays
}

#pragma mark -

- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSLog(@"move %i from %i to %i", fromIndexPath.section, fromIndexPath.row, toIndexPath.row);
}

- (void)archiveLayerAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"archive %i at %i", indexPath.section, indexPath.row);
}

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *layer;
    
    switch (indexPath.section)
    {
        case 0:
            
            return;
            
        case 1:
            
            NSLog(@"toggle tile layer at row %i", indexPath.row);

            layer = [tileLayers objectAtIndex:indexPath.row];

            break;
            
        case 2:
            
            layer = [dataLayers objectAtIndex:indexPath.row];
            
            if ( ! [layer objectForKey:@"source"])
            {
                NSString *source = [NSString stringWithContentsOfFile:[layer objectForKey:@"path"] encoding:NSUTF8StringEncoding error:NULL];
                
                [layer setObject:source forKey:@"source"];
            }
            
            if ([[layer objectForKey:@"selected"] boolValue])
                [dataOverlayManager removeOverlayWithSource:[layer objectForKey:@"source"]];

            else
            {
                if ([[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeKML)
                {
                    SimpleKML *kml = [SimpleKML KMLWithContentsOfFile:[layer objectForKey:@"path"] error:NULL];
                    
                    [dataOverlayManager addOverlayForKML:kml];
                }
                else if ([[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeGeoRSS)
                {
                    [dataOverlayManager addOverlayForGeoRSS:[layer objectForKey:@"source"]];
                }
            }

            break;
    }
    
    [layer setObject:[NSNumber numberWithBool:( ! [[layer objectForKey:@"selected"] boolValue])] forKey:@"selected"];
}

@end