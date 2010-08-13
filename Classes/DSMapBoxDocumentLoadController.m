//
//  DSMapBoxDocumentLoadController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDocumentLoadController.h"

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
    UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self
                                               cancelButtonTitle:nil
                                          destructiveButtonTitle:@"Delete Map"
                                               otherButtonTitles:nil] autorelease];
    
    UIButton *trashButton = (UIButton *)sender;
    
    [sheet showFromRect:trashButton.bounds inView:trashButton animated:YES];
}

#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        NSString *saveFilePath = [NSString stringWithFormat:@"%@/%@", [self saveFolderPath], [[self saveFiles] objectAtIndex:scroller.index]];
        
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