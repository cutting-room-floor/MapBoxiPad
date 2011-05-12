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
#import "RMMBTilesTileSource.h"
#import "DSTiledLayerMapView.h"
#import "DSMapContents.h"
#import "DSMapView.h"

#import "UIApplication_Additions.h"

#import "SimpleKML.h"

#import "RMOpenStreetMapSource.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLayerManager (DSMapBoxLayerManagerPrivate)

- (void)reloadLayersFromDisk;
- (void)reorderLayerDisplay;

@end

#pragma mark -

@implementation DSMapBoxLayerManager

@synthesize baseMapView;
@synthesize baseLayers;
@synthesize tileLayers;
@synthesize dataLayers;
@synthesize baseLayerCount;
@synthesize tileLayerCount;
@synthesize dataLayerCount;
@synthesize delegate;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager overBaseMapView:(DSMapView *)mapView;
{
    self = [super init];

    if (self != nil)
    {
        dataOverlayManager = [overlayManager retain];
        baseMapView        = [mapView retain];
        
        baseLayers = [[NSArray array] retain];
        tileLayers = [[NSArray array] retain];
        dataLayers = [[NSArray array] retain];
        
        [self reloadLayersFromDisk];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadLayersFromDisk)
                                                     name:DSMapBoxTileSetChangedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadLayersFromDisk)
                                                     name:DSMapBoxDocumentsChangedNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxTileSetChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxDocumentsChangedNotification object:nil];

    [dataOverlayManager release];
    [baseMapView release];
    [baseLayers release];
    [tileLayers release];
    [dataLayers release];
    
    [super dealloc];
}

#pragma mark -

- (NSUInteger)baseLayerCount
{
    return [self.baseLayers count];
}

- (NSUInteger)tileLayerCount
{
    return [self.tileLayers count];
}

- (NSUInteger)dataLayerCount
{
    return [self.dataLayers count];
}

#pragma mark -

- (void)reloadLayersFromDisk
{
    // base layers
    //
    NSArray *baseSetPaths = [[DSMapBoxTileSetManager defaultManager] alternateTileSetPathsOfType:DSMapBoxTileSetTypeBaselayer];
    
    NSMutableArray *mutableBaseLayers = [NSMutableArray array];
    
    [mutableBaseLayers addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[[DSMapBoxTileSetManager defaultManager] defaultTileSetName], @"name",
                                                                                   [[DSMapBoxTileSetManager defaultManager] descriptionForTileSetAtURL:[[DSMapBoxTileSetManager defaultManager] defaultTileSetURL]], @"description",
                                                                                   [NSNumber numberWithBool:[[DSMapBoxTileSetManager defaultManager] isUsingDefaultTileSet]], @"selected",
                                                                                   nil]];
    
    for (NSURL *baseSetPath in baseSetPaths)
    {
        if ( ! [[mutableBaseLayers valueForKeyPath:@"path"] containsObject:baseSetPath])
        {
            NSString *name        = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:baseSetPath];
            NSString *description = [[DSMapBoxTileSetManager defaultManager] descriptionForTileSetAtURL:baseSetPath];
            
            BOOL isSelected = [[[DSMapBoxTileSetManager defaultManager] activeTileSetName] isEqualToString:name] && 
                              [[mutableBaseLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]] count] == 0;
            
            [mutableBaseLayers addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:baseSetPath,                          @"path",
                                                                                           name,                                 @"name",
                                                                                           (description ? description : @""),    @"description",
                                                                                           [NSNumber numberWithBool:isSelected], @"selected",
                                                                                           nil]];
        }
    }
    
    [mutableBaseLayers sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
    
    [baseLayers release];
    baseLayers = [[NSArray arrayWithArray:mutableBaseLayers] retain];
    
    // tile layers
    //
    NSArray *tileSetPaths = [[DSMapBoxTileSetManager defaultManager] alternateTileSetPathsOfType:DSMapBoxTileSetTypeOverlay];
    
    NSMutableArray *mutableTileLayers  = [NSMutableArray arrayWithArray:self.tileLayers];
    NSMutableArray *tileLayersToRemove = [NSMutableArray array];
    
    // look for layers missing on disk, turning them off
    //
    for (NSDictionary *tileLayer in mutableTileLayers)
    {
        if ( ! [tileSetPaths containsObject:[tileLayer objectForKey:@"path"]])
        {
            if ([[tileLayer objectForKey:@"selected"] boolValue])
                [self toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[mutableTileLayers indexOfObject:tileLayer] inSection:DSMapBoxLayerSectionTile]];
            
            [tileLayersToRemove addObject:tileLayer];
        }
    }

    // remove any missing layers from UI
    while ([tileLayersToRemove count] > 0)
    {
        [mutableTileLayers removeObject:[tileLayersToRemove objectAtIndex:0]];
        [tileLayersToRemove removeObjectAtIndex:0];
    }
    
    // pick up any new tiles on disk
    //
    for (NSURL *tileSetPath in tileSetPaths)
    {
        if ( ! [[mutableTileLayers valueForKeyPath:@"path"] containsObject:tileSetPath])
        {
            NSString *name        = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:tileSetPath];
            NSString *description = [[DSMapBoxTileSetManager defaultManager] descriptionForTileSetAtURL:tileSetPath];
            
            [mutableTileLayers addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:tileSetPath,                       @"path",
                                                                                           name,                              @"name",
                                                                                           (description ? description : @""), @"description",
                                                                                           [NSNumber numberWithBool:NO],      @"selected",
                                                                                           nil]];
        }
    }
    
    [tileLayers release];
    tileLayers = [[NSArray arrayWithArray:mutableTileLayers] retain];

    // data layers
    //
    NSArray *docs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPathString] error:NULL];
    
    NSMutableArray *mutableDataLayers  = [NSMutableArray arrayWithArray:self.dataLayers];
    NSMutableArray *dataLayersToRemove = [NSMutableArray array];
    
    // look for layers missing on disk, turning them off
    //
    for (NSDictionary *dataLayer in mutableDataLayers)
    {
        if ( ! [docs containsObject:[[dataLayer objectForKey:@"path"] lastPathComponent]])
        {
            if ([[dataLayer objectForKey:@"selected"] boolValue])
                [self toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[mutableDataLayers indexOfObject:dataLayer] inSection:DSMapBoxLayerSectionData]];
            
            [dataLayersToRemove addObject:dataLayer];
        }
    }

    // remove any missing layers from UI
    //
    while ([dataLayersToRemove count] > 0)
    {
        [mutableDataLayers removeObject:[dataLayersToRemove objectAtIndex:0]];
        [dataLayersToRemove removeObjectAtIndex:0];
    }
    
    // pick up any new layers on disk
    //
    for (NSString *path in docs)
    {
        path = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], path];
        
        if (([[[path pathExtension] lowercaseString] isEqualToString:@"kml"] || [[[path pathExtension] lowercaseString] isEqualToString:@"kmz"]) && 
             ! [[mutableDataLayers valueForKeyPath:@"path"] containsObject:path])
        {
            NSString *description = [[[path pathExtension] lowercaseString] isEqualToString:@"kml"] ? @"KML File" : @"KMZ Archive";
            
            NSString *name = [path lastPathComponent];
            
            name = [name stringByReplacingOccurrencesOfString:@".kml" 
                                                   withString:@"" 
                                                      options:NSCaseInsensitiveSearch 
                                                        range:NSMakeRange(0, [name length])];

            name = [name stringByReplacingOccurrencesOfString:@".kmz" 
                                                   withString:@""
                                                      options:NSCaseInsensitiveSearch 
                                                        range:NSMakeRange(0, [name length])];

            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                                          @"path", 
                                                                                           name,                                          @"name",
                                                                                           description,                                   @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeKML], @"type",
                                                                                           [NSNumber numberWithBool:NO],                  @"selected",
                                                                                           nil];
            
            [mutableDataLayers addObject:layer];
        }
        else if ([[[path pathExtension] lowercaseString] isEqualToString:@"rss"] && 
                  ! [[mutableDataLayers valueForKeyPath:@"path"] containsObject:path])
        {
            NSString *description = @"GeoRSS Feed";

            NSString *name = [path lastPathComponent];
        
            name = [name stringByReplacingOccurrencesOfString:@".rss" 
                                                   withString:@""
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(0, [name length])];
                        
            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                                             @"path", 
                                                                                           name,                                             @"name",
                                                                                           description,                                      @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeGeoRSS], @"type",
                                                                                           [NSNumber numberWithBool:NO],                     @"selected",
                                                                                           nil];
            
            [mutableDataLayers addObject:layer];
        }
    }
        
    [dataLayers release];
    dataLayers = [[NSArray arrayWithArray:mutableDataLayers] retain];
}

- (void)reorderLayerDisplay
{
    // check tile layers
    //
    NSArray *visibleTileLayers = [self.tileLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]];

    if ([visibleTileLayers count] > 1)
    {
        // track map views in order
        //
        NSMutableArray *orderedMaps = [NSMutableArray array];
        
        // remove all tile layer maps from superview
        //
        [((DSMapContents *)baseMapView.contents).layerMapViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        // iterate visible layers, finding map for each & inserting it above top-most existing map layer
        //
        for (NSUInteger i = 0; i < [visibleTileLayers count]; i++)
        {
            DSTiledLayerMapView *layerMapView = [[((DSMapContents *)baseMapView.contents).layerMapViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tileSetURL = %@", [[visibleTileLayers objectAtIndex:i] objectForKey:@"path"]]] lastObject];
            
            [baseMapView insertLayerMapView:layerMapView];
            
            [orderedMaps addObject:layerMapView];
        }
        
        // find the new top-most map
        //
        DSTiledLayerMapView *topMostMap = [orderedMaps lastObject];

        // pass the data overlay baton to it
        //
        dataOverlayManager.mapView = topMostMap;

        // setup the master map & data manager connections
        //
        topMostMap.masterView = baseMapView;
        topMostMap.delegate   = dataOverlayManager;
        
        // zero out the non-top-most map connections
        //
        [orderedMaps removeLastObject];

        for (DSTiledLayerMapView *orderedMap in orderedMaps)
        {
            orderedMap.masterView = nil;
            orderedMap.delegate   = nil;
        }
    }
    
    // check data layers
    //
    NSArray *visibleDataLayers = [self.dataLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]];
    
    if ([visibleDataLayers count] > 1)
    {
        // find the superlayer of all live paths
        //
        RMLayerCollection *destinationLayer = [baseMapView topMostMapView].contents.overlay;        
        
        // remove all live paths from the superlayer
        //
        for (NSDictionary *overlay in dataOverlayManager.overlays)
            [[overlay objectForKey:@"overlay"] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
        
        // find which overlay matches each data layer in turn & re-add them
        //
        for (NSUInteger i = 0; i < [visibleDataLayers count]; i++)
        {
            NSString *source = [[visibleDataLayers objectAtIndex:i] objectForKey:@"source"];

            for (NSDictionary *overlay in dataOverlayManager.overlays)
            {
                id overlaySource = [overlay objectForKey:@"source"];
                
                if (([overlaySource isKindOfClass:[SimpleKML class]] && [[overlaySource source] isEqualToString:source]) ||
                    ([overlaySource isKindOfClass:[NSString class]]  && [overlaySource isEqualToString:source]))
                {
                    for (NSUInteger j = 0; j < [[overlay objectForKey:@"overlay"] count]; j++)
                        [destinationLayer addSublayer:[[overlay objectForKey:@"overlay"] objectAtIndex:j]];
                    
                    break;
                }
            }
        }
    }
}

#pragma mark -

- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableDictionary *layer;
    
    switch (fromIndexPath.section)
    {
        case DSMapBoxLayerSectionBase: // can't move base layers
            
            return;
            
        case DSMapBoxLayerSectionTile: // tile layers
            
            layer = [self.tileLayers objectAtIndex:fromIndexPath.row];

            NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
            
            [mutableTileLayers removeObject:layer];
            [mutableTileLayers insertObject:layer atIndex:toIndexPath.row];

            [tileLayers release];
            tileLayers = [[NSArray arrayWithArray:mutableTileLayers] retain];
            
            break;
            
        case DSMapBoxLayerSectionData: // data layers
            
            layer = [self.dataLayers objectAtIndex:fromIndexPath.row];
            
            NSMutableArray *mutableDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];
            
            [mutableDataLayers removeObject:layer];
            [mutableDataLayers insertObject:layer atIndex:toIndexPath.row];
            
            [dataLayers release];
            dataLayers = [[NSArray arrayWithArray:mutableDataLayers] retain];
            
            break;
    }
    
    [self reloadLayersFromDisk];
    [self reorderLayerDisplay];
}

- (void)archiveLayerAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: change this from a deletion into a library archival
    
    NSMutableDictionary *layer;

    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionBase: // can't archive base layers (for now)
            
            layer = [self.baseLayers objectAtIndex:indexPath.row];
            
            if ([[layer objectForKey:@"selected"] boolValue])
                [self toggleLayerAtIndexPath:indexPath];
            
            [[NSFileManager defaultManager] removeItemAtPath:[[layer objectForKey:@"path"] relativePath] error:NULL];
            
            NSMutableArray *mutableBaseLayers = [NSMutableArray arrayWithArray:self.baseLayers];
            
            [mutableBaseLayers removeObject:layer];
            
            [baseLayers release];
            baseLayers = [[NSArray arrayWithArray:mutableBaseLayers] retain];
            
            break;

        case DSMapBoxLayerSectionTile: // tile layers
            
            layer = [self.tileLayers objectAtIndex:indexPath.row];
            
            if ([[layer objectForKey:@"selected"] boolValue])
                [self toggleLayerAtIndexPath:indexPath];

            [[NSFileManager defaultManager] removeItemAtPath:[[layer objectForKey:@"path"] relativePath] error:NULL];
            
            NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
            
            [mutableTileLayers removeObject:layer];
            
            [tileLayers release];
            tileLayers = [[NSArray arrayWithArray:mutableTileLayers] retain];
            
            break;
            
        case DSMapBoxLayerSectionData: // data layers
            
            layer = [self.dataLayers objectAtIndex:indexPath.row];

            if ([[layer objectForKey:@"selected"] boolValue])
                [self toggleLayerAtIndexPath:indexPath];
            
            [[NSFileManager defaultManager] removeItemAtPath:[layer objectForKey:@"path"] error:NULL];
            
            NSMutableArray *mutableDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];
            
            [mutableDataLayers removeObject:layer];
            
            [dataLayers release];
            dataLayers = [[NSArray arrayWithArray:mutableDataLayers] retain];
            
            break;
    }
}

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleLayerAtIndexPath:indexPath zoomingIfNecessary:NO];
}

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath zoomingIfNecessary:(BOOL)zoomNow
{
    NSMutableDictionary *layer;
    
    NSMutableDictionary *newLayer;
    NSMutableDictionary *oldLayer;
    
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionBase:
            
            newLayer = [self.baseLayers objectAtIndex:indexPath.row];

            if ([[newLayer objectForKey:@"selected"] boolValue]) // already active
                return;

            oldLayer = [[self.baseLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]] lastObject];
            
            [oldLayer setObject:[NSNumber numberWithBool:NO]  forKey:@"selected"];
            [newLayer setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
            
            [[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:[newLayer objectForKey:@"name"] animated:YES];
            
            return;
            
        case DSMapBoxLayerSectionTile: // tile layers
            
            layer = [self.tileLayers objectAtIndex:indexPath.row];
            
            if ([[layer objectForKey:@"selected"] boolValue])
            {
                for (UIView *baseMapPeer in baseMapView.superview.subviews)
                {
                    if ([baseMapPeer isKindOfClass:[DSTiledLayerMapView class]])
                    {
                        if ([((DSTiledLayerMapView *)baseMapPeer).tileSetURL isEqual:[layer objectForKey:@"path"]])
                        {
                            // disassociate with master map
                            //
                            NSMutableArray *layerMapViews = [NSMutableArray arrayWithArray:((DSMapContents *)baseMapView.contents).layerMapViews];
                            [layerMapViews removeObject:baseMapPeer];
                            ((DSMapContents *)baseMapView.contents).layerMapViews = [NSArray arrayWithArray:layerMapViews];

                            // remove from view hierarchy
                            //
                            [baseMapPeer removeFromSuperview];
                            
                            // transfer data overlay status
                            //
                            dataOverlayManager.mapView = ([layerMapViews count] ? [layerMapViews lastObject] : baseMapView);
                        }
                    }
                }
            }
            else
            {
                // create tile source
                //
                NSURL *tileSetURL = [layer objectForKey:@"path"];
                
                id <RMTileSource>source;
                
                if ([tileSetURL isEqual:kDSOpenStreetMapURL])
                    source = [[[RMOpenStreetMapSource alloc] init] autorelease];
                
                else
                    source = [[[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL] autorelease];
                
                // create the overlay map view
                //
                DSTiledLayerMapView *layerMapView = [[[DSTiledLayerMapView alloc] initWithFrame:baseMapView.frame] autorelease];
                
                layerMapView.tileSetURL = tileSetURL;
                
                // insert above top-most existing map view
                //
                [baseMapView insertLayerMapView:layerMapView];
                
                // copy main map view attributes
                //
                layerMapView.autoresizingMask = baseMapView.autoresizingMask;
                layerMapView.enableRotate     = baseMapView.enableRotate;
                layerMapView.deceleration     = baseMapView.deceleration;

                [[[DSMapContents alloc] initWithView:layerMapView 
                                          tilesource:source
                                        centerLatLon:baseMapView.contents.mapCenter
                                           zoomLevel:baseMapView.contents.zoom
                                        maxZoomLevel:[source maxZoom]
                                        minZoomLevel:[source minZoom]
                                     backgroundImage:nil] autorelease];
                
                // get peer layer map views
                //
                NSMutableArray *layerMapViews = [NSMutableArray arrayWithArray:((DSMapContents *)baseMapView.contents).layerMapViews];

                // disassociate peers with master
                //
                for (DSTiledLayerMapView *mapView in layerMapViews)
                {
                    mapView.masterView = nil;
                    mapView.delegate   = nil;
                }
                
                // associate new with master
                //
                [layerMapViews addObject:layerMapView];
                ((DSMapContents *)baseMapView.contents).layerMapViews = [NSArray arrayWithArray:layerMapViews];
                layerMapView.masterView = baseMapView;

                // associate new with data overlay manager
                //
                layerMapView.delegate = dataOverlayManager;
                dataOverlayManager.mapView = layerMapView;
            }

            break;
            
        case DSMapBoxLayerSectionData: // data layers
            
            layer = [self.dataLayers objectAtIndex:indexPath.row];
            
            if ([[layer objectForKey:@"selected"] boolValue])
            {
                [dataOverlayManager removeOverlayWithSource:[layer objectForKey:@"source"]];
            }
            else
            {
                if ([[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeKML || [[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeKMZ)
                {
                    SimpleKML *kml = [SimpleKML KMLWithContentsOfFile:[layer objectForKey:@"path"] error:NULL];
                    
                    if ( ! kml)
                    {
                        if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didFailToHandleDataLayerAtPath:)])
                            [self.delegate dataLayerHandler:self didFailToHandleDataLayerAtPath:[layer objectForKey:@"path"]];
                        
                        return;
                    }
                    
                    [dataOverlayManager addOverlayForKML:kml];
                    
                    if ( ! [layer objectForKey:@"source"])
                        [layer setObject:[kml source] forKey:@"source"];
                }
                else if ([[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeGeoRSS)
                {
                    if ( ! [layer objectForKey:@"source"])
                        [layer setObject:[NSString stringWithContentsOfFile:[layer objectForKey:@"path"] encoding:NSUTF8StringEncoding error:NULL]
                                  forKey:@"source"];
                    
                    [dataOverlayManager addOverlayForGeoRSS:[layer objectForKey:@"source"]];
                }
            }

            break;
    }
    
    [layer setObject:[NSNumber numberWithBool:( ! [[layer objectForKey:@"selected"] boolValue])] forKey:@"selected"];
    
    if ([[layer objectForKey:@"selected"] boolValue])
        [self reorderLayerDisplay];
}

@end