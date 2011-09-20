//
//  DSMapBoxDownloadViewController.m
//  MapBoxiPad
//
//  Created by Justin Miller on 8/16/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDownloadViewController.h"

#import "DSMapBoxDownloadManager.h"
#import "DSMapBoxDownloadTableViewCell.h"
#import "DSMapBoxTintedBarButtonItem.h"

#import "ASIHTTPRequest.h"

#import "SSPieProgressView.h"

@interface DSMapBoxDownloadViewController (DSMapBoxDownloadViewControllerPrivate)

- (void)reloadTableView;

@end

#pragma mark -

@implementation DSMapBoxDownloadViewController

- (void)viewDidLoad
{
    [self reloadTableView];
    
    self.navigationItem.title = @"Downloads";
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                            target:self
                                                                                            action:@selector(editButtonTapped:)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadTableView];
}

- (void)dealloc
{
    for (int i = 0; i < [self.tableView numberOfRowsInSection:0]; i++)
        [[self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]] release];
    
    [super dealloc];
}

#pragma mark -

- (void)reloadTableView
{
    [self.tableView reloadData];
    
    self.contentSizeForViewInPopover = CGSizeMake(self.contentSizeForViewInPopover.width, 200);
    
    if ([self.tableView numberOfRowsInSection:0])
    {
        self.tableView.editing = NO;
        
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                                target:self
                                                                                                action:@selector(editButtonTapped:)] autorelease];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark -

- (void)editButtonTapped:(id)sender
{
    self.tableView.editing = YES;
    
    self.navigationItem.rightBarButtonItem = [[[DSMapBoxTintedBarButtonItem alloc] initWithTitle:@"Done" 
                                                                                          target:self
                                                                                          action:@selector(doneButtonTapped:)] autorelease];
}

- (void)doneButtonTapped:(id)sender
{
    self.tableView.editing = NO;
    
    if ([self.tableView numberOfRowsInSection:0])
    {
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                                target:self
                                                                                                action:@selector(editButtonTapped:)] autorelease];
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [((DSMapBoxDownloadManager *)[DSMapBoxDownloadManager sharedManager]).downloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ASIHTTPRequest *request = (ASIHTTPRequest *)[((DSMapBoxDownloadManager *)[DSMapBoxDownloadManager sharedManager]).downloads objectAtIndex:indexPath.row];
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxDownloadTableViewCell" owner:self options:nil];
    
    DSMapBoxDownloadTableViewCell *cell = [(DSMapBoxDownloadTableViewCell *)[nib objectAtIndex:0] retain];
    
    NSURL *downloadURL = request.originalURL;
    
    if ( ! downloadURL)
        downloadURL = request.url;
    
    cell.primaryLabel.text   = [downloadURL lastPathComponent];
    cell.secondaryLabel.text = [downloadURL host];
    
    request.downloadProgressDelegate = cell.pie;
    
    [request updateDownloadProgress];
    
    cell.isPaused = ! request.inProgress;
    
    return (UITableViewCell *)cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSMapBoxDownloadManager *manager = [DSMapBoxDownloadManager sharedManager];
    
    ASIHTTPRequest *request = (ASIHTTPRequest *)[manager.downloads objectAtIndex:indexPath.row];
    
    [manager cancelDownload:request];
    
    [self reloadTableView];
}

#pragma mark -

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Cancel";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSMapBoxDownloadManager *manager = [DSMapBoxDownloadManager sharedManager];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    ASIHTTPRequest *request = (ASIHTTPRequest *)[manager.downloads objectAtIndex:indexPath.row];

    if (request.inProgress)
        [manager pauseDownload:request];

    else
        [manager resumeDownload:request];
    
    [self reloadTableView];
}

@end