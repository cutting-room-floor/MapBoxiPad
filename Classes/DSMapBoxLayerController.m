//
//  DSMapBoxLayerController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerController.h"

#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxLayerManager.h"
#import "DSMapBoxMarkerManager.h"
#import "DSMapContents.h"
#import "DSMapBoxTintedBarButtonItem.h"
#import "DSMapBoxTintedPlusItem.h"
#import "DSMapBoxAlertView.h"
#import "DSMapBoxTileSourceInfiniteZoom.h"
#import "DSMapView.h"

#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

#import "Reachability.h"

@interface DSMapBoxLayerController ()

@property (nonatomic, retain) NSIndexPath *indexPathToDelete;

- (BOOL)layerAtURLShouldShowCrosshairs:(NSURL *)layerURL;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark -

@implementation DSMapBoxLayerController

@synthesize layerManager;
@synthesize indexPathToDelete;
@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Layers";

    self.navigationItem.leftBarButtonItem = [[[DSMapBoxTintedPlusItem alloc] initWithTarget:self.delegate
                                                                                     action:@selector(presentAddLayerHelper)] autorelease];
    
    // We are always in editing mode, which allows reordering
    // of layers at any time. We use gestures to bring up a
    // menu for deletion rather than use the built-in table 
    // view way, though.
    //
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.editing = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] postNotificationName:DSMapBoxDocumentsChangedNotification object:nil];
    
    [self.tableView reloadData];
}

- (void)dealloc
{
    [layerManager release];
    [indexPathToDelete release];
    
    [super dealloc];
}

#pragma mark -

- (IBAction)tappedLayerButton:(id)sender event:(id)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint  point = [touch locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint: point];

    if (indexPath)
        [self tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (void)handleGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]] && gesture.state == UIGestureRecognizerStateBegan)
    {
        // cancel gesture
        //
        gesture.enabled = NO;
        gesture.enabled = YES;
        
        // determine cell touched & index path
        //
        UITableViewCell *cell = (UITableViewCell *)gesture.view;
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        
        // show deletion menu for deletable layers
        //
        BOOL layerCanBeDeleted = NO;
        
        if (indexPath.section == DSMapBoxLayerSectionTile)
        {
            NSURL *tileSetURL = [[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKey:@"URL"];
            
            if ( ! [tileSetURL isEqual:kDSOpenStreetMapURL] && ! [tileSetURL isEqual:kDSMapQuestOSMURL])
                layerCanBeDeleted = YES;
        }
        else if (indexPath.section == DSMapBoxLayerSectionData)
        {
            layerCanBeDeleted = YES;
        }
        
        if (layerCanBeDeleted)
        {
            self.indexPathToDelete = [self.tableView indexPathForCell:cell];
            
            UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:cell.textLabel.text
                                                                      delegate:self
                                                             cancelButtonTitle:@"Cancel"
                                                        destructiveButtonTitle:@"Delete Layer"
                                                             otherButtonTitles:nil] autorelease];
            
            [actionSheet showFromRect:cell.frame inView:cell animated:YES];
            
            [TESTFLIGHT passCheckpoint:@"long-press gesture to delete layer table row"];
        }
    }
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
    
    NSArray *layers = nil;
    
    switch (indexPath.section)
    {
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
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case DSMapBoxLayerSectionTile:
            return @"Tile Layers";
            
        case DSMapBoxLayerSectionData:
            return @"Data Layers";
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case DSMapBoxLayerSectionTile:
            return [self.layerManager.tileLayers count];

        case DSMapBoxLayerSectionData:
            return [self.layerManager.dataLayers count];
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *LayerCellIdentifier = @"LayerCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LayerCellIdentifier];

    if ( ! cell)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:LayerCellIdentifier] autorelease];
    
    NSDictionary *layer = nil;
    
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionTile:

            layer = [self.layerManager.tileLayers objectAtIndex:indexPath.row];
            
            if ([[layer valueForKey:@"selected"] boolValue])
            {
                NSURL *layerURL = [layer valueForKey:@"URL"];
                
                if ([self layerAtURLShouldShowCrosshairs:layerURL])
                {
                    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                    
                    button.frame = CGRectMake(0, 0, 44.0, 44.0);
                    
                    [button setImage:[UIImage imageNamed:@"crosshairs.png"]           forState:UIControlStateNormal];
                    [button setImage:[UIImage imageNamed:@"crosshairs_highlight.png"] forState:UIControlStateHighlighted];
                    
                    [button addTarget:self action:@selector(tappedLayerButton:event:) forControlEvents:UIControlEventTouchUpInside];
                    
                    cell.accessoryView        = button;
                    cell.editingAccessoryView = button;
                }
                else
                {
                    cell.accessoryView        = nil;
                    cell.editingAccessoryView = nil;
                    
                    cell.accessoryType        = UITableViewCellAccessoryCheckmark;
                    cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
            else
            {
                cell.accessoryView        = nil;
                cell.editingAccessoryView = nil;
                
                cell.accessoryType        = UITableViewCellAccessoryNone;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
            }

            cell.textLabel.text       = [layer valueForKey:@"name"];
            cell.detailTextLabel.text = [layer valueForKey:@"description"];

            if ([[layer valueForKey:@"URL"] isEqual:kDSOpenStreetMapURL])
                cell.imageView.image = [UIImage imageNamed:@"osm_layer.png"];
            
            else if ([[layer valueForKey:@"URL"] isEqual:kDSMapQuestOSMURL])
                cell.imageView.image = [UIImage imageNamed:@"mapquest_layer.png"];
            
            else if ([[layer valueForKey:@"URL"] isTileStreamURL])
                cell.imageView.image = [UIImage imageNamed:@"tilestream_layer.png"];
            
            else
                cell.imageView.image = [UIImage imageNamed:@"mbtiles_layer.png"];
            
            break;
            
        case DSMapBoxLayerSectionData:

            layer = [self.layerManager.dataLayers objectAtIndex:indexPath.row];
            
            cell.accessoryView        = nil;
            cell.editingAccessoryView = nil;
            
            cell.accessoryType        = [[layer valueForKey:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.editingAccessoryType = cell.accessoryType;
            
            cell.textLabel.text       = [layer valueForKey:@"name"];
            cell.detailTextLabel.text = [layer valueForKey:@"description"];
            
            switch ([[layer valueForKey:@"type"] intValue])
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
    
    if ( ! cell.gestureRecognizers)
    {
        UILongPressGestureRecognizer *gesture = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)] autorelease];

        gesture.minimumPressDuration = 1.0;

        [cell addGestureRecognizer:gesture];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case DSMapBoxLayerSectionTile:
            return YES;
            
        case DSMapBoxLayerSectionData:
            return ! ((DSMapBoxMarkerManager *)self.layerManager.baseMapView.topMostMapView.contents.markerManager).clusteringEnabled;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.layerManager moveLayerAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    
    [TESTFLIGHT passCheckpoint:@"reordered layers"];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DSMapBoxLayerSectionTile)
    {
        // we want to warn the user if they are deleting a large tile layer
        //
        NSURL *tileSetURL = [[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKey:@"URL"];
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[tileSetURL relativePath] error:NULL];
        
        if ([[attributes objectForKey:NSFileSize] unsignedLongLongValue] >= (1024 * 1024 * 100)) // 100MB+
        {
            self.indexPathToDelete = indexPath;
            
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Delete Layer?"
                                                             message:@"This is a large layer file. Are you sure that you want to delete it permanently?"
                                                            delegate:self
                                                   cancelButtonTitle:@"Don't Delete"
                                                   otherButtonTitles:@"Delete", nil] autorelease];
            
            [alert show];
            
            [TESTFLIGHT passCheckpoint:@"user warned about deleting large layer"];
            
            return;
        }
    }
    
    [self.layerManager deleteLayerAtIndexPath:indexPath];
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark -

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.selectedBackgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
    cell.selectedBackgroundView.backgroundColor = kMapBoxBlue;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *layer = nil;
    
    if (indexPath.section == DSMapBoxLayerSectionTile)
        layer = [self.layerManager.tileLayers objectAtIndex:indexPath.row];
    
    else if (indexPath.section == DSMapBoxLayerSectionData)
        layer = [self.layerManager.dataLayers objectAtIndex:indexPath.row];
    
    if (layer && ([[layer objectForKey:@"URL"] isEqual:kDSOpenStreetMapURL] || [[layer objectForKey:@"URL"] isEqual:kDSMapQuestOSMURL] || [[layer objectForKey:@"URL"] isTileStreamURL]))
    {        
        if ( ! [[layer valueForKey:@"selected"] boolValue] && [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
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
    
    if (indexPath.section == DSMapBoxLayerSectionTile)
    {
        NSArray *layers;
        
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
                
                [TESTFLIGHT passCheckpoint:@"user warned about out-of-zoom layer"];
                
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
    
    NSDictionary *layer = nil;
    
    switch (indexPath.section)
    {
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
    
    [TESTFLIGHT passCheckpoint:@"tapped layer crosshairs to zoom"];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        [self.layerManager deleteLayerAtIndexPath:self.indexPathToDelete];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.indexPathToDelete] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [self tableView:self.tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:self.indexPathToDelete];
        
        [TESTFLIGHT passCheckpoint:@"confirmed layer deletion"];
    }
}

@end