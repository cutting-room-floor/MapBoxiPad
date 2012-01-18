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
#import "DSMapBoxAlertView.h"
#import "DSMapBoxTileSourceInfiniteZoom.h"
#import "DSMapView.h"

#import "MapBoxAppDelegate.h"

#import "RMMBTilesTileSource.h"
#import "RMTileStreamSource.h"

#import "Reachability.h"

@interface DSMapBoxLayerController ()

@property (nonatomic, readonly, strong) UIButton *crosshairsButton;
@property (nonatomic, strong) NSArray *defaultToolbarItems;
@property (nonatomic, assign) BOOL activeLayerMode;
@property (nonatomic, assign) BOOL bulkDownloadMode;
@property (nonatomic, assign) BOOL bulkDeleteMode;

- (BOOL)layerAtURLShouldShowCrosshairs:(NSURL *)layerURL;
- (NSArray *)selectedIndexPathsInSection:(DSMapBoxLayerSection)section;
- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths;
- (void)toggleLayerAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteLayersAtIndexPaths:(NSArray *)indexPaths;

@end

#pragma mark -

@implementation DSMapBoxLayerController

@synthesize layerManager;
@synthesize delegate;
@synthesize defaultToolbarItems;
@synthesize activeLayerMode;
@synthesize bulkDownloadMode;
@synthesize bulkDeleteMode;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set top bar title & buttons
    //
    self.navigationItem.title = @"Layers";

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                          target:self.delegate
                                                                                          action:@selector(presentAddLayerHelper)
                                                                                       tintColor:kMapBoxBlue];

    // We are always in editing mode, which allows reordering
    // of layers at any time. We use a bulk deletion method
    // for deletion rather than use the built-in table 
    // view swiping way. 
    //
    self.tableView.editing = YES;
    self.tableView.allowsSelection = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
    
    // setup bottom bar download/delete actions
    //
    self.navigationController.toolbarHidden = NO;
    
    self.defaultToolbarItems = [NSArray arrayWithObjects:
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize handler:^(id sender)
                                   {
                                       self.bulkDownloadMode = ! self.bulkDownloadMode;
                                   }],
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace handler:nil],
                                   [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash handler:^(id sender)
                                   {
                                       self.bulkDeleteMode   = ! self.bulkDeleteMode;
                                   }],
                                   nil];
    
    self.toolbarItems = self.defaultToolbarItems;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.layerManager reloadLayersFromDisk];

    [self reloadRowsAtIndexPaths:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.bulkDownloadMode = NO;
    self.bulkDeleteMode   = NO;
}

#pragma mark -

- (UIButton *)crosshairsButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.frame = CGRectMake(0, 0, 44.0, 44.0);
    
    [button setImage:[UIImage imageNamed:@"crosshairs.png"]           forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"crosshairs_highlight.png"] forState:UIControlStateHighlighted];
    
    [button addTarget:self action:@selector(tappedLayerAccessoryButton:event:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)setActiveLayerMode:(BOOL)flag
{
    if (activeLayerMode != flag)
    {
        activeLayerMode = flag;
    
        self.navigationItem.title = (activeLayerMode ? @"Active Layers" : @"Layers");
    
        [self reloadRowsAtIndexPaths:nil];
        
        [TESTFLIGHT passCheckpoint:@"toggled active layer mode"];
    }

    self.tableView.allowsMultipleSelection = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

- (void)setBulkDownloadMode:(BOOL)flag
{
    if (bulkDownloadMode != flag)
    {
        if (flag && [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
        {
            [UIAlertView showAlertViewWithTitle:@"No Internet Connection"
                                        message:@"Downloading layers requires an active internet connection."
                              cancelButtonTitle:nil
                              otherButtonTitles:[NSArray arrayWithObject:@"OK"]
                                        handler:nil];
            
            return;
        }
        
        bulkDownloadMode = flag;
        
        if (bulkDownloadMode)
        {
            if (self.activeLayerMode)
                self.activeLayerMode = NO;
            
            // make sure there is at least one downloadable TileStream layer
            //
            if ( ! [[self.layerManager.tileLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.downloadable = YES"]] count])
            {
                [UIAlertView showAlertViewWithTitle:@"No Downloadable Layers"
                                            message:@"You don't have any offline-capable layers that aren't already downloaded. Try adding some from MapBox Hosting first."
                                  cancelButtonTitle:nil
                                  otherButtonTitles:[NSArray arrayWithObjects:@"OK", @"Show Me", nil]
                                            handler:^(UIAlertView *alertView, NSInteger buttonIndex)
                                            {
                                                if (buttonIndex == alertView.firstOtherButtonIndex + 1)
                                                    [self.delegate presentAddLayerHelper];
                                            }];
                
                return;
            }

            // change toolbar to show cancel & download action buttons
            //
            UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered handler:^(id sender)
                                      {
                                          self.bulkDownloadMode = ! self.bulkDownloadMode;
                                          
                                          self.toolbarItems = self.defaultToolbarItems;
                                      }];

            cancel.width = 100;

            UIBarButtonItem *download = [[UIBarButtonItem alloc] initWithTitle:@"Download" style:UIBarButtonItemStyleBordered handler:^(id sender)
            {
                UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Download Layers?" 
                                                             message:@"Are you sure that you want to download the selected layers? They will be downloaded in the background."];
                
                [alert setCancelButtonWithTitle:@"Cancel" handler:nil];
                
                [alert addButtonWithTitle:@"Download" handler:^(void)
                {
                    for (NSIndexPath *indexPath in [self selectedIndexPathsInSection:DSMapBoxLayerSectionTile])
                    {
                        NSDictionary *layer = [self.layerManager.tileLayers objectAtIndex:indexPath.row];

                        NSString *downloadURLString = [[NSDictionary dictionaryWithContentsOfURL:[layer objectForKey:@"URL"]] objectForKey:@"download"];

                        if (downloadURLString)
                            [((MapBoxAppDelegate *)[[UIApplication sharedApplication] delegate]) openExternalURL:[NSURL URLWithString:downloadURLString]];
                    }

                    self.bulkDownloadMode = NO;
                    
                    [TESTFLIGHT passCheckpoint:@"bulk downloaded layers"];
                }];
                
                [alert show];
            }
            tintColor:kMapBoxBlue];
            
            download.width = 100;
            download.enabled = NO;
            
            self.toolbarItems = [NSArray arrayWithObjects:
                                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace handler:nil],
                                    cancel,
                                    download, 
                                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace handler:nil],
                                    nil];
            
            self.navigationItem.title = @"Choose Layers To Download";
        }
        else
        {
            self.toolbarItems = self.defaultToolbarItems;
            
            self.navigationItem.title = @"Layers";
        }
        
        self.tableView.allowsMultipleSelection = bulkDownloadMode;
        self.tableView.allowsMultipleSelectionDuringEditing = bulkDownloadMode;

        [self reloadRowsAtIndexPaths:nil];
        
        [TESTFLIGHT passCheckpoint:@"toggled bulk download mode"];
    }
}

- (void)setBulkDeleteMode:(BOOL)flag
{
    if (bulkDeleteMode != flag)
    {
        bulkDeleteMode = flag;
    
        if (bulkDeleteMode)
        {
            if (self.activeLayerMode)
                self.activeLayerMode = NO;

            // change toolbar to show cancel & delete action buttons
            //
            UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered handler:^(id sender)
                                      {
                                          self.bulkDeleteMode = ! self.bulkDeleteMode;
                                          
                                          self.toolbarItems = self.defaultToolbarItems;
                                      }];

            cancel.width = 100;

            UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStyleBordered handler:^(id sender)
            {
                NSMutableArray *indexPaths = [NSMutableArray arrayWithArray:[self selectedIndexPathsInSection:DSMapBoxLayerSectionData]];
                
                [indexPaths addObjectsFromArray:[self selectedIndexPathsInSection:DSMapBoxLayerSectionTile]];
                
                // we want to warn the user if they are deleting any large tile layers
                //
                BOOL hasLargeLayer = NO;
                
                for (NSIndexPath *indexPath in indexPaths)
                {
                    if ( ! hasLargeLayer && indexPath.section == DSMapBoxLayerSectionTile)
                    {
                        NSURL *tileSetURL = [[self.layerManager.tileLayers objectAtIndex:indexPath.row] valueForKey:@"URL"];
                        
                        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[tileSetURL relativePath] error:NULL];
                        
                        if ([[attributes objectForKey:NSFileSize] unsignedLongLongValue] >= (1024 * 1024 * 100)) // 100MB+
                            hasLargeLayer = YES;
                    }
                }
                
                if (hasLargeLayer)
                {
                    [UIAlertView showAlertViewWithTitle:@"Delete Large Layers?"
                                                message:@"You are deleting one or more large layers. Are you sure that you want to delete them permanently?"
                                      cancelButtonTitle:@"Don't Delete"
                                      otherButtonTitles:[NSArray arrayWithObject:@"Delete"]
                                                handler:^(UIAlertView *alertView, NSInteger buttonIndex)
                                                {
                                                    if (buttonIndex == alertView.firstOtherButtonIndex)
                                                    {
                                                        [self deleteLayersAtIndexPaths:indexPaths];
                                                        
                                                        [TESTFLIGHT passCheckpoint:@"confirmed large layer deletion"];
                                                    }

                                                    self.bulkDeleteMode = NO;
                                                }];
                    
                    return;
                }
                else
                    [self deleteLayersAtIndexPaths:indexPaths];
                
                self.bulkDeleteMode = NO;
                
                [TESTFLIGHT passCheckpoint:@"bulk deleted layers"];
            }
            tintColor:[UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:1.0]];

            delete.width = 100;
            delete.enabled = NO;
            
            self.toolbarItems = [NSArray arrayWithObjects:
                                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace handler:nil],
                                    cancel,
                                    delete, 
                                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace handler:nil],
                                    nil];
            
            self.navigationItem.title = @"Choose Layers To Delete";
        }
        else
        {
            self.toolbarItems = self.defaultToolbarItems;
            
            self.navigationItem.title = @"Layers";
        }

        self.tableView.allowsMultipleSelection = bulkDeleteMode;
        self.tableView.allowsMultipleSelectionDuringEditing = bulkDeleteMode;

        [self reloadRowsAtIndexPaths:nil];
        
        [TESTFLIGHT passCheckpoint:@"toggled bulk delete mode"];
    }
}

#pragma mark -

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths
{
    // deselect all cells first if not in bulk modes
    //
    if ( ! self.bulkDownloadMode && ! self.bulkDeleteMode)
        for (int i = 0; i < [self.tableView numberOfSections]; i++)
            for (int j = 0; j < [self.tableView numberOfRowsInSection:i]; j++)
                [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:j inSection:i] animated:NO];
    
    // do reloads, all or some
    //
    if (indexPaths)
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    else
        [self.tableView reloadData];

    // update active layers button accordingly
    //
    int count = [[self selectedIndexPathsInSection:DSMapBoxLayerSectionData] count] + [[self selectedIndexPathsInSection:DSMapBoxLayerSectionTile] count];
    
    if (self.bulkDownloadMode || self.bulkDeleteMode || ! count)
        self.navigationItem.rightBarButtonItem = nil;
    else
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:(self.activeLayerMode ? @"Show All" : @"Show Active")
                                                                                  style:UIBarButtonItemStyleBordered
                                                                                handler:^(id sender)
                                                                                {
                                                                                    self.activeLayerMode = ! self.activeLayerMode;
                                                                                }];
}

- (IBAction)tappedLayerAccessoryButton:(id)sender event:(id)event
{
    // first half of the accessory button faking routine
    //
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint  point = [touch locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];

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
    }
    else if ([layerURL isTileStreamURL])
    {
        RMTileStreamSource *source = [[RMTileStreamSource alloc] initWithReferenceURL:layerURL];
        
        if ( ! [source coversFullWorld])
            shouldShowCrosshairs = YES;
    }

    return shouldShowCrosshairs;
}

- (NSArray *)selectedIndexPathsInSection:(DSMapBoxLayerSection)section
{
    NSMutableArray *indexPaths = [NSMutableArray array];

    if (self.bulkDownloadMode || self.bulkDeleteMode)
    {
        // for bulk modes, use true table selection state
        //
        for (int row = 0; row < [self.tableView numberOfRowsInSection:section]; row++)
            if ([self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]].selected)
                [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
    }
    else
    {
        // for layer toggling, use the data model instead
        //
        NSArray *layers;
        
        if (section == DSMapBoxLayerSectionData)
            layers = self.layerManager.dataLayers;
        else
            layers = self.layerManager.tileLayers;
        
        for (int row = 0; row < [layers count]; row++)
            if ([[[layers objectAtIndex:row] objectForKey:@"selected"] boolValue])
                [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
    }
    
    return indexPaths;
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
            cell.editingAccessoryView = self.crosshairsButton;
        }
        else
        {
            cell.editingAccessoryView = nil;
            cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    else
    {
        cell.editingAccessoryView = nil;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    }
    
    // reload this changed row
    //
    [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    
    // if, after toggling, we aren't showing any layers, get out of "active layers" mode
    //
    int count = [[self selectedIndexPathsInSection:DSMapBoxLayerSectionData] count] + [[self selectedIndexPathsInSection:DSMapBoxLayerSectionTile] count];
    
    if (self.activeLayerMode && ! count)
        self.activeLayerMode = NO;
}

- (void)deleteLayersAtIndexPaths:(NSArray *)indexPaths
{
    [self.layerManager deleteLayersAtIndexPaths:indexPaths];

    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:LayerCellIdentifier];
    
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
                    cell.editingAccessoryView = self.crosshairsButton;
                }
                else
                {
                    cell.editingAccessoryView = nil;
                    cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
            else
            {
                cell.editingAccessoryView = nil;
                cell.editingAccessoryType = UITableViewCellAccessoryNone;
            }

            cell.textLabel.text = [layer valueForKey:@"name"];
            
            if (self.bulkDownloadMode && [[layer valueForKey:@"downloadable"] boolValue])
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%qu MB", ([[layer objectForKey:@"filesize"] longLongValue] / (1024 * 1024))];
            else
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
            
            cell.editingAccessoryView = nil;
            cell.editingAccessoryType = [[layer valueForKey:@"selected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            
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
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ! (self.bulkDownloadMode || self.bulkDeleteMode);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.layerManager moveLayerAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    
    [TESTFLIGHT passCheckpoint:@"reordered layers"];
}

#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // hide headers if only TileStream layers shown
    //
    if (self.bulkDownloadMode)
        return 0;
    
    // hide header if section is empty when showing only active layers
    //
    if (self.activeLayerMode && ! [[self selectedIndexPathsInSection:section] count])
        return 0;
    
    return [tableView sectionHeaderHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionLayers = (indexPath.section == DSMapBoxLayerSectionData ? self.layerManager.dataLayers : self.layerManager.tileLayers);
    
    NSDictionary *layer = [sectionLayers objectAtIndex:indexPath.row];
    
    // active layer mode - don't show unselected layers
    //
    if (self.activeLayerMode)
        if ( ! [[layer objectForKey:@"selected"] boolValue])
            return 0;
    
    // bulk download mode - only show downloadable TileStream layers
    //
    if (self.bulkDownloadMode)
        if ( ! [[layer objectForKey:@"URL"] isTileStreamURL] || ! [[layer objectForKey:@"downloadable"] boolValue])
            return 0;
    
    // bulk delete - only show deleteable layers
    //
    if (self.bulkDeleteMode)
        if ([[layer objectForKey:@"URL"] isEqual:kDSOpenStreetMapURL] || [[layer objectForKey:@"URL"] isEqual:kDSMapQuestOSMURL])
            return 0;
            
    return [tableView rowHeight];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // hide certain rows
    //
    NSArray *sectionLayers = (indexPath.section == DSMapBoxLayerSectionData ? self.layerManager.dataLayers : self.layerManager.tileLayers);
    
    NSDictionary *layer = [sectionLayers objectAtIndex:indexPath.row];
    
    // active layer mode - don't show unselected layers
    //
    if (self.activeLayerMode)
        if ( ! [[layer objectForKey:@"selected"] boolValue])
            cell.hidden = YES;
    
    // bulk download mode - only show downloadable TileStream layers
    //
    if (self.bulkDownloadMode)
        if ( ! [[layer objectForKey:@"URL"] isTileStreamURL] || ! [[layer objectForKey:@"downloadable"] boolValue])
            cell.hidden = YES;
    
    // bulk delete - only show deleteable layers
    //
    if (self.bulkDeleteMode)
        if ([[layer objectForKey:@"URL"] isEqual:kDSOpenStreetMapURL] || [[layer objectForKey:@"URL"] isEqual:kDSMapQuestOSMURL])
            cell.hidden = YES;

    // setup selection backgrounds
    //
    if (self.bulkDownloadMode || self.bulkDeleteMode)
    {
        // Mail.app-style multiple selection highlighting
        //
        cell.multipleSelectionBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.multipleSelectionBackgroundView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    }
    else
    {
        // custom-themed highlight selection background
        //
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.selectedBackgroundView.backgroundColor = kMapBoxBlue;
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (self.bulkDownloadMode || self.bulkDeleteMode);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // happens when toggling off in bulk modes - trigger action button updates
    //
    if (self.bulkDownloadMode || self.bulkDeleteMode)
        [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.bulkDownloadMode || self.bulkDeleteMode)
    {
        // just update download/delete button label in bulk modes
        //
        UIBarButtonItem *item = [self.toolbarItems objectAtIndex:2];
        
        NSString *title = [[item.title componentsSeparatedByString:@" "] objectAtIndex:0];

        int count = [[self selectedIndexPathsInSection:DSMapBoxLayerSectionData] count] + [[self selectedIndexPathsInSection:DSMapBoxLayerSectionTile] count];
        
        if (count)
        {
            item.title = [NSString stringWithFormat:@"%@ (%i)", title, count];
            item.enabled = YES;
        }
        else
        {
            item.title = title;
            item.enabled = NO;
        }
        
        return;
    }

    // perform layer toggling actions
    //
    NSDictionary *layer;
    
    if (indexPath.section == DSMapBoxLayerSectionTile)
        layer = [self.layerManager.tileLayers objectAtIndex:indexPath.row];
    
    else if (indexPath.section == DSMapBoxLayerSectionData)
        layer = [self.layerManager.dataLayers objectAtIndex:indexPath.row];
    
    // require net for online layers turning on
    //
    if ([[layer objectForKey:@"URL"] isEqual:kDSOpenStreetMapURL] || [[layer objectForKey:@"URL"] isEqual:kDSMapQuestOSMURL] || [[layer objectForKey:@"URL"] isTileStreamURL])
    {        
        if ( ! [[layer valueForKey:@"selected"] boolValue] && [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
        {
            [UIAlertView showAlertViewWithTitle:@"No Internet Connection"
                                        message:[NSString stringWithFormat:@"%@ requires an active internet connection.", [tableView cellForRowAtIndexPath:indexPath].textLabel.text]
                              cancelButtonTitle:nil
                              otherButtonTitles:[NSArray arrayWithObject:@"OK"]
                                        handler:nil];
            
            return;
        }
    }
    
    // warn when turning on MBTiles layers that are lower than our min zoom
    //
    if (indexPath.section == DSMapBoxLayerSectionTile && [[layer valueForKey:@"URL"] isMBTilesURL] && [[[RMMBTilesTileSource alloc] initWithTileSetURL:[layer valueForKey:@"URL"]] maxZoomNative] < kLowerZoomBounds)
    {
        [UIAlertView showAlertViewWithTitle:@"Unable To Zoom"
                                    message:[NSString stringWithFormat:@"The %@ layer can't zoom out far enough to be displayed. Please contact the layer author and request a file that supports zoom level 3 or higher.", [layer valueForKey:@"name"]]
                          cancelButtonTitle:nil
                          otherButtonTitles:[NSArray arrayWithObject:@"OK"]
                                    handler:nil];
        
        [TESTFLIGHT passCheckpoint:@"user warned about out-of-zoom layer"];
        
        return;
    }
    
    /**
     * In response to potentially long toggle operations, we add a spinner 
     * accessory view & start it animating. Then, we do the actual operation
     * in the next run loop pass, which also takes care of removing the
     * animation and re-setting selected state. 
     */
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.tableView cellForRowAtIndexPath:indexPath].editingAccessoryView = spinner;
    [spinner startAnimating];
    
    [self performSelector:@selector(toggleLayerAtIndexPath:) withObject:indexPath afterDelay:0.0];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    // don't allow dragging out of layer's own section
    //
    if (sourceIndexPath.section < proposedDestinationIndexPath.section)
        return [NSIndexPath indexPathForRow:0 inSection:sourceIndexPath.section];

    else if (sourceIndexPath.section > proposedDestinationIndexPath.section)
        return [NSIndexPath indexPathForRow:([[tableView dataSource] tableView:tableView numberOfRowsInSection:sourceIndexPath.section] - 1) 
                                  inSection:sourceIndexPath.section];
    
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    // we are currently faking this via accessory view button actions
    //
    if (indexPath.section == DSMapBoxLayerSectionTile)
        if (self.delegate && [self.delegate respondsToSelector:@selector(zoomToLayer:)])
            [self.delegate zoomToLayer:[self.layerManager.tileLayers objectAtIndex:indexPath.row]];
    
    [TESTFLIGHT passCheckpoint:@"tapped layer crosshairs to zoom"];
}

@end