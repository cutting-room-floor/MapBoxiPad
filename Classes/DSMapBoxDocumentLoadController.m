//
//  DSMapBoxDocumentLoadController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDocumentLoadController.h"

#import "DSAlertView.h"

#import "UIApplication_Additions.h"

@interface DSMapBoxDocumentLoadController (DSMapBoxDocumentLoadControllerPrivate)

- (void)reload;

@end

#pragma mark -

@implementation DSMapBoxDocumentLoadController

@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self reload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark -

- (void)reload
{
    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *saveFolderPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDSSaveFolderName];
    
    NSArray *saveFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:saveFolderPath error:NULL];
    
    NSUInteger count = 0;
    
    for (NSString *saveFile in saveFiles)
    {
        // get snapshot
        //
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", saveFolderPath, saveFile]];
        UIImage *snapshot  = [UIImage imageWithData:[data objectForKey:@"mapSnapshot"]];
        
        // add image view
        //
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:snapshot] autorelease];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:imageView];
        imageView.frame = CGRectMake(20, 20 + count * 60, 50, 50);
        
        // strip extension
        //
        saveFile = [saveFile stringByReplacingOccurrencesOfString:@".plist" withString:@""];
        
        // add load button
        //
        UIButton *loadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [loadButton addTarget:self action:@selector(tappedLoadButton:) forControlEvents:UIControlEventTouchUpInside];
        [loadButton setTitle:saveFile forState:UIControlStateNormal];
        [self.view addSubview:loadButton];
        loadButton.frame = CGRectMake(90, 20 + count * 60, 200, 50);
        
        // add trash button
        //
        UIButton *trashButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [trashButton addTarget:self action:@selector(tappedTrashButton:) forControlEvents:UIControlEventTouchUpInside];
        [trashButton setTitle:saveFile forState:UIControlStateDisabled];
        [trashButton setImage:[UIImage imageNamed:@"trash.png"] forState:UIControlStateNormal];
        [self.view addSubview:trashButton];
        trashButton.frame = CGRectMake(310, 20 + count * 60, 50, 50);
        
        // add last modified stamp
        //
        UILabel *dateLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@.plist", saveFolderPath, saveFile];
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL];
        dateLabel.text = [[attributes objectForKey:NSFileModificationDate] description];
        [self.view addSubview:dateLabel];
        dateLabel.frame = CGRectMake(380, 20 + count * 60, 250, 50);
        
        count++;
    }
}

- (void)tappedLoadButton:(id)sender
{
    [self.delegate documentLoadController:self didLoadDocumentWithName:((UIButton *)sender).titleLabel.text];
}

- (void)tappedTrashButton:(id)sender
{
    DSAlertView *alert = [[[DSAlertView alloc] initWithTitle:@"Delete Saved Map?"
                                                     message:[NSString stringWithFormat:@"Are you sure that you want to delete the '%@' saved map?", [(UIButton *)sender titleForState:UIControlStateDisabled]]
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Delete", nil] autorelease];
    
    alert.contextInfo = [(UIButton *)sender titleForState:UIControlStateDisabled];
    
    [alert show];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        NSString *saveFolderPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDSSaveFolderName];
        NSString *saveFilePath = [NSString stringWithFormat:@"%@/%@.plist", saveFolderPath, ((DSAlertView *)alertView).contextInfo];
        
        [[NSFileManager defaultManager] removeItemAtPath:saveFilePath error:NULL];
        
        [self reload];
    }
}

@end