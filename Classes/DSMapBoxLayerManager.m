//
//  DSMapBoxLayerManager.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/27/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerManager.h"

#import "DSMapBoxDataOverlayManager.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxTiledLayerMapView.h"
#import "DSMapContents.h"
#import "DSMapView.h"

#import "UIApplication_Additions.h"

#import "SimpleKML.h"

#import "RMOpenStreetMapSource.h"
#import "RMMapQuestOSMSource.h"
#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLayerManager ()

@property (nonatomic, retain) DSMapBoxDataOverlayManager *dataOverlayManager;
@property (nonatomic, retain) DSMapView *baseMapView;
@property (nonatomic, retain) NSArray *tileLayers;
@property (nonatomic, retain) NSArray *dataLayers;

- (void)reloadLayersFromDisk;
- (void)reorderLayerDisplay;

@end

#pragma mark -

@implementation DSMapBoxLayerManager

@synthesize dataOverlayManager;
@synthesize baseMapView;
@synthesize tileLayers;
@synthesize dataLayers;
@synthesize delegate;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager overBaseMapView:(DSMapView *)mapView;
{
    self = [super init];

    if (self != nil)
    {
        dataOverlayManager = [overlayManager retain];
        baseMapView        = [mapView retain];
        
        tileLayers = [[NSArray array] retain];
        dataLayers = [[NSArray array] retain];
        
        [self reloadLayersFromDisk];
        
        if ([[tileLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"mbtiles"]) // bundled set doesn't have a URL
            [TESTFLIGHT passCheckpoint:@"has MBTiles layer"];
        
        if ([[tileLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"plist"])
            [TESTFLIGHT passCheckpoint:@"has TileStream layer"];
            
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"kml"])
            [TESTFLIGHT passCheckpoint:@"has KML layer (.kml)"];
        
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"kmz"])
            [TESTFLIGHT passCheckpoint:@"has KML layer (.kmz)"];
        
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"rss"])            
            [TESTFLIGHT passCheckpoint:@"has GeoRSS layer (.rss)"];
            
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"xml"])
            [TESTFLIGHT passCheckpoint:@"has GeoRSS layer (.xml)"];
        
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"json"])
            [TESTFLIGHT passCheckpoint:@"has GeoJSON layer (.json)"];
            
        if ([[dataLayers valueForKeyPath:@"URL.pathExtension"] containsObject:@"geojson"])
            [TESTFLIGHT passCheckpoint:@"has GeoJSON layer (.geojson)"];
        
        [TESTFLIGHT addCustomEnvironmentInformation:[NSString stringWithFormat:@"%i", [tileLayers count]] forKey:@"tile layer count"];
        [TESTFLIGHT addCustomEnvironmentInformation:[NSString stringWithFormat:@"%i", [dataLayers count]] forKey:@"data layer count"];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadLayersFromDisk)
                                                     name:DSMapBoxDocumentsChangedNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxDocumentsChangedNotification object:nil];

    [dataOverlayManager release];
    [baseMapView release];
    [tileLayers release];
    [dataLayers release];
    
    [super dealloc];
}

#pragma mark -

- (void)reloadLayersFromDisk
{
    // tile layers
    //
    NSArray *tileSetURLs = [[DSMapBoxTileSetManager defaultManager] tileSetURLs];
    
    NSMutableArray *mutableTileLayers  = [NSMutableArray arrayWithArray:self.tileLayers];
    NSMutableArray *tileLayersToRemove = [NSMutableArray array];
    
    // look for layers missing on disk, turning them off
    //
    for (NSDictionary *tileLayer in mutableTileLayers)
    {
        if ( ! [tileSetURLs containsObject:[tileLayer objectForKey:@"URL"]])
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
    for (NSURL *tileSetURL in tileSetURLs)
    {
        if ( ! [[mutableTileLayers valueForKeyPath:@"URL"] containsObject:tileSetURL])
        {
            NSString *name        = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:tileSetURL];
            NSString *description = [[DSMapBoxTileSetManager defaultManager] descriptionForTileSetAtURL:tileSetURL];
            
            [mutableTileLayers addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:tileSetURL,                        @"URL",
                                                                                           name,                              @"name",
                                                                                           (description ? description : @""), @"description",
                                                                                           [NSNumber numberWithBool:NO],      @"selected",
                                                                                           nil]];
        }
    }
    
    self.tileLayers = [NSArray arrayWithArray:mutableTileLayers];

    // data layers
    //
    NSArray *docs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPathString] error:NULL];
    
    NSMutableArray *mutableDataLayers  = [NSMutableArray arrayWithArray:self.dataLayers];
    NSMutableArray *dataLayersToRemove = [NSMutableArray array];
    
    // look for layers missing on disk, turning them off
    //
    for (NSDictionary *dataLayer in mutableDataLayers)
    {
        if ( ! [docs containsObject:[[dataLayer objectForKey:@"URL"] lastPathComponent]])
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

            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSURL fileURLWithPath:path],                  @"URL", 
                                                                                           name,                                          @"name",
                                                                                           description,                                   @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeKML], @"type",
                                                                                           [NSNumber numberWithBool:NO],                  @"selected",
                                                                                           nil];
            
            [mutableDataLayers addObject:layer];
        }
        else if ([[[path pathExtension] lowercaseString] isEqualToString:@"rss"] && 
                  ! [[mutableDataLayers valueForKeyPath:@"URL"] containsObject:[NSURL fileURLWithPath:path]])
        {
            NSString *description = @"GeoRSS Feed";

            NSString *name = [path lastPathComponent];
        
            name = [name stringByReplacingOccurrencesOfString:@".rss" 
                                                   withString:@""
                                                      options:NSCaseInsensitiveSearch
                                                        range:NSMakeRange(0, [name length])];
                        
            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSURL fileURLWithPath:path],                     @"URL", 
                                                                                           name,                                             @"name",
                                                                                           description,                                      @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeGeoRSS], @"type",
                                                                                           [NSNumber numberWithBool:NO],                     @"selected",
                                                                                           nil];
            
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

            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSURL fileURLWithPath:path],                      @"URL", 
                                                                                           name,                                              @"name",
                                                                                           description,                                       @"description",
                                                                                           [NSNumber numberWithInt:DSMapBoxLayerTypeGeoJSON], @"type",
                                                                                           [NSNumber numberWithBool:NO],                      @"selected",
                                                                                           nil];
            
            [mutableDataLayers addObject:layer];
        }
    }
        
    self.dataLayers = [NSArray arrayWithArray:mutableDataLayers];
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
        [((DSMapContents *)self.baseMapView.contents).layerMapViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        // iterate visible layers, finding map for each & inserting it above top-most existing map layer
        //
        for (NSUInteger i = 0; i < [visibleTileLayers count]; i++)
        {
            DSMapBoxTiledLayerMapView *layerMapView = [[((DSMapContents *)self.baseMapView.contents).layerMapViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tileSetURL = %@", [[visibleTileLayers objectAtIndex:i] objectForKey:@"URL"]]] lastObject];
            
            [self.baseMapView insertLayerMapView:layerMapView];
            
            [orderedMaps addObject:layerMapView];
        }
        
        // find the new top-most map
        //
        DSMapBoxTiledLayerMapView *topMostMap = [orderedMaps lastObject];

        // pass the data overlay baton to it
        //
        self.dataOverlayManager.mapView = topMostMap;

        // setup the master map & data manager connections
        //
        topMostMap.masterView = self.baseMapView;
        topMostMap.delegate   = self.dataOverlayManager;
        
        // zero out the non-top-most map connections
        //
        [orderedMaps removeLastObject];

        for (DSMapBoxTiledLayerMapView *orderedMap in orderedMaps)
        {
            orderedMap.masterView = nil;
            orderedMap.delegate   = nil;
        }
    }
}

#pragma mark -

- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableDictionary *layer;
    
    switch (fromIndexPath.section)
    {
        case DSMapBoxLayerSectionTile:
            
            layer = [self.tileLayers objectAtIndex:fromIndexPath.row];

            NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
            
            [mutableTileLayers removeObject:layer];
            [mutableTileLayers insertObject:layer atIndex:toIndexPath.row];

            self.tileLayers = [NSArray arrayWithArray:mutableTileLayers];
            
            break;
            
        case DSMapBoxLayerSectionData:
            
            layer = [self.dataLayers objectAtIndex:fromIndexPath.row];
            
            NSMutableArray *mutableDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];
            
            [mutableDataLayers removeObject:layer];
            [mutableDataLayers insertObject:layer atIndex:toIndexPath.row];
            
            self.dataLayers = [NSArray arrayWithArray:mutableDataLayers];
            
            break;
    }
    
    [self reloadLayersFromDisk];
    [self reorderLayerDisplay];
}

- (void)deleteLayerAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *layer;

    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionTile:
            
            layer = [self.tileLayers objectAtIndex:indexPath.row];
            
            if ([[layer objectForKey:@"selected"] boolValue])
                [self toggleLayerAtIndexPath:indexPath];

            [[NSFileManager defaultManager] removeItemAtPath:[[layer objectForKey:@"URL"] relativePath] error:NULL];
            
            NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
            
            [mutableTileLayers removeObject:layer];
            
            self.tileLayers = [NSArray arrayWithArray:mutableTileLayers];
            
            break;
            
        case DSMapBoxLayerSectionData:
            
            layer = [self.dataLayers objectAtIndex:indexPath.row];

            if ([[layer objectForKey:@"selected"] boolValue])
                [self toggleLayerAtIndexPath:indexPath];
            
            [[NSFileManager defaultManager] removeItemAtPath:[[layer objectForKey:@"URL"] relativePath] error:NULL];
            
            NSMutableArray *mutableDataLayers = [NSMutableArray arrayWithArray:self.dataLayers];
            
            [mutableDataLayers removeObject:layer];
            
            self.dataLayers = [NSArray arrayWithArray:mutableDataLayers];
            
            break;
    }
}

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath
{
    [self toggleLayerAtIndexPath:indexPath zoomingIfNecessary:NO];
}

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath zoomingIfNecessary:(BOOL)zoomNow
{
    NSMutableDictionary *layer = nil;
    
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionTile:
            
            layer = [self.tileLayers objectAtIndex:indexPath.row];
            
            if ([[layer objectForKey:@"selected"] boolValue])
            {
                for (UIView *baseMapPeer in self.baseMapView.superview.subviews)
                {
                    if ([baseMapPeer isKindOfClass:[DSMapBoxTiledLayerMapView class]])
                    {
                        if ([((DSMapBoxTiledLayerMapView *)baseMapPeer).tileSetURL isEqual:[layer objectForKey:@"URL"]])
                        {
                            // disassociate with master map
                            //
                            NSMutableArray *layerMapViews = [NSMutableArray arrayWithArray:((DSMapContents *)self.baseMapView.contents).layerMapViews];
                            [layerMapViews removeObject:baseMapPeer];
                            ((DSMapContents *)self.baseMapView.contents).layerMapViews = [NSArray arrayWithArray:layerMapViews];

                            // remove from view hierarchy
                            //
                            [baseMapPeer removeFromSuperview];
                            
                            // transfer data overlay status
                            //
                            self.dataOverlayManager.mapView = ([layerMapViews count] ? [layerMapViews lastObject] : self.baseMapView);
                        }
                    }
                }
            }
            else
            {
                // create tile source
                //
                NSURL *tileSetURL = [layer objectForKey:@"URL"];
                
                id <RMTileSource>source;
                
                if ([tileSetURL isEqual:kDSOpenStreetMapURL])
                    source = [[[RMOpenStreetMapSource alloc] init] autorelease];

                else if ([tileSetURL isEqual:kDSMapQuestOSMURL])
                    source = [[[RMMapQuestOSMSource alloc] init] autorelease];

                else if ([tileSetURL isTileStreamURL])
                    source = [[[RMTileStreamSource alloc] initWithReferenceURL:tileSetURL] autorelease];
                
                else
                    source = [[[RMMBTilesTileSource alloc] initWithTileSetURL:tileSetURL] autorelease];
                
                // create the overlay map view
                //
                DSMapBoxTiledLayerMapView *layerMapView = [[[DSMapBoxTiledLayerMapView alloc] initWithFrame:self.baseMapView.frame] autorelease];
                
                layerMapView.tileSetURL = tileSetURL;
                
                // insert above top-most existing map view
                //
                [self.baseMapView insertLayerMapView:layerMapView];
                
                // copy main map view attributes
                //
                layerMapView.autoresizingMask = self.baseMapView.autoresizingMask;
                layerMapView.enableRotate     = self.baseMapView.enableRotate;
                layerMapView.deceleration     = self.baseMapView.deceleration;

                [[[DSMapContents alloc] initWithView:layerMapView 
                                          tilesource:source
                                        centerLatLon:self.baseMapView.contents.mapCenter
                                           zoomLevel:self.baseMapView.contents.zoom
                                        maxZoomLevel:[source maxZoom]
                                        minZoomLevel:[source minZoom]
                                     backgroundImage:nil] autorelease];
                
                // get peer layer map views
                //
                NSMutableArray *layerMapViews = [NSMutableArray arrayWithArray:((DSMapContents *)self.baseMapView.contents).layerMapViews];

                // disassociate peers with master
                //
                for (DSMapBoxTiledLayerMapView *mapView in layerMapViews)
                {
                    mapView.masterView = nil;
                    mapView.delegate   = nil;
                }
                
                // associate new with master
                //
                [layerMapViews addObject:layerMapView];
                ((DSMapContents *)self.baseMapView.contents).layerMapViews = [NSArray arrayWithArray:layerMapViews];
                layerMapView.masterView = self.baseMapView;

                // associate new with data overlay manager
                //
                layerMapView.delegate = self.dataOverlayManager;
                self.dataOverlayManager.mapView = layerMapView;
                
                [TESTFLIGHT passCheckpoint:@"enabled tile layer"];
            }

            break;
            
        case DSMapBoxLayerSectionData:
            
            layer = [self.dataLayers objectAtIndex:indexPath.row];
            
            if ([[layer objectForKey:@"selected"] boolValue])
            {
                [self.dataOverlayManager removeOverlayWithSource:[layer objectForKey:@"source"]];
            }
            else
            {
                if ([[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeKML || [[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeKMZ)
                {
                    SimpleKML *kml = [SimpleKML KMLWithContentsOfURL:[layer objectForKey:@"URL"] error:NULL];
                    
                    if ( ! kml)
                    {
                        if ([self.delegate respondsToSelector:@selector(dataLayerHandler:didFailToHandleDataLayerAtURL:)])
                            [self.delegate dataLayerHandler:self didFailToHandleDataLayerAtURL:[layer objectForKey:@"URL"]];
                        
                        return;
                    }
                    
                    [self.dataOverlayManager addOverlayForKML:kml];
                    
                    if ( ! [layer objectForKey:@"source"])
                        [layer setObject:[kml source] forKey:@"source"];
                    
                    [TESTFLIGHT passCheckpoint:@"enabled KML layer"];
                }
                else if ([[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeGeoRSS)
                {
                    if ( ! [layer objectForKey:@"source"])
                    {
                        NSError *error = nil;
                        NSString *source = [NSString stringWithContentsOfURL:[layer objectForKey:@"URL"] encoding:NSUTF8StringEncoding error:&error];
                        
                        [layer setObject:source forKey:@"source"];
                    }
                    
                    [self.dataOverlayManager addOverlayForGeoRSS:[layer objectForKey:@"source"]];
                    
                    [TESTFLIGHT passCheckpoint:@"enabled GeoRSS layer"];
                }
                else if ([[layer objectForKey:@"type"] intValue] == DSMapBoxLayerTypeGeoJSON)
                {
                    if ( ! [layer objectForKey:@"source"])
                    {
                        NSError *error = nil;
                        NSString *source = [NSString stringWithContentsOfURL:[layer objectForKey:@"URL"] encoding:NSUTF8StringEncoding error:&error];
                        
                        [layer setObject:source forKey:@"source"];
                    }
                    
                    [self.dataOverlayManager addOverlayForGeoJSON:[layer objectForKey:@"source"]];
                    
                    [TESTFLIGHT passCheckpoint:@"enabled GeoJSON layer"];
                }
            }

            break;
    }
    
    [layer setObject:[NSNumber numberWithBool:( ! [[layer objectForKey:@"selected"] boolValue])] forKey:@"selected"];
    
    if (indexPath.section == DSMapBoxLayerSectionData && [self.delegate respondsToSelector:@selector(dataLayerHandler:didUpdateDataLayerCount:)])
        [self.delegate dataLayerHandler:self didUpdateDataLayerCount:[[self.dataLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]] count]];

    if ([[layer objectForKey:@"selected"] boolValue])
        [self reorderLayerDisplay];
}

@end