//
//  DSMapBoxLayerController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerController.h"

#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxLayerManager.h"
#import "DSMapBoxMarkerManager.h"
#import "DSMapContents.h"
#import "DSMapBoxTintedBarButtonItem.h"
#import "DSMapBoxTintedPlusItem.h"
#import "DSMapBoxAlertView.h"

#import "RMMapView.h"
#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

#import "MapBoxConstants.h"

#import "Reachability.h"

#import "TestFlight.h"

@interface DSMapBoxLayerController (DSMapBoxLayerControllerPrivate)

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark -

@implementation DSMapBoxLayerController

@synthesize layerManager;
@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Layers";

    self.navigationItem.leftBarButtonItem = [[[DSMapBoxTintedPlusItem alloc] initWithTarget:self.delegate
                                                                                     action:@selector(presentAddLayerHelper)] autorelease];
    
    [self tappedDoneButton:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDocumentsChangedNotification object:nil];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self tappedDoneButton:self];
}

- (void)dealloc
{
    [layerManager release];
    
    [super dealloc];
}

#pragma mark -

- (IBAction)tappedEditButton:(id)sender
{
    self.navigationItem.rightBarButtonItem = [[[DSMapBoxTintedBarButtonItem alloc] initWithTitle:@"Done"
                                                                                          target:self
                                                                                          action:@selector(tappedDoneButton:)] autorelease];

    self.tableView.editing = YES;
}

- (IBAction)tappedDoneButton:(id)sender
{
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" 
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(tappedEditButton:)] autorelease];
    
    self.tableView.editing = NO;
}

- (IBAction)tappedLayerButton:(id)sender event:(id)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint  point = [touch locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: point];

    if (indexPath)
        [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

#pragma mark -

- (BOOL)layerAtURLShouldShowCrosshairs:(NSURL *)layerURL
{
    BOOL shouldShowCrosshairs = NO;
    
    if ([layerURL isMBTilesURL])
    {
        RMMBTilesTileSource *source = [[RMMBTilesTileSource alloc] initWithTileSetURL:layerURL];
        
        if ( ! [source coversFullWorld])
            shouldShowCrosshairs = YES;
        
        [source release];
    }
    else if ([layerURL isTileStreamURL])
    {
        RMTileStreamSource *source = [[RMTileStreamSource alloc] initWithReferenceURL:layerURL];
        
        if ( ! [source coversFullWorld])
            shouldShowCrosshairs = YES;
        
        [source release];
    }

    return shouldShowCrosshairs;
}

#pragma mark -

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     * This routine takes care of the actual toggle, meant for use in a 
     * performSelector:withObject:afterDelay: so as to animate properly 
     * on the next run loop pass. 
     *
     * This assumes we're in selected, animating state, then performs
     * the toggle, then when that returns, deselects the cell, removes 
     * the animator accessory, and re-sets the cell selection state 
     * properly.
     */

    [self.layerManager toggleLayerAtIndexPath:indexPath zoomingIfNecessary:YES];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    NSArray *layers;
    
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionBase:
            layers = self.layerManager.baseLayers;
            break;
            
        case DSMapBoxLayerSectionTile:
            layers = self.layerManager.tileLayers;
            break;
            
        case DSMapBoxLayerSectionData:
            layers = self.layerManager.dataLayers;
            break;
    }
            
    if ([[[layers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue])
    {
        NSURL *layerURL = [[layers objectAtIndex:indexPath.row] valueForKeyPath:@"URL"];
        
        if (indexPath.section == DSMapBoxLayerSectionTile && [self layerAtURLShouldShowCrosshairs:layerURL])
        {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            
            button.frame = CGRectMake(0, 0, 44.0, 44.0);
            
            [button setImage:[UIImage imageNamed:@"crosshairs.png"]           forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"crosshairs_highlight.png"] forState:UIControlStateHighlighted];
            
            [button addTarget:self action:@selector(tappedLayerButton:event:) forControlEvents:UIControlEventTouchUpInside];
            
            cell.accessoryView = button;
        }
        else
        {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    else
    {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case DSMapBoxLayerSectionBase:
            return @"Base Layers";

        case DSMapBoxLayerSectionTile:
            return [self tableView:tableView numberOfRowsInSection:section] ? @"Overlay Layers" : nil;
            
        case DSMapBoxLayerSectionData:
            return [self tableView:tableView numberOfRowsInSection:section] ? @"Data Layers" : nil;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case DSMapBoxLayerSectionBase:
            return self.layerManager.baseLayerCount;
            
        case DSMapBoxLayerSectionTile:
            return self.layerManager.tileLayerCount;

        case DSMapBoxLayerSectionData:
            return self.layerManager.dataLayerCount;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if ( ! cell)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionBase:
            
            cell.accessoryView        = nil;
            cell.accessoryType        = [[[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text       = [[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"name"];
            cell.detailTextLabel.text = [[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"description"];
            
            if ([[[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"URL"] isEqual:kDSOpenStreetMapURL])
                cell.imageView.image = [UIImage imageNamed:@"osm_layer.png"];

            else if ([[[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"URL"] isEqual:kDSMapQuestOSMURL])
                cell.imageView.image = [UIImage imageNamed:@"mapquest_layer.png"];
            
            else if ([[[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"URL"] isTileStreamURL])
                cell.imageView.image = [UIImage imageNamed:@"tilestream_layer.png"];
                
            else
                cell.imageView.image = [UIImage imageNamed:@"mbtiles_layer.png"];
            
            break;
            
        case DSMapBoxLayerSectionTile:

            if ([[[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue])
            {
                NSURL *layerURL = [[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"URL"];
                
                if ([self layerAtURLShouldShowCrosshairs:layerURL])
                {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    
                    button.frame = CGRectMake(0, 0, 44.0, 44.0);
                    
                    [button setImage:[UIImage imageNamed:@"crosshairs.png"]           forState:UIControlStateNormal];
                    [button setImage:[UIImage imageNamed:@"crosshairs_highlight.png"] forState:UIControlStateHighlighted];
                    
                    [button addTarget:self action:@selector(tappedLayerButton:event:) forControlEvents:UIControlEventTouchUpInside];
                    
                    cell.accessoryView = button;
                }
                else
                {
                    cell.accessoryView = nil;
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
            else
            {
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;                
            }

            cell.textLabel.text       = [[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"name"];
            cell.detailTextLabel.text = [[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"description"];

            if ([[[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"URL"] isTileStreamURL])
                cell.imageView.image = [UIImage imageNamed:@"tilestream_layer.png"];
            
            else
                cell.imageView.image = [UIImage imageNamed:@"mbtiles_layer.png"];
            
            break;
            
        case DSMapBoxLayerSectionData:

            cell.accessoryView        = nil;
            cell.accessoryType        = [[[self.layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.textLabel.text       = [[self.layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"name"];
            cell.detailTextLabel.text = [[self.layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"description"];
            
            switch ([[[self.layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"type"] intValue])
            {
                case DSMapBoxLayerTypeKML:
                case DSMapBoxLayerTypeKMZ:
                    cell.imageView.image = [UIImage imageNamed:@"kml_layer.png"];
                    break;

                case DSMapBoxLayerTypeGeoRSS:
                    cell.imageView.image = [UIImage imageNamed:@"georss_layer.png"];
                    break;

                case DSMapBoxLayerTypeGeoJSON:
                    cell.imageView.image = [UIImage imageNamed:@"geojson_layer.png"];
                    break;
            }
            
            break;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *baseTileSetURL;

    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionBase:
            baseTileSetURL = [[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKey:@"URL"];
       
            // don't allow deletion of OSM or bundled tile set
            //
            if ([baseTileSetURL isEqual:kDSOpenStreetMapURL] || [baseTileSetURL isEqual:kDSMapQuestOSMURL] || [[[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKey:@"name"] isEqualToString:[[DSMapBoxTileSetManager defaultManager] defaultTileSetName]])
                return NO;
                
            return YES;
            
        case DSMapBoxLayerSectionTile:
        case DSMapBoxLayerSectionData:
            return YES;
    }
    
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionBase:
            return NO;
            
        case DSMapBoxLayerSectionTile:
            return YES;
            
        case DSMapBoxLayerSectionData:
            return ! ((DSMapBoxMarkerManager *)((RMMapView *)self.layerManager.baseMapView).contents.markerManager).clusteringEnabled;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.layerManager moveLayerAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    
    [TestFlight passCheckpoint:@"reordered layers"];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // "archival" is currently deletion -- this might change! 
    //
    if (indexPath.section == DSMapBoxLayerSectionBase)
    {
        // we want to warn the user if they are deleting a base layer, which is possibly quite large
        //
        NSURL *tileSetURL = [[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKey:@"URL"];
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[tileSetURL relativePath] error:NULL];
        
        if ([[attributes objectForKey:NSFileSize] unsignedLongLongValue] >= (1024 * 1024 * 100)) // 100MB+
        {
            DSMapBoxAlertView *alert = [[[DSMapBoxAlertView alloc] initWithTitle:@"Delete Base Layer?"
                                                                         message:@"This is a large layer file. Are you sure that you want to delete it permanently?"
                                                                        delegate:self
                                                               cancelButtonTitle:@"Don't Delete"
                                                               otherButtonTitles:@"Delete", nil] autorelease];
            
            alert.context = indexPath;
            
            [alert show];
            
            return;
        }

        // revert to default bundled tileset if active one was deleted
        //
        if ([tileSetURL isEqual:[[DSMapBoxTileSetManager defaultManager] activeTileSetURL]])
            [[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:[[DSMapBoxTileSetManager defaultManager] defaultTileSetName] animated:NO];
    }
    
    [self.layerManager archiveLayerAtIndexPath:indexPath];
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    [self tappedDoneButton:self];
}

#pragma mark -

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.selectedBackgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
    cell.selectedBackgroundView.backgroundColor = kMapBoxBlue;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *layer;
    
    if (indexPath.section == DSMapBoxLayerSectionBase)
        layer = [self.layerManager.baseLayers objectAtIndex:indexPath.row];
    
    else if (indexPath.section == DSMapBoxLayerSectionTile)
        layer = [self.layerManager.tileLayers objectAtIndex:indexPath.row];
    
    else if (indexPath.section == DSMapBoxLayerSectionData)
        layer = [self.layerManager.dataLayers objectAtIndex:indexPath.row];
    
    if (layer && ([[layer objectForKey:@"URL"] isEqual:kDSOpenStreetMapURL] || [[layer objectForKey:@"URL"] isEqual:kDSMapQuestOSMURL] || [[layer objectForKey:@"URL"] isTileStreamURL]))
    {        
        if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];

            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                             message:[NSString stringWithFormat:@"%@ requires an active internet connection.", [tableView cellForRowAtIndexPath:indexPath].textLabel.text]
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil] autorelease];

            [alert show];
            
            return;
        }
    }
    else if (indexPath.section == DSMapBoxLayerSectionBase || indexPath.section == DSMapBoxLayerSectionTile)
    {
        NSArray *layers;
        
        if (indexPath.section == DSMapBoxLayerSectionBase)
            layers = self.layerManager.baseLayers;

        else
            layers = self.layerManager.tileLayers;
        
        NSDictionary *layer = [layers objectAtIndex:indexPath.row];
        
        if ([[[layer valueForKey:@"URL"] pathExtension] isEqualToString:@"mbtiles"])
        {
            if ([[[[RMMBTilesTileSource alloc] initWithTileSetURL:[layer valueForKey:@"URL"]] autorelease] maxZoomNative] < kLowerZoomBounds)
            {
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
                
                UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to zoom"
                                                                 message:[NSString stringWithFormat:@"The %@ layer can't zoom out far enough to be displayed. Please contact the layer author and request a file that supports zoom level 3 or higher.", [layer valueForKey:@"name"]]
                                                                delegate:nil
                                                       cancelButtonTitle:nil
                                                       otherButtonTitles:@"OK", nil] autorelease];
                
                [alert show];
                
                return;
            }
        }
    }
    
    /**
     * In response to potentially long toggle operations, we add a spinner 
     * accessory view & start it animating. Then, we do the actual operation
     * in the next run loop pass, which also takes care of removing the
     * animation and re-setting selected state. 
     */
    
    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    [self.tableView cellForRowAtIndexPath:indexPath].accessoryView = spinner;
    [spinner startAnimating];
    
    [self performSelector:@selector(toggleLayerAtIndexPath:) withObject:indexPath afterDelay:0.0];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Delete";
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (sourceIndexPath.section < proposedDestinationIndexPath.section)
        return [NSIndexPath indexPathForRow:0 inSection:sourceIndexPath.section];

    else if (sourceIndexPath.section > proposedDestinationIndexPath.section)
        return [NSIndexPath indexPathForRow:([[tableView dataSource] tableView:tableView numberOfRowsInSection:sourceIndexPath.section] - 1) 
                                  inSection:sourceIndexPath.section];
    
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    /**
     * Note that we are currently faking this via accessory view button actions.
     */
    
    NSDictionary *layer;
    
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionBase:
            layer = [self.layerManager.baseLayers objectAtIndex:indexPath.row];
            break;
            
        case DSMapBoxLayerSectionTile:
            layer = [self.layerManager.tileLayers objectAtIndex:indexPath.row];
            break;
            
        case DSMapBoxLayerSectionData:
            layer = [self.layerManager.dataLayers objectAtIndex:indexPath.row];
            break;
    }

    if (indexPath.section == DSMapBoxLayerSectionTile)
        if (self.delegate && [self.delegate respondsToSelector:@selector(zoomToLayer:)])
            [self.delegate zoomToLayer:layer];
    
    [TestFlight passCheckpoint:@"tapped layer crosshairs to zoom"];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        NSIndexPath *indexPath = (NSIndexPath *)((DSMapBoxAlertView *)alertView).context;
        
        NSURL *tileSetURL = [[self.layerManager.baseLayers objectAtIndex:indexPath.row] valueForKey:@"URL"];

        // revert to default bundled tileset if active one was deleted
        //
        if ([tileSetURL isEqual:[[DSMapBoxTileSetManager defaultManager] activeTileSetURL]])
            [[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:[[DSMapBoxTileSetManager defaultManager] defaultTileSetName] animated:NO];
        
        [self.layerManager archiveLayerAtIndexPath:indexPath];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    }

    [self tappedDoneButton:self];
}

@end