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
#import "DSMapBoxSQLiteTileSource.h"
#import "DSTiledLayerMapView.h"
#import "DSMapContents.h"

#import "UIApplication_Additions.h"

#import "SimpleKML.h"

#import "RMMapView.h"

@interface DSMapBoxLayerManager (DSMapBoxLayerManagerPrivate)

- (void)reloadLayersFromDisk;
- (void)reorderLayerDisplay;

@end

#pragma mark -

@implementation DSMapBoxLayerManager

@synthesize baseMapView;
@synthesize tileLayers;
@synthesize dataLayers;
@synthesize tileLayerCount;
@synthesize dataLayerCount;

- (id)initWithDataOverlayManager:(DSMapBoxDataOverlayManager *)overlayManager overBaseMapView:(RMMapView *)mapView;
{
    self = [super init];

    if (self != nil)
    {
        dataOverlayManager = [overlayManager retain];
        baseMapView        = [mapView retain];
        
        tileLayers = [[NSArray array] retain];
        dataLayers = [[NSArray array] retain];
        
        [self reloadLayersFromDisk];
    }

    return self;
}

- (void)dealloc
{
    [dataOverlayManager release];
    [baseMapView release];
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

- (void)reloadLayersFromDisk
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
            NSString *description = @""; // TODO: better description
            //[NSString stringWithFormat:@"%i Points", ([[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"<Point>"] count] - 1)];
            
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
            NSString *description = @""; // TODO: better description
            //[NSString stringWithFormat:@"%i Points", ([[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL] componentsSeparatedByString:@"georss:point"] count] - 1)];
            
            NSMutableDictionary *layer = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                                             @"path", 
                                                                                           [path lastPathComponent],                         @"name",
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
        
        // iterate visible layers, finding map for each & inserting it on top (but below toolbar & watermark)
        //
        for (NSUInteger i = 0; i < [visibleTileLayers count]; i++)
        {
            DSTiledLayerMapView *layerMapView = [[((DSMapContents *)baseMapView.contents).layerMapViews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tileSetURL = %@", [[visibleTileLayers objectAtIndex:i] objectForKey:@"path"]]] lastObject];
            
            [[baseMapView superview] insertSubview:layerMapView atIndex:([baseMapView.superview.subviews count] - 2)];
            
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
        //
    }
}

#pragma mark -

- (void)moveLayerAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableDictionary *layer;
    
    switch (fromIndexPath.section)
    {
        case 0: // can't move base layers
            
            return;
            
        case 1: // tile layers
            
            layer = [self.tileLayers objectAtIndex:fromIndexPath.row];

            NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
            
            [mutableTileLayers removeObject:layer];
            [mutableTileLayers insertObject:layer atIndex:toIndexPath.row];

            [tileLayers release];
            tileLayers = [[NSArray arrayWithArray:mutableTileLayers] retain];
            
            break;
            
        case 2: // data layers
            
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
    // TODO: remove from display if active
    
    NSMutableDictionary *layer;

    switch (indexPath.section)
    {
        case 0: // can't archive base layers (for now)
            
            return;
            
        case 1: // tile layers
            
            layer = [self.tileLayers objectAtIndex:indexPath.row];
            
            [[NSFileManager defaultManager] removeItemAtPath:[[layer objectForKey:@"path"] relativePath] error:NULL];
            
            NSMutableArray *mutableTileLayers = [NSMutableArray arrayWithArray:self.tileLayers];
            
            [mutableTileLayers removeObject:layer];
            
            [tileLayers release];
            tileLayers = [[NSArray arrayWithArray:mutableTileLayers] retain];
            
            break;
            
        case 2: // data layers
            
            layer = [self.dataLayers objectAtIndex:indexPath.row];

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
    NSMutableDictionary *layer;
    
    switch (indexPath.section)
    {
        case 0: // TODO: change base layers via this UI
            
            return;
            
        case 1: // tile layers
            
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
                // create tile source & map view
                //
                NSURL *tileSetURL = [layer objectForKey:@"path"];
                
                DSMapBoxSQLiteTileSource *source = [[[DSMapBoxSQLiteTileSource alloc] initWithTileSetAtURL:tileSetURL] autorelease];
                
                DSTiledLayerMapView *layerMapView = [[[DSTiledLayerMapView alloc] initWithFrame:baseMapView.frame] autorelease];
                
                layerMapView.tileSetURL = tileSetURL;
                
                // insert below toolbar & watermark
                //
                [[baseMapView superview] insertSubview:layerMapView atIndex:([baseMapView.superview.subviews count] - 2)];
                
                // copy main map view attributes
                //
                layerMapView.autoresizingMask = baseMapView.autoresizingMask;
                layerMapView.enableRotate     = baseMapView.enableRotate;
                layerMapView.deceleration     = baseMapView.deceleration;

                // setup the new map view contents
                //
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
            
        case 2: // data layers
            
            layer = [self.dataLayers objectAtIndex:indexPath.row];
            
            if ( ! [layer objectForKey:@"source"])
            {
                NSString *source = [NSString stringWithContentsOfFile:[layer objectForKey:@"path"] encoding:NSUTF8StringEncoding error:NULL];
                
                [layer setObject:source forKey:@"source"];
            }
            
            if ([[layer objectForKey:@"selected"] boolValue])
            {
                [dataOverlayManager removeOverlayWithSource:[layer objectForKey:@"source"]];
            }
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
    
    if ([[layer objectForKey:@"selected"] boolValue])
        [self reorderLayerDisplay];
}

@end