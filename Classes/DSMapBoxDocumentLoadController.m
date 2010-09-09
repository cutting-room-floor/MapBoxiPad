//
//  DSMapBoxDocumentLoadController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDocumentLoadController.h"

#import "UIApplication_Additions.h"

@interface DSMapBoxDocumentLoadController (DSMapBoxDocumentLoadControllerPrivate)

- (void)reload;
- (NSString *)saveFolderPath;
- (NSArray *)saveFiles;
- (void)updateMetadata;

@end

#pragma mark -

@implementation DSMapBoxDocumentLoadController

@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.png"]];
    
    [self reload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark -

- (void)reload
{
    [scroller.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // iterate documents
    //
    for (NSString *saveFile in [self saveFiles])
    {
        // get snapshot
        //
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [self saveFolderPath], saveFile]];
        UIImage *snapshot  = [UIImage imageWithData:[data objectForKey:@"mapSnapshot"]];
        
        // create & add snapshot view
        //
        DSMapBoxLargeSnapshotView *snapshotView = [[[DSMapBoxLargeSnapshotView alloc] initWithSnapshot:snapshot] autorelease];
        snapshotView.snapshotName = saveFile;
        snapshotView.delegate = self;
        [scroller addSubview:snapshotView];
        snapshotView.frame = CGRectMake(kDSDocumentWidth * ([scroller.subviews count] - 1), 0, kDSDocumentWidth, kDSDocumentHeight);
    }
    
    scroller.contentSize = CGSizeMake(kDSDocumentWidth * [scroller.subviews count], kDSDocumentHeight);
    
    [self scrollViewDidScroll:scroller];
}

- (NSString *)saveFolderPath
{
    return [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDSSaveFolderName];
}

- (NSArray *)saveFiles
{
    NSArray *saveFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self saveFolderPath] error:NULL];
    
    return saveFiles;
}

- (void)updateMetadata
{
    if ([[self saveFiles] count])
    {
        CGFloat needle = scroller.contentOffset.x / kDSDocumentWidth;
        
        int index = -1;
        
        if (needle - floorf(needle) < 0.5) // scrolling left
            index = (int)floorf(needle);
        
        else if (ceilf(needle) - needle < 0.5) // scrolling right
            index = (int)ceilf(needle);
        
        if (index < 0 || index >= [[scroller subviews] count])
            return;
        
        self.title = [NSString stringWithFormat:@"My Maps (%i of %i)", index + 1, [[self saveFiles] count]];
        
        NSString *currentFile = [[self saveFiles] objectAtIndex:index];
        
        nameLabel.text = [currentFile stringByReplacingOccurrencesOfString:@".plist" withString:@""];
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:
                                    [NSString stringWithFormat:@"%@/%@", [self saveFolderPath], currentFile] error:NULL];
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        dateLabel.text = [dateFormatter stringFromDate:[attributes objectForKey:NSFileModificationDate]];
        
        noDocsView.hidden   = YES;
        scroller.hidden     = NO;
        actionButton.hidden = NO;
        trashButton.hidden  = NO;
        
        DSMapBoxLargeSnapshotView *oldActiveSnapshot = (DSMapBoxLargeSnapshotView *)[[[scroller subviews] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isActive = YES"]] lastObject];
        
        if ([[scroller subviews] indexOfObject:oldActiveSnapshot] != index)
            oldActiveSnapshot.isActive = NO;
        
        DSMapBoxLargeSnapshotView *newActiveSnapshot = (DSMapBoxLargeSnapshotView *)[[scroller subviews] objectAtIndex:index];
        
        if ( ! newActiveSnapshot.isActive)
            newActiveSnapshot.isActive = YES;
    }
    else
    {
        self.title     = @"My Maps";
        nameLabel.text = @"";
        dateLabel.text = @"";

        noDocsView.hidden   = NO;
        scroller.hidden     = YES;
        actionButton.hidden = YES;
        trashButton.hidden  = YES;
    }
}

#pragma mark -

- (IBAction)tappedSaveNowButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(documentLoadController:wantsToSaveDocumentWithName:)])
    {
        [self.delegate documentLoadController:self wantsToSaveDocumentWithName:@"Saved Map"];

        [self reload];
    }
}

- (IBAction)tappedSendButton:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        // get the current image
        //
        NSUInteger index = scroller.contentOffset.x / kDSDocumentWidth;
        
        NSString *saveFilePath = [NSString stringWithFormat:@"%@/%@", [self saveFolderPath], [[self saveFiles] objectAtIndex:index]];
        
        NSDictionary *saveData = [NSDictionary dictionaryWithContentsOfFile:saveFilePath];
        
        // configure & present mailer
        //
        MFMailComposeViewController *mailer = [[[MFMailComposeViewController alloc] init] autorelease];
        
        mailer.mailComposeDelegate = self;
        
        [mailer setSubject:@""];
        [mailer setMessageBody:@"<p>&nbsp;</p><p>Powered by <a href=\"http://mapbox.com\">MapBox</a></p>" isHTML:YES];

        [mailer addAttachmentData:[saveData objectForKey:@"mapSnapshot"]                       
                         mimeType:@"image/jpeg" 
                         fileName:@"MapBoxSnapshot.jpg"];
                
        mailer.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentModalViewController:mailer animated:YES];
    }
    else
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Mail Not Setup"
                                                         message:@"Please setup Mail before trying to send map snapshots."
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"OK", nil] autorelease];
        
        [alert show];
    }
}

- (IBAction)tappedTrashButton:(id)sender
{
    UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self
                                               cancelButtonTitle:nil
                                          destructiveButtonTitle:@"Delete Map"
                                               otherButtonTitles:nil] autorelease];
    
    [sheet showFromRect:trashButton.bounds inView:trashButton animated:YES];
}

#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        NSUInteger index = scroller.contentOffset.x / kDSDocumentWidth;
        
        NSString *saveFilePath = [NSString stringWithFormat:@"%@/%@", [self saveFolderPath], [[self saveFiles] objectAtIndex:index]];
        
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
}

#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultFailed:
            
            [self dismissModalViewControllerAnimated:NO];
            
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Mail Failed"
                                                             message:@"There was a problem sending the mail. Try again?"
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"Try Again", nil] autorelease];
            
            [alert show];
            
            break;
            
        default:
            
            [self dismissModalViewControllerAnimated:YES];
    }
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
        [self tappedSendButton:self];
}

@end