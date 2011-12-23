//
//  DSMapBoxDocumentLoadController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxDocumentLoadController.h"

#import "UIApplication_Additions.h"

@interface DSMapBoxDocumentLoadController ()

- (void)reload;
- (NSArray *)saveFilesReloadingFromDisk:(BOOL)shouldReloadFromDisk;
- (void)updateMetadata;

@property (nonatomic, strong) NSArray *saveFiles;
@property (nonatomic, strong) UIView *dimmer;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

#pragma mark -

@implementation DSMapBoxDocumentLoadController

@synthesize delegate;
@synthesize noDocsView;
@synthesize scroller;
@synthesize nameLabel;
@synthesize dateLabel;
@synthesize actionButton;
@synthesize trashButton;
@synthesize saveFiles;
@synthesize dimmer;
@synthesize spinner;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.138 green:0.138 blue:0.138 alpha:1.000];
    
    self.saveFiles = [NSArray array];
    
    // put up dimmer & spinner while loading
    //
    self.dimmer = [[UIView alloc] initWithFrame:self.view.frame];
    
    self.dimmer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    
    [self.view addSubview:self.dimmer];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [self.spinner startAnimating];
    
    self.spinner.center = self.dimmer.center;

    [self.dimmer addSubview:self.spinner];

    // prep the UI
    //
    [self updateMetadata];
    
    self.noDocsView.hidden = YES;
    
    self.navigationItem.leftBarButtonItem.enabled = NO;

    // perform the reload
    //
    dispatch_delayed_ui_action(0.0, ^(void) { [self reload]; });
    
    [TESTFLIGHT passCheckpoint:@"viewed document loader"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark -

- (void)reload
{
    [self.scroller.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // iterate documents
    //
    for (NSString *saveFile in [self saveFilesReloadingFromDisk:YES])
    {
        // get snapshot
        //
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[self class] saveFolderPath], [saveFile valueForKey:@"name"]]];
        UIImage *snapshot  = [UIImage imageWithData:[data objectForKey:@"mapSnapshot"]];
        
        // create & add snapshot view
        //
        DSMapBoxLargeSnapshotView *snapshotView = [[DSMapBoxLargeSnapshotView alloc] initWithSnapshot:snapshot];
        snapshotView.snapshotName = [saveFile valueForKey:@"name"];
        snapshotView.delegate = self;
        [self.scroller addSubview:snapshotView];
        snapshotView.frame = CGRectMake(kDSDocumentWidth * ([self.scroller.subviews count] - 1), 0, kDSDocumentWidth, kDSDocumentHeight);
    }
    
    self.scroller.contentSize = CGSizeMake(kDSDocumentWidth * [self.scroller.subviews count], kDSDocumentHeight);
    
    [self scrollViewDidScroll:self.scroller];
    
    // clean up modal UI
    //
    [self.dimmer  removeFromSuperview];
    [self.spinner removeFromSuperview];

    self.navigationItem.leftBarButtonItem.enabled = YES;
}

+ (NSString *)saveFolderPath
{
    return [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPath], kDSSaveFolderName];
}

- (NSArray *)saveFilesReloadingFromDisk:(BOOL)shouldReloadFromDisk
{
    if (shouldReloadFromDisk)
    {
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[self class] saveFolderPath] error:NULL];
        
        NSMutableArray *filesWithDates = [NSMutableArray array];
        
        for (NSString *file in files)
        {
            if ( ! [file hasPrefix:@"."] && [file hasSuffix:@".plist"])
            {
                NSString *path = [NSString stringWithFormat:@"%@/%@", [[self class] saveFolderPath], file];
                NSDate   *date = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL] fileModificationDate];
                
                NSDictionary *fileDictionary = [NSDictionary dictionaryWithObjectsAndKeys:file, @"name", date, @"date", nil];
                
                [filesWithDates addObject:fileDictionary];
            }
        }
        
        [filesWithDates sortUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]];
        
        self.saveFiles = [NSArray arrayWithArray:filesWithDates];
    }
    
    return self.saveFiles;
}

- (void)updateMetadata
{
    if ([[self saveFilesReloadingFromDisk:NO] count])
    {
        CGFloat needle = self.scroller.contentOffset.x / kDSDocumentWidth;
        
        int index = -1;
        
        if (needle - floorf(needle) < 0.5) // scrolling left
            index = (int)floorf(needle);
        
        else if (ceilf(needle) - needle < 0.5) // scrolling right
            index = (int)ceilf(needle);
        
        if (index < 0 || index >= [[self.scroller subviews] count])
            return;
        
        self.title = [NSString stringWithFormat:@"My Maps (%i of %i)", index + 1, [[self saveFilesReloadingFromDisk:NO] count]];
        
        NSString *currentFile = [[self saveFilesReloadingFromDisk:NO] objectAtIndex:index];
        
        self.nameLabel.text = [[currentFile valueForKey:@"name"] stringByReplacingOccurrencesOfString:@".plist" withString:@""];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        self.dateLabel.text = [dateFormatter stringFromDate:[currentFile valueForKey:@"date"]];
        
        self.noDocsView.hidden   = YES;
        self.scroller.hidden     = NO;
        self.actionButton.hidden = NO;
        self.trashButton.hidden  = NO;
        
        DSMapBoxLargeSnapshotView *oldActiveSnapshot = (DSMapBoxLargeSnapshotView *)[[[self.scroller subviews] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isActive = YES"]] lastObject];
        
        if ([[self.scroller subviews] indexOfObject:oldActiveSnapshot] != index)
            oldActiveSnapshot.isActive = NO;
        
        DSMapBoxLargeSnapshotView *newActiveSnapshot = (DSMapBoxLargeSnapshotView *)[[self.scroller subviews] objectAtIndex:index];
        
        if ( ! newActiveSnapshot.isActive)
            newActiveSnapshot.isActive = YES;
    }
    else
    {
        self.title     = @"My Maps";
        self.nameLabel.text = @"";
        self.dateLabel.text = @"";

        self.noDocsView.hidden   = NO;
        self.scroller.hidden     = YES;
        self.actionButton.hidden = YES;
        self.trashButton.hidden  = YES;
    }
}

#pragma mark -

- (IBAction)tappedSaveNowButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(documentLoadController:wantsToSaveDocumentWithName:)])
    {
        [self.delegate documentLoadController:self wantsToSaveDocumentWithName:kDSSaveFileName];

        [self reload];
        
        [TESTFLIGHT passCheckpoint:@"saved document from document load view"];
    }
}

- (IBAction)tappedSendButton:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Email Snapshot", nil];
    
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    sheet.tag = 0;
    
    [sheet showFromRect:self.actionButton.bounds inView:self.actionButton animated:YES];
}

- (IBAction)tappedTrashButton:(id)sender
{
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:@"Delete Map"
                                              otherButtonTitles:nil];
    
    sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    sheet.tag = 1;
    
    [sheet showFromRect:self.trashButton.bounds inView:self.trashButton animated:YES];
}

#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 0 && buttonIndex == actionSheet.firstOtherButtonIndex)
    {
        // email button: compose
        //
        if ([MFMailComposeViewController canSendMail])
        {
            // get the current image
            //
            NSUInteger index = self.scroller.contentOffset.x / kDSDocumentWidth;
            
            NSString *saveFilePath = [NSString stringWithFormat:@"%@/%@", [[self class] saveFolderPath], [[[self saveFilesReloadingFromDisk:NO] objectAtIndex:index] valueForKey:@"name"]];
            
            NSDictionary *saveData = [NSDictionary dictionaryWithContentsOfFile:saveFilePath];
            
            // configure & present mailer
            //
            MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
            
            mailer.mailComposeDelegate = self;
            
            [mailer setSubject:@""];
            [mailer setMessageBody:@"<p>&nbsp;</p><p>Powered by <a href=\"http://mapbox.com\">MapBox</a></p>" isHTML:YES];
            
            [mailer addAttachmentData:[saveData objectForKey:@"mapSnapshot"]                       
                             mimeType:@"image/jpeg" 
                             fileName:@"MapBoxSnapshot.jpg"];
            
            mailer.modalPresentationStyle = UIModalPresentationPageSheet;
            
            [self presentModalViewController:mailer animated:YES];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Not Setup"
                                                            message:@"Please setup Mail before trying to send map snapshots."
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
            
            [alert show];
        }
    }
    else if (actionSheet.tag == 1 && buttonIndex == actionSheet.destructiveButtonIndex)
    {
        // trash button: delete
        //
        NSUInteger index = self.scroller.contentOffset.x / kDSDocumentWidth;
        
        NSString *saveFilePath = [NSString stringWithFormat:@"%@/%@", [[self class] saveFolderPath], [[[self saveFilesReloadingFromDisk:NO] objectAtIndex:index] valueForKey:@"name"]];
        
        [[NSFileManager defaultManager] removeItemAtPath:saveFilePath error:NULL];
        
        [self reload];
    }
}

#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateMetadata];
}

#pragma mark -

- (void)snapshotViewWasTapped:(DSMapBoxLargeSnapshotView *)snapshotView withName:(NSString *)snapshotName
{
    if ([self.delegate respondsToSelector:@selector(documentLoadController:didLoadDocumentWithName:)])
        [self.delegate documentLoadController:self didLoadDocumentWithName:[snapshotName stringByReplacingOccurrencesOfString:@".plist" withString:@""]];
    
    [TESTFLIGHT passCheckpoint:@"loaded saved document"];
}

#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultFailed:
        {
            [self dismissModalViewControllerAnimated:NO];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Mail Failed"
                                                            message:@"There was a problem sending the mail. Try again?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Try Again", nil];
            
            [alert show];
            
            break;
        }
        default:
        {
            [self dismissModalViewControllerAnimated:YES];
            
            [TESTFLIGHT passCheckpoint:@"shared snapshot from document loader"];
        }
    }
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
        [self tappedSendButton:self];
}

@end