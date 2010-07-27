//
//  DSMapBoxLayerController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerController.h"

@implementation DSMapBoxLayerController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Layers";
}

#pragma mark -

- (IBAction)tappedEditButton:(id)sender
{
    NSLog(@"edit layers");
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
            return @"Tiled Layers";
            
        case 2:
            return @"Data Layers";
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
        case 1:
            return 2;

        case 2:
            return 4;
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
            cell.accessoryType = (indexPath.row == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
            
            break;
            
        case 1:
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.detailTextLabel.text = (indexPath.row == 0 ? @"One thing to show" : @"Another thing to show");
            
            break;
            
        case 2:
            cell.accessoryType = (indexPath.row == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
            cell.imageView.image = [UIImage imageNamed:(indexPath.row % 2 ? @"kml.jpg" : @"rss-icon.jpg")];

            switch (indexPath.row)
            {
                case 0:
                    cell.detailTextLabel.text = @"5 Points, 1 Polygon";

                    break;
                    
                case 1:
                    cell.detailTextLabel.text = @"36 Points";
                    
                    break;
                    
                case 2:
                    cell.detailTextLabel.text = @"17 Points, 4 Lines";
                    
                    break;
                    
                case 3:
                    cell.detailTextLabel.text = @"1 Point";
                    
                    break;
            }
            
            break;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Testing %i, %i", indexPath.section, indexPath.row];
    
    return cell;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSLog(@"%@", indexPath);
}

@end