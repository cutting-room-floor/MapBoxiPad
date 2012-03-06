//
//  DSMapBoxShareSheet.m
//  MapBoxiPad
//
//  Created by Justin Miller on 1/17/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

#import "DSMapBoxShareSheet.h"

#import "DSMapBoxMailComposeViewController.h"

#import <Twitter/Twitter.h>

@interface DSMapBoxShareSheetDelegate : NSObject <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, copy) UIImage *(^imageCreationBlock)(void);
@property (nonatomic, weak) UIViewController *presentingViewController;

- (id)initWithImageCreationBlock:(UIImage *(^)(void))imageCreationBlock modalForViewController:(UIViewController *)presentingViewController;

@end

#pragma mark -

@implementation DSMapBoxShareSheetDelegate

@synthesize imageCreationBlock=_imageCreationBlock;
@synthesize presentingViewController=_presentingViewController;

- (id)initWithImageCreationBlock:(UIImage *(^)(void))imageCreationBlock modalForViewController:(UIViewController *)presentingViewController
{
    self = [super init];
    
    if (self)
    {
        _imageCreationBlock = imageCreationBlock;
        _presentingViewController = presentingViewController;
    }
    
    return self;
}

#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 0:
        {
            if ( ! [MFMailComposeViewController canSendMail])
            {
                [UIAlertView showAlertViewWithTitle:@"Mail Not Setup"
                                            message:@"Please setup a Mail account in order to send a snapshot."
                                  cancelButtonTitle:nil
                                  otherButtonTitles:[NSArray arrayWithObjects:@"OK", @"Show Me", nil]
                                            handler:^(UIAlertView *alertView, NSInteger buttonIndex)
                                            {
                                                if (buttonIndex == alertView.firstOtherButtonIndex + 1)
                                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=ACCOUNT_SETTINGS"]];
                                            }];
            }
            else
            {
                DSMapBoxMailComposeViewController *mailer = [[DSMapBoxMailComposeViewController alloc] init];
                
                [mailer setSubject:@""];
                [mailer setMessageBody:@"<p>&nbsp;</p><p>Powered by <a href=\"http://mapbox.com\">MapBox</a></p>" isHTML:YES];
                
                [mailer addAttachmentData:UIImageJPEGRepresentation(self.imageCreationBlock(), 1.0)                       
                                 mimeType:@"image/jpeg" 
                                 fileName:@"MapBoxSnapshot.jpg"];
                
                mailer.mailComposeDelegate = self;
                
                [self.presentingViewController presentModalViewController:mailer animated:YES];
            }
            
            break;
        }
        case 1:
        {
            if ( ! [TWTweetComposeViewController canSendTweet])
            {
                [UIAlertView showAlertViewWithTitle:@"Twitter Not Setup"
                                            message:@"Please setup a Twitter account in order to tweet a snapshot."
                                  cancelButtonTitle:nil
                                  otherButtonTitles:[NSArray arrayWithObjects:@"OK", @"Show Me", nil]
                                            handler:^(UIAlertView *alertView, NSInteger buttonIndex)
                                            {
                                                if (buttonIndex == alertView.firstOtherButtonIndex + 1)
                                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
                                            }];
            }
            else
            {
                TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
                
                [tweetSheet addImage:self.imageCreationBlock()];
                
                tweetSheet.completionHandler = ^(TWTweetComposeViewControllerResult result)
                {
                    if (result == TWTweetComposeViewControllerResultDone)
                        [TESTFLIGHT passCheckpoint:@"shared snapshot by Twitter"];
                    
                    [self.presentingViewController dismissModalViewControllerAnimated:YES];
                };
                
                [self.presentingViewController presentModalViewController:tweetSheet animated:YES];
            }
            
            break;
        }
        case 2:
        {
            UIImageWriteToSavedPhotosAlbum(self.imageCreationBlock(), nil, nil, nil);
            
            if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"notifiedSnapshotSave"])
            {
                [UIAlertView showAlertViewWithTitle:@"Snapshot Saved"
                                            message:@"The snapshot was copied to your Saved Photos. In the future, this will happen without a notification." 
                                  cancelButtonTitle:nil
                                  otherButtonTitles:[NSArray arrayWithObject:@"OK"]
                                            handler:nil];
                
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"notifiedSnapshotSave"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }            
            
            [TESTFLIGHT passCheckpoint:@"saved snapshot to camera roll"];
            
            break;
        }
    }
}

#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
    
    if (result == MFMailComposeResultFailed)
    {
        UIAlertView *alert = [UIAlertView alertViewWithTitle:@"Mail Failed" message:@"There was a problem sending the mail."];
        
        [alert addButtonWithTitle:@"OK"];
        
        [alert show];
    }
    else
    {
        [TESTFLIGHT passCheckpoint:@"shared snapshot by mail"];
    }
}

@end

#pragma mark -

@interface DSMapBoxShareSheet ()

@property (nonatomic, strong) id <UIActionSheetDelegate>strongDelegate;

@end

#pragma mark -

@implementation DSMapBoxShareSheet

@synthesize strongDelegate;

+ (id)shareSheetWithImageCreationBlock:(UIImage *(^)(void))imageCreationBlock modalForViewController:(UIViewController *)presentingViewController
{
    DSMapBoxShareSheet *sheet = [[super alloc] init];
    
    if (self)
    {
        sheet.strongDelegate = [[DSMapBoxShareSheetDelegate alloc] initWithImageCreationBlock:imageCreationBlock modalForViewController:presentingViewController];
        
        sheet.delegate = sheet.strongDelegate;
        
        [sheet addButtonWithTitle:@"Email Snapshot"];
        [sheet addButtonWithTitle:@"Tweet Snapshot"];
        [sheet addButtonWithTitle:@"Save Snapshot"];
        
        sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    }
    
    return sheet;
}

@end