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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Base Layer";

        case 1:
            return [self tableView:tableView numberOfRowsInSection:section] ? @"Tile Layers" : nil;
            
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
            return 1;
            
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
            cell.accessoryType  = UITableViewCellAccessoryCheckmark;
            cell.textLabel.text = [[DSMapBoxTileSetManager defaultManager] activeTileSetName];
            
            break;
            
        case 1:
            cell.accessoryType        = ([[[layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
            cell.textLabel.text       = [[layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"name"];
            cell.detailTextLabel.text = [[layerManager.tileLayers objectAtIndex:indexPath.row] valueForKeyPath:@"description"];
            
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
        case 2:
            return YES;
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
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) // base tiles
    {
        // TODO: hide popover & switch tileset
        
        /*
        if ([[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:[tableView cellForRowAtIndexPath:indexPath].textLabel.text])
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:DSMapBoxTileSetChangedNotification object:nil]];
        */
    }
    else
    {
        [layerManager toggleLayerAtIndexPath:indexPath];
        
        [self.tableView reloadData];
    }
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