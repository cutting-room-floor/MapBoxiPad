//
//  DSMapBoxTileSetChooserController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxTileSetChooserController.h"
#import "DSMapBoxTileSetManager.h"

@implementation DSMapBoxTileSetChooserController

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([[[DSMapBoxTileSetManager defaultManager] activeDownloads] count])
        return 3;
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;
        
        case 1:
            if ([[DSMapBoxTileSetManager defaultManager] tileSetCount] > 1)
                return [[DSMapBoxTileSetManager defaultManager] tileSetCount];

            else
                return 1;

        case 2:
            return [[[DSMapBoxTileSetManager defaultManager] activeDownloads] count];
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return @"Default Tile Set";
        
        case 1:
            return @"Alternate Tile Sets";
        
        case 2:
            return @"Downloads";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TileChooserCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section)
    {
        case 0:
            cell.textLabel.text = [[DSMapBoxTileSetManager defaultManager] defaultTileSetName];

            if ([[DSMapBoxTileSetManager defaultManager] isUsingDefaultTileSet])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                
            break;
            
        case 1:
            if ([[DSMapBoxTileSetManager defaultManager] tileSetCount] > 1 && indexPath.row < [[DSMapBoxTileSetManager defaultManager] tileSetCount] - 1)
            {
                cell.textLabel.text = [[[DSMapBoxTileSetManager defaultManager] tileSetNames] objectAtIndex:indexPath.row + 1];
                
                if ([[[DSMapBoxTileSetManager defaultManager] activeTileSetName] isEqualToString:cell.textLabel.text])
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            
            if (indexPath.row == [[DSMapBoxTileSetManager defaultManager] tileSetCount] - 1)
            {
                cell.textLabel.text = @"Download more tile sets...";
                cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            break;
            
        case 2:
            cell.textLabel.text = [[[DSMapBoxTileSetManager defaultManager] activeDownloads] objectAtIndex:indexPath.row];
            cell.textLabel.textColor = [UIColor lightGrayColor];
            break;
    }
    
    return cell;
}

#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2)
        return [[[DSMapBoxTileSetManager defaultManager] activeDownloads] count] * 44.0;
    
    return 44.0;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2)
        return nil;
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == [tableView numberOfRowsInSection:1] - 1)
    {
        NSLog(@"download more tiles here");
    }
    
    else
        [[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
}

@end