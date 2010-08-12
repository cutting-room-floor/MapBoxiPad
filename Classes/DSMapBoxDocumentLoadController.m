//
//  DSMapBoxDocumentLoadController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDocumentLoadController.h"

#import "DSAlertView.h"
#import "DSMapBoxLargeSnapshotView.h"

#import "UIApplication_Additions.h"

@interface DSMapBoxDocumentLoadController (DSMapBoxDocumentLoadControllerPrivate)

- (void)reload;
- (NSString *)saveFolderPath;
- (NSArray *)saveFiles;

@end

#pragma mark -

@implementation DSMapBoxDocumentLoadController

@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.jpg"]];
    
    [self reload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark -

- (void)reload
{
    // iterate documents
    //
    NSMutableArray *documentViews = [NSMutableArray array];

    for (NSString *saveFile in [self saveFiles])
    {
        // get snapshot
        //
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [self saveFolderPath], saveFile]];
        UIImage *snapshot  = [UIImage imageWithData:[data objectForKey:@"mapSnapshot"]];
        
        // create & add snapshot view
        //
        [documentViews addObject:[[[DSMapBoxLargeSnapshotView alloc] initWithSnapshot:snapshot] autorelease]];
    }

    // assign snapshots to scroll view
    //
    scroller.documentViews = documentViews;
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

#pragma mark -

- (IBAction)tappedTrashButton:(id)sender
{
    DSAlertView *alert = [[[DSAlertView alloc] initWithTitle:@"Delete Saved Map?"
                                                     message:[NSString stringWithFormat:@"Are you sure that you want to delete the '%@' saved map?", nameLabel.text]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Delete", nil] autorelease];
    
    alert.contextInfo = nameLabel.text;
    
    [alert show];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        NSString *saveFilePath = [NSString stringWithFormat:@"%@/%@.plist", [self saveFolderPath], ((DSAlertView *)alertView).contextInfo];
        
        [[NSFileManager defaultManager] removeItemAtPath:saveFilePath error:NULL];
        
        [self reload];
    }
}

#pragma mark -

- (void)documentScrollView:(DSMapBoxDocumentScrollView *)scrollView didScrollToIndex:(NSUInteger)index
{
    self.title = [NSString stringWithFormat:@"My Maps (%i of %i)", index + 1, [[self saveFiles] count]];

    nameLabel.text = [[[self saveFiles] objectAtIndex:index] stringByReplacingOccurrencesOfString:@".plist" withString:@""];
        
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@", [self saveFolderPath], [[self saveFiles] objectAtIndex:index]] error:NULL];
        
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    dateLabel.text = [dateFormatter stringFromDate:[attributes objectForKey:NSFileModificationDate]];
}

- (void)documentScrollView:(DSMapBoxDocumentScrollView *)scrollView didTapItemAtIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(documentLoadController:didLoadDocumentWithName:)])
        [self.delegate documentLoadController:self didLoadDocumentWithName:[[[self saveFiles] objectAtIndex:index] stringByReplacingOccurrencesOfString:@".plist" withString:@""]];
}

@end