//
//  DSMapBoxLayerController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerController.h"

#import "MapBoxAppDelegate.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxLayerManager.h"
#import "DSMapBoxMarkerManager.h"
#import "RMMapView.h"

#import "Reachability.h"

@interface DSMapBoxLayerController (DSMapBoxLayerControllerPrivate)

- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath;

@end

#pragma mark -

@implementation DSMapBoxLayerController

@synthesize layerManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Layers";
    
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
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done" 
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(tappedDoneButton:)] autorelease];

    self.tableView.editing = YES;
}

- (IBAction)tappedDoneButton:(id)sender
{
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Edit" 
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self
                                                                              action:@selector(tappedEditButton:)] autorelease];
    
    self.tableView.editing = NO;
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

    [layerManager toggleLayerAtIndexPath:indexPath zoomingIfNecessary:YES];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    [self.tableView cellForRowAtIndexPath:indexPath].accessoryView = nil;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    NSArray *layers;
    
    switch (indexPath.section)
    {
        case 0:
            layers = layerManager.baseLayers;
            break;
            
        case 1:
            layers = layerManager.tileLayers;
            break;
            
        case 2:
            layers = layerManager.dataLayers;
            break;
    }
            
    cell.accessoryType = ([[[layers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
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
        case 0:
            return @"Base Layers";

        case 1:
            return [self tableView:tableView numberOfRowsInSection:section] ? @"Overlay Layers" : nil;
            
        case 2:
            return [self tableView:tableView numberOfRowsInSection:section] ? @"Data Layers" : nil;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return layerManager.baseLayerCount;
            
        case 1:
            return layerManager.tileLayerCount;

        case 2:
            return layerManager.dataLayerCount;
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
        case 0:
            cell.accessoryType        = ([[[layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
            cell.textLabel.text       = [[layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"name"];
            cell.detailTextLabel.text = [[layerManager.baseLayers objectAtIndex:indexPath.row] valueForKeyPath:@"description"];
            cell.imageView.image      = [UIImage imageNamed:@"mbtiles.png"];
            
            break;
            
        case 1:
            cell.accessoryType        = ([[[layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
            cell.textLabel.text       = [[layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"name"];
            cell.detailTextLabel.text = [[layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"description"];
            cell.imageView.image      = [UIImage imageNamed:@"mbtiles.png"];
            
            break;
            
        case 2:
            cell.accessoryType        = ([[[layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
            cell.textLabel.text       = [[layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"name"];
            cell.detailTextLabel.text = [[layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"description"];
            cell.imageView.image      = [UIImage imageNamed:([[[layerManager.dataLayers objectAtIndex:indexPath.row] valueForKeyPath:@"type"] intValue] == DSMapBoxLayerTypeKML ? @"kml.png" : @"rss.png")];
            
            break;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
            return NO;
            
        case 1:
        case 2:
            return YES;
    }
    
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
            return NO;
            
        case 1:
            return YES;
            
        case 2:
            return ! ((DSMapBoxMarkerManager *)layerManager.baseMapView.contents.markerManager).clusteringEnabled;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [layerManager moveLayerAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [layerManager archiveLayerAtIndexPath:indexPath];
    
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    
    [self tappedDoneButton:self];
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[tableView cellForRowAtIndexPath:indexPath].textLabel.text isEqual:kDSOpenStreetMapURL])
    {
        if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];

            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                             message:[NSString stringWithFormat:@"%@ tiles require an active internet connection.", kDSOpenStreetMapURL]
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil] autorelease];

            [alert show];
            
            return;
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

@end