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

#import "MapBoxAppDelegate.h"

#import "SSPieProgressView.h"

@interface DSMapBoxDownloadViewController ()

@property (nonatomic, strong) UIBarButtonItem *editButton;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

- (void)reloadTableView;
- (void)downloadProgressUpdated:(NSNotification *)notification;

@end

#pragma mark -

@implementation DSMapBoxDownloadViewController

@synthesize editButton;
@synthesize doneButton;

- (void)viewDidLoad
{
    [self reloadTableView];
    
    self.navigationItem.title = @"Downloads";
    
    self.editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                    target:self
                                                                    action:@selector(editButtonTapped:)];

    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                       style:UIBarButtonItemStyleBordered
                                                      target:self
                                                      action:@selector(doneButtonTapped:)
                                                   tintColor:kMapBoxBlue];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                          target:self
                                                                                          action:@selector(promptForURL:)
                                                                                       tintColor:kMapBoxBlue];
    
    self.navigationItem.rightBarButtonItem = self.editButton;
    
    // watch for download queue
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadQueueChanged:)
                                                 name:DSMapBoxDownloadQueueNotification
                                               object:nil];
    
    // watch for download progress
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadProgressUpdated:)
                                                 name:DSMapBoxDownloadProgressNotification
                                               object:nil];
    
    // watch for download completion
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadCompleted:)
                                                 name:DSMapBoxDownloadCompleteNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self reloadTableView];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxDownloadQueueNotification    object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxDownloadProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxDownloadCompleteNotification object:nil];
}

#pragma mark -

- (void)reloadTableView
{
    [self.tableView reloadData];
    
    self.contentSizeForViewInPopover = CGSizeMake(self.contentSizeForViewInPopover.width, 200);
    
    if ([self.tableView numberOfRowsInSection:0] != 0)
    {
        self.tableView.editing = NO;
        
        self.navigationItem.rightBarButtonItem = self.editButton;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark -

- (void)downloadQueueChanged:(NSNotification *)notification
{
    [self reloadTableView];
}

- (void)downloadProgressUpdated:(NSNotification *)notification
{
    if ( ! [[notification object] isEqual:[DSMapBoxDownloadManager sharedManager]])
    {
        NSURLConnection *download = [notification object];
        
        if ( ! download.isPaused)
        {
            CGFloat progress = [[[notification userInfo] objectForKey:DSMapBoxDownloadProgressKey] floatValue];
            
            NSUInteger totalDownloaded = [[[notification userInfo] objectForKey:DSMapBoxDownloadTotalDownloadedKey] unsignedIntegerValue];
            NSUInteger totalSize       = [[[notification userInfo] objectForKey:DSMapBoxDownloadTotalSizeKey]       unsignedIntegerValue];
            
            NSString *totalDownloadedString = [NSString stringWithFormat:@"%i", (totalDownloaded / (1024 * 1024))];
            NSString *totalSizeString       = (download.isIndeterminate ? @"?" : [NSString stringWithFormat:@"%i", (totalSize / (1024 * 1024))]);
            
            int row = [[DSMapBoxDownloadManager sharedManager].downloads indexOfObject:download];
            
            DSMapBoxDownloadTableViewCell *cell = (DSMapBoxDownloadTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            
            cell.progress = progress;
            
            cell.secondaryLabel.text = [NSString stringWithFormat:@"%@ (%@ of %@ MB)", [download.originalRequest.URL host], totalDownloadedString, totalSizeString];
        }
    }
}

- (void)downloadCompleted:(NSNotification *)notification
{
    [self performBlock:^(id sender) { [self reloadTableView]; } afterDelay:1.0];
}

#pragma mark -

- (void)promptForURL:(id)sender
{
    __weak UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Download MBTiles" message:@"Enter an MBTiles file URL:"];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    [alert setCancelButtonWithTitle:@"Cancel" handler:nil];

    [alert addButtonWithTitle:@"Download" handler:^(void)
    {
        NSURL *downloadURL = [NSURL URLWithString:[alert textFieldAtIndex:0].text];
        
        NSString *errorMessage;
        
        if ( ! downloadURL || ! [[[downloadURL pathExtension] lowercaseString] isEqualToString:@"mbtiles"])
            errorMessage = @"Please enter a valid MBTiles URL.";
        
        else if ( ! [[[downloadURL scheme] lowercaseString] hasPrefix:@"http"] && ! [[[downloadURL scheme] lowercaseString] hasPrefix:kMBTilesURLSchemePrefix])
            errorMessage = [NSString stringWithFormat:@"Unable to download a URL starting with %@://.", [downloadURL scheme]];

        if (errorMessage)
            [UIAlertView showAlertViewWithTitle:@"Download Error"
                                        message:errorMessage
                              cancelButtonTitle:@"Try Again" 
                              otherButtonTitles:nil
                                        handler:^(UIAlertView *alert, NSInteger buttonIndex) { [self promptForURL:self]; }];

        else
            [((MapBoxAppDelegate *)[[UIApplication sharedApplication] delegate])  openExternalURL:downloadURL];
    }];
    
    [alert show];
}

- (void)editButtonTapped:(id)sender
{
    self.tableView.editing = YES;
    
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)doneButtonTapped:(id)sender
{
    [self reloadTableView];
}

#pragma mark -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[DSMapBoxDownloadManager sharedManager].downloads count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"DSMapBoxDownloadTableViewCell" owner:self options:nil];
    
    DSMapBoxDownloadTableViewCell *cell = (DSMapBoxDownloadTableViewCell *)[nib objectAtIndex:0];
    
    DSMapBoxDownloadManager *manager = [DSMapBoxDownloadManager sharedManager];
    
    NSURLConnection *download = [manager.downloads objectAtIndex:indexPath.row];
    
    cell.primaryLabel.text   = [download.originalRequest.URL lastPathComponent];
    cell.secondaryLabel.text = [NSString stringWithFormat:@"%@%@", [download.originalRequest.URL host], (download.isPaused ? @" (paused)" : @"")];

    cell.primaryLabel.highlightedTextColor   = [UIColor whiteColor];
    cell.secondaryLabel.highlightedTextColor = [UIColor whiteColor];
    
    cell.isIndeterminate = download.isIndeterminate;
    cell.isPaused        = download.isPaused;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        DSMapBoxDownloadManager *manager = [DSMapBoxDownloadManager sharedManager];
        
        NSURLConnection *download = [manager.downloads objectAtIndex:indexPath.row];
        
        [manager cancelDownload:download];
        
        [self reloadTableView];
    }
}

#pragma mark -

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Cancel";
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    cell.selectedBackgroundView.backgroundColor = kMapBoxBlue;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DSMapBoxDownloadManager *manager = [DSMapBoxDownloadManager sharedManager];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSURLConnection *download = [manager.downloads objectAtIndex:indexPath.row];

    if (((DSMapBoxDownloadTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).isPaused)
        [manager resumeDownload:download];

    else
        [manager pauseDownload:download];

    [self reloadTableView];
}

@end