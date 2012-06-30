//
//  DSMapBoxLayerManager.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerManager.h"

#import "DSMapBoxLayer.h"
#import "DSMapBoxDataOverlayManager.h"
#import "DSMapBoxTileSetManager.h"

#import "SimpleKML.h"

#import "RMMapView.h"
#import "RMOpenStreetMapSource.h"
#import "RMMapQuestOSMSource.h"
#import "RMMBTilesSource.h"
#import "RMMapBoxSource.h"
#import "RMAnnotation.h"
#import "RMMapLayer.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLayerManager ()

@property (nonatomic, strong) DSMapBoxDataOverlayManager *dataOverlayManager;
@property (nonatomic, strong) RMMapView *mapView;
@property (nonatomic, strong) NSArray *tileLayers;
@property (nonatomic, strong) NSArray *dataLayers;

- (void)updateBaseHiddenState;

@end

#pragma mark -

@implementation DSMapBoxLayerManager

@synthesize dataOverlayManager;
@synthesize mapView;
@synthesize tileLayers;
@synthesize dataLayers;
@synthesize delegate;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager overMapView:(RMMapView *)aMapView;
{
    self = [super init];

    if (self != nil)
    {
        dataOverlayManager = overlayManager;
        mapView            = aMapView;
        
        tileLayers = [NSArray array];
        dataLayers = [NSArray array];
        
        [self reloadLayersFromDisk];
        
        if ([[tileLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"mbtiles"]) // bundled set doesn't have a URL
            [TestFlight passCheckpoint:@"has MBTiles layer"];
        
        if ([[tileLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"plist"])
            [TestFlight passCheckpoint:@"has TileStream layer"];
            
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"kml"])
            [TestFlight passCheckpoint:@"has KML layer (.kml)"];
        
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"kmz"])
            [TestFlight passCheckpoint:@"has KML layer (.kmz)"];
        
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"rss"])            
            [TestFlight passCheckpoint:@"has GeoRSS layer (.rss)"];
            
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"xml"])
            [TestFlight passCheckpoint:@"has GeoRSS layer (.xml)"];
        
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"json"])
            [TestFlight passCheckpoint:@"has GeoJSON layer (.json)"];
            
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"geojson"])
            [TestFlight passCheckpoint:@"has GeoJSON layer (.geojson)"];
        
        [TestFlight addCustomEnvironmentInformation:[NSString stringWithFormat:@"%i", [tileLayers count]] forKey:@"Tile Layer Count"];
        [TestFlight addCustomEnvironmentInformation:[NSString stringWithFormat:@"%i", [dataLayers count]] forKey:@"Data Layer Count"];
    }

    return self;
}

#pragma mark -

- (void)reloadLayersFromDisk
{
    // tile layers
    //
    NSArray *tileSetURLs = [[DSMapBoxTileSetManager defaultManager] tileSetURLs];
    
    NSMutableArray *mutableTileLayers  = [NSMutableArray arrayWithArray:self.tileLayers];
    NSMutableArray *tileLayersToRemove = [NSMutableArray array];
    
    // look for tile layers missing on disk, turning them off
    //
    for (DSMapBoxLayer *tileLayer in mutableTileLayers)
    {
        if ( ! [tileSetURLs containsObject:tileLayer.URL])
        {
            if (tileLayer.isSelected)
                [self toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[mutableTileLayers indexOfObject:tileLayer] inSection:DSMapBoxLayerSectionTile]];
            
            [tileLayersToRemove addObject:tileLayer];
        }
    }

    // remove any missing tile layers from UI
    //
    while ([tileLayersToRemove count] > 0)
    {
        [mutableTileLayers removeObject:[tileLayersToRemove objectAtIndex:0]];
        [tileLayersToRemove removeObjectAtIndex:0];
    }
    
    // pick up any new tile layers on disk
    //
    for (NSURL *tileSetURL in tileSetURLs)
    {
        if ( ! [[mutableTileLayers valueForKeyPath:@"URL"] containsObject:tileSetURL])
        {
            NSString *name        = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:tileSetURL];
            NSString *description = [[DSMapBoxTileSetManager defaultManager] descriptionForTileSetAtURL:tileSetURL];
            NSString *attribution = [[DSMapBoxTileSetManager defaultManager] attributionForTileSetAtURL:tileSetURL];
            
            // determine if downloadable as MBTiles
            //
            BOOL downloadable = NO;
            unsigned long long filesize = 0;
            
            if ([tileSetURL isTileStreamURL])
            {
                NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:tileSetURL];
                
                if ([[info objectForKey:@"download"] length] && [NSURL URLWithString:[info objectForKey:@"download"]])
                {
                    if ([[info objectForKey:@"filesize"] isKindOfClass:[NSNumber class]])
                    {
                        filesize = [[info objectForKey:@"filesize"] longLongValue];

                        downloadable = YES;

                        [TestFlight passCheckpoint:@"has downloadable TileStream layer"];
                    }
                }
            }
            
            DSMapBoxLayer *layer = [[DSMapBoxLayer alloc] init];
            
            layer.URL          = tileSetURL;
            layer.name         = name;
            layer.description  = (description ? description : @"");
            layer.selected     = NO;
            layer.attribution  = attribution;
            layer.downloadable = downloadable;
            layer.filesize     = [NSNumber numberWithLongLong:filesize];
            
            [mutableTileLayers addObject:layer];
        }
    }
    
    // reverse sort the first time we populate to match stacking order
    //
    if ([self.tileLayers count])
        self.tileLayers = [NSArray arrayWithArray:mutableTileLayers];
    
    else
        self.tileLayers = [[[NSArray arrayWithArray:mutableTileLayers] reverseObjectEnumerator] allObjects];

    // data layers
    //
    NSArray *docs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPath] error:NULL];
    
    NSMutableArray *mutableDataLayers  = [NSMutableArray arrayWithArray:self.dataLayers];
    NSMutableArray *dataLayersToRemove = [NSMutableArray array];
    
    // look for data layers missing on disk, turning them off
    //
    for (DSMapBoxLayer *dataLayer in mutableDataLayers)
    {
        if ( ! [docs containsObject:[dataLayer.URL lastPathComponent]])
        {
            if (dataLayer.isSelected)
                [self toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[mutableDataLayers indexOfObject:dataLayer] inSection:DSMapBoxLayerSectionData]];
            
            [dataLayersToRemove addObject:dataLayer];
        }
    }

    // remove any missing data layers from UI
    //
    while ([dataLayersToRemove count] > 0)
    {
        [mutableDataLayers removeObject:[dataLayersToRemove objectAtIndex:0]];
        [dataLayersToRemove removeObjectAtIndex:0];
    }
    
    // pick up any new data layers on disk
    //
    for (__strong NSString *path in docs)
    {
        path = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPath], path];
        
        if (([[[path pathExtension] lowercaseString] isEqualToString:@"kml"] || [[[path pathExtension] lowercaseString] isEqualToString:@"kmz"]) && 
             ! [[mutableDataLayers valueForKeyPath:@"URL"] containsObject:[NSURL fileURLWithPath:path]])
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

            DSMapBoxLayer *layer = [[DSMapBoxLayer alloc] init];
            
            layer.URL         = [NSURL fileURLWithPath:path];
            layer.name        = name;
            layer.description = description;
            layer.type        = DSMapBoxLayerTypeKML;
            layer.selected    = NO;
            
            [mutableDataLayers addObject:layer];
        }
        else if ([[[path pathExtension] lowercaseString] isEqualToString:@"rss"] && 
                  ! [[mutableDataLayers valueForKeyPath:@"URL"] containsObject:[NSURL fileURLWithPath:path]])
        {
            NSString *description = @"GeoRSS";

            NSString *name = [path lastPathComponent];
        
            name = [name stringByReplacingOccurrencesOfString:@".rss" 
                                                   withString:@""
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(0, [name length])];

            DSMapBoxLayer *layer = [[DSMapBoxLayer alloc] init];
            
            layer.URL         = [NSURL fileURLWithPath:path];
            layer.name        = name;
            layer.description = description;
            layer.type        = DSMapBoxLayerTypeGeoRSS;
            layer.selected    = NO;
            
            [mutableDataLayers addObject:layer];
        }
        else if (([[[path pathExtension] lowercaseString] isEqualToString:@"geojson"] || [[[path pathExtension] lowercaseString] isEqualToString:@"json"]) && 
                 ! [[mutableDataLayers valueForKeyPath:@"URL"] containsObject:[NSURL fileURLWithPath:path]])
        {
            NSString *description = @"GeoJSON";
            
            NSString *name = [path lastPathComponent];
            
            name = [name stringByReplacingOccurrencesOfString:@".geojson" 
                                                   withString:@""
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(0, [name length])];

            name = [name stringByReplacingOccurrencesOfString:@".json" 
                                                   withString:@""
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(0, [name length])];

            DSMapBoxLayer *layer = [[DSMapBoxLayer alloc] init];
            
            layer.URL         = [NSURL fileURLWithPath:path];
            layer.name        = name;
            layer.description = description;
            layer.type        = DSMapBoxLayerTypeGeoJSON;
            layer.selected    = NO;
            
            [mutableDataLayers addObject:layer];
        }
    }
    
    // reverse sort the first time we populate to match stacking order
    //
    if ([self.dataLayers count])
        self.dataLayers = [NSArray arrayWithArray:mutableDataLayers];
    
    else
        self.dataLayers = [[[NSArray arrayWithArray:mutableDataLayers] reverseObjectEnumerator] allObjects];
}

- (void)updateLayers
{
    // notify delegate of tile layer toggles to update attributions
    //
    if (/*indexPath.section == DSMapBoxLayerSectionTile &&*/ [self.delegate respondsToSelector:@selector(dataLayerHandler:didUpdateTileLayers:)])
        [self.delegate dataLayerHandler:self didUpdateTileLayers:[self.tileLayers filteredArrayUsingPredicate:kDSMapBoxSelectedLayerPredicate]];
    
    // notify delegate for clustering button to toggle visibility
    //
    if (/*indexPath.section == DSMapBoxLayerSectionData &&*/ [self.delegate respondsToSelector:@selector(dataLayerHandler:didUpdateDataLayers:)])
        [self.delegate dataLayerHandler:self didUpdateDataLayers:[self.dataLayers filteredArrayUsingPredicate:kDSMapBoxSelectedLayerPredicate]];
    
}

- (void)reorderLayersDisplay
{
    // tile layers - just notify
    //
    if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didReorderTileLayers:)])
        [self.delegate dataLayerHandler:self didReorderTileLayers:[self.tileLayers filteredArrayUsingPredicate:kDSMapBoxSelectedLayerPredicate]];

    // data layers
    //
    NSArray *annotationsWithVisibleLayers = [self.mapView.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@ AND SELF.layer != %@", [NSNull null], [NSNull null]]];
    
    for (RMAnnotation *annotation in annotationsWithVisibleLayers)
        annotation.layer.zPosition = 0;
    
    int i = 0;
    
    for (DSMapBoxLayer *dataLayer in [[[self.dataLayers filteredArrayUsingPredicate:kDSMapBoxSelectedLayerPredicate] reverseObjectEnumerator] allObjects])
        for (RMAnnotation *annotation in [dataLayer.annotations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.layer != %@", [NSNull null]]])
                annotation.layer.zPosition = i++;
    
    if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didReorderDataLayers:)])
        [self.delegate dataLayerHandler:self didReorderDataLayers:[self.dataLayers filteredArrayUsingPredicate:kDSMapBoxSelectedLayerPredicate]];
}

- (void)bringActiveTileLayersToTop:(NSArray *)activeTileLayers dataLayers:(NSArray *)activeDataLayers
{
    // Move the passed layers to the top of their respective UIs. The reasoning is that the layers
    // are normally sorted according to the tile manager sort order. When restoring state, we want to
    // move all of the now-active layers to the top of the array & the UI so that they stack properly 
    // in relation to each other and are easily accessible. 
    //
    if ([activeTileLayers count])
    {
        NSMutableArray *newTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
        
        for (int i = 0; i < [activeTileLayers count]; i++)
        {
            NSDictionary *tileLayer = [[[activeTileLayers reverseObjectEnumerator] allObjects] objectAtIndex:i];
            
            [newTileLayers removeObject:tileLayer];
            [newTileLayers insertObject:tileLayer atIndex:0];
        }
        
        self.tileLayers = newTileLayers;
    }
    
    if ([activeDataLayers count])
    {
        NSMutableArray *newDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];

        for (int j = 0; j < [activeDataLayers count]; j++)
        {
            NSDictionary *dataLayer = [[[activeDataLayers reverseObjectEnumerator] allObjects] objectAtIndex:j];
            
            [newDataLayers removeObject:dataLayer];
            [newDataLayers insertObject:dataLayer atIndex:0];
        }
        
        self.dataLayers = newDataLayers;
    }
    
    [self reorderLayersDisplay];
}

- (void)updateBaseHiddenState
{
    // add in default base map if we don't have full-world coverage somewhere else
    //
    for (int j = 1; j < [self.mapView.tileSources count]; j++) // skip first/base source in tests
    {
        id enabledSource = [self.mapView.tileSources objectAtIndex:j];
        
        if ( [enabledSource isKindOfClass:[RMOpenStreetMapSource class]]                                                         || 
            [enabledSource isKindOfClass:[RMMapQuestOSMSource   class]]                                                         || 
            ([enabledSource isKindOfClass:[RMMBTilesSource       class]] && [(RMMBTilesSource *)enabledSource coversFullWorld])  ||
            ([enabledSource isKindOfClass:[RMMapBoxSource        class]] && [(RMMapBoxSource  *)enabledSource coversFullWorld]))
        {
            [self.mapView setHidden:YES forTileSourceAtIndex:0];
            
            return;
        }
    }
    
    [self.mapView setHidden:NO forTileSourceAtIndex:0];
}

#pragma mark -

- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if ([fromIndexPath compare:toIndexPath] == NSOrderedSame)
        return;
    
    DSMapBoxLayer *layer;
    
    switch (fromIndexPath.section)
    {
        case DSMapBoxLayerSectionTile:
        {
            layer = [self.tileLayers objectAtIndex:fromIndexPath.row];
            
            // figure out relative movement in tile layers, leaving space for base layer
            //
            NSArray *desiredSources = [[[self.tileLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.isSelected = YES OR SELF = %@", layer]] reverseObjectEnumerator] allObjects];
            
            int fromRow = [desiredSources indexOfObject:layer] + 1;
            int toRow   = [desiredSources indexOfObject:[self.tileLayers objectAtIndex:toIndexPath.row]] + 1;

            // move in tile layers
            //
            NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
            
            [mutableTileLayers removeObject:layer];
            [mutableTileLayers insertObject:layer atIndex:toIndexPath.row];

            self.tileLayers = [NSArray arrayWithArray:mutableTileLayers];

            // move in tile sources
            //
            [self.mapView moveTileSourceAtIndex:fromRow toIndex:toRow];
            
            [self updateBaseHiddenState];
            
            break;
        }
        case DSMapBoxLayerSectionData:
        {
            layer = [self.dataLayers objectAtIndex:fromIndexPath.row];
            
            NSMutableArray *mutableDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];
            
            [mutableDataLayers removeObject:layer];
            [mutableDataLayers insertObject:layer atIndex:toIndexPath.row];
            
            self.dataLayers = [NSArray arrayWithArray:mutableDataLayers];
            
            break;
        }
    }
    
    [self reloadLayersFromDisk];
    [self reorderLayersDisplay];
}

- (void)deleteLayersAtIndexPaths:(NSArray *)indexPaths
{
    // build up array of actual layers first, as index paths change during individual deletion
    //
    NSMutableArray *layers = [NSMutableArray array];
    
    for (NSIndexPath *indexPath in indexPaths)
    {
        if (indexPath.section == DSMapBoxLayerSectionTile)
            [layers addObject:[self.tileLayers objectAtIndex:indexPath.row]];
        else if (indexPath.section == DSMapBoxLayerSectionData)
            [layers addObject:[self.dataLayers objectAtIndex:indexPath.row]];
    }
    
    // do the actual deletions, toggling off first if necessary
    //
    NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
    NSMutableArray *mutableDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];

    for (DSMapBoxLayer *layer in layers)
    {
        // remove from UI & data model
        //
        if ([mutableTileLayers containsObject:layer])
        {
            if (layer.isSelected)
                [self toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[mutableTileLayers indexOfObject:layer] inSection:DSMapBoxLayerSectionTile]];
            
            [mutableTileLayers removeObject:layer];
        }
        else if ([mutableDataLayers containsObject:layer])
        {
            if (layer.isSelected)
                [self toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[mutableDataLayers indexOfObject:layer] inSection:DSMapBoxLayerSectionData]];
            
            [mutableDataLayers removeObject:layer];
        }
        
        // remove from disk
        //
        [[NSFileManager defaultManager] removeItemAtPath:[layer.URL relativePath] error:NULL];
    }
    
    self.tileLayers = [NSArray arrayWithArray:mutableTileLayers];
    self.dataLayers = [NSArray arrayWithArray:mutableDataLayers];
}

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleLayerAtIndexPath:indexPath zoomingIfNecessary:NO];
}

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath zoomingIfNecessary:(BOOL)zoomNow
{
    DSMapBoxLayer *layer;
    
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionTile:
        {
            layer = [self.tileLayers objectAtIndex:indexPath.row];
            
            if (layer.isSelected) // layer disable
            {
                // remove tile source
                //
                [self.mapView removeTileSource:layer.source];
            }
            else // layer enable
            {
                // create tile source
                //
                NSURL *tileSetURL = layer.URL;
                
                id <RMTileSource>source;
                
                if ([tileSetURL isEqual:kDSOpenStreetMapURL])
                    source = [[RMOpenStreetMapSource alloc] init];

                else if ([tileSetURL isEqual:kDSMapQuestOSMURL])
                    source = [[RMMapQuestOSMSource alloc] init];

                else if ([tileSetURL isTileStreamURL])
                    source = [[RMMapBoxSource alloc] initWithReferenceURL:tileSetURL];
                
                else
                    source = [[RMMBTilesSource alloc] initWithTileSetURL:tileSetURL];
                
                if ( ! layer.source)
                    layer.source = source;
                
                // determine source(s) to show
                //
                NSArray *desiredLayers = [[[self.tileLayers reverseObjectEnumerator] allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isSelected = YES OR SELF = %@", layer]];

                for (int i = 0; i < [desiredLayers count]; i++)
                    if ( ! [self.mapView.tileSources containsObject:((DSMapBoxLayer *)[desiredLayers objectAtIndex:i]).source])
                        [self.mapView addTileSource:(id <RMTileSource>)(((DSMapBoxLayer *)[desiredLayers objectAtIndex:i]).source) atIndex:i + 1];

                [TestFlight passCheckpoint:@"enabled tile layer"];
            }
            
            [self updateBaseHiddenState];
            
            break;
        }
        case DSMapBoxLayerSectionData:
        {
            layer = [self.dataLayers objectAtIndex:indexPath.row];
            
            if (layer.isSelected)
            {
                // forget annotations
                //
                layer.annotations = nil;
                
                // remove visuals
                //
                [self.dataOverlayManager removeOverlayWithSource:layer.source];
            }
            else
            {
                if (layer.type == DSMapBoxLayerTypeKML || layer.type == DSMapBoxLayerTypeKMZ)
                {
                    SimpleKML *kml = [SimpleKML KMLWithContentsOfURL:layer.URL error:NULL];
                    
                    if ( ! kml)
                    {
                        // KML parsing failure
                        //
                        if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didFailToHandleDataLayerAtURL:)])
                            [self.delegate dataLayerHandler:self didFailToHandleDataLayerAtURL:layer.URL];
                        
                        return;
                    }
                    
                    // add layer visuals
                    //
                    if ( ! (layer.annotations = [self.dataOverlayManager addOverlayForKML:kml]) || ! [layer.annotations count])
                    {
                        if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didFailToHandleDataLayerAtURL:)])
                            [self.delegate dataLayerHandler:self didFailToHandleDataLayerAtURL:layer.URL];
                        
                        return;
                    }
                    
                    // save source for comparison later
                    //
                    if ( ! layer.source)
                        layer.source = [kml source];
                    
                    [TestFlight passCheckpoint:@"enabled KML layer"];
                }
                else if (layer.type == DSMapBoxLayerTypeGeoRSS)
                {
                    // save source for comparison later
                    //
                    if ( ! layer.source)
                    {
                        NSError *error = nil;
                        NSString *source = [NSString stringWithContentsOfURL:layer.URL encoding:NSUTF8StringEncoding error:&error];
                        
                        layer.source = source;
                    }
                    
                    // add layer visuals
                    //
                    if ( ! [self.dataOverlayManager addOverlayForGeoRSS:layer.source])
                    {
                        if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didFailToHandleDataLayerAtURL:)])
                            [self.delegate dataLayerHandler:self didFailToHandleDataLayerAtURL:layer.URL];
                        
                        return;
                    }
                    
                    [TestFlight passCheckpoint:@"enabled GeoRSS layer"];
                }
                else if (layer.type == DSMapBoxLayerTypeGeoJSON)
                {
                    // save source for comparison later
                    //
                    if ( ! layer.source)
                    {
                        NSError *error = nil;
                        NSString *source = [NSString stringWithContentsOfURL:layer.URL encoding:NSUTF8StringEncoding error:&error];
                        
                        layer.source = source;
                    }
                    
                    // add layer visuals
                    //
                    if ( ! [self.dataOverlayManager addOverlayForGeoJSON:layer.source])
                    {
                        if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didFailToHandleDataLayerAtURL:)])
                            [self.delegate dataLayerHandler:self didFailToHandleDataLayerAtURL:layer.URL];
                        
                        return;
                    }
                    
                    [TestFlight passCheckpoint:@"enabled GeoJSON layer"];
                }
            }

            break;
        }
    }
    
    // toggle selected state
    //
    layer.selected = ! layer.isSelected;
    
    [self updateLayers];
    [self reorderLayersDisplay];
}

@end