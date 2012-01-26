//
//  DSMapBoxShareSheet.m
//  MapBoxiPad
//
//  Created by Justin Miller on 1/17/12.
//  Copyright (c) 2012 Development Seed. All rights reserved.
//

#import "DSMapBoxShareSheet.h"

#import <MessageUI/MessageUI.h>
#import <Twitter/Twitter.h>

@implementation DSMapBoxShareSheet

+ (id)shareSheetForImageHandler:(UIImage *(^)(void))imageHandler withViewController:(UIViewController *)viewController
{
    DSMapBoxShareSheet *sheet = [DSMapBoxShareSheet actionSheetWithTitle:nil];

    if (sheet)
    {
        // mail action
        //
        [sheet addButtonWithTitle:@"Email Snapshot" handler:^(void)
        {
            if ( ! [MFMailComposeViewController canSendMail])
            {
                [UIAlertView showAlertViewWithTitle:@"Mail Not Setup"
                                            message:@"Please setup Mail in order to send a snapshot."
                                  cancelButtonTitle:nil
                                  otherButtonTitles:[NSArray arrayWithObject:@"OK"]
                                            handler:nil];
            }
            else
            {
                MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];

                [mailer setSubject:@""];
                [mailer setMessageBody:@"<p>&nbsp;</p><p>Powered by <a href=\"http://mapbox.com\">MapBox</a></p>" isHTML:YES];

                [mailer addAttachmentData:UIImageJPEGRepresentation(imageHandler(), 1.0)                       
                                 mimeType:@"image/jpeg" 
                                 fileName:@"MapBoxSnapshot.jpg"];

                // manual copy from DSMapBoxMailComposeViewController due to BlocksKit runtime weirdness
                //
                mailer.modalPresentationStyle = UIModalPresentationPageSheet;
                
                mailer.navigationBar.barStyle = UIBarStyleBlack;
                
                mailer.visibleViewController.navigationItem.rightBarButtonItem.style     = UIBarButtonItemStyleBordered;
                mailer.visibleViewController.navigationItem.rightBarButtonItem.tintColor = kMapBoxBlue;
                //
                // end copy from DSMapBoxMailComposeViewController
                
                mailer.completionBlock = ^(MFMailComposeViewController *mailer, MFMailComposeResult result, NSError *error)
                {
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
                };
                
                [viewController presentModalViewController:mailer animated:YES];
            }
        }];
        
        // tweet action
        //
        [sheet addButtonWithTitle:@"Tweet Snapshot" handler:^(void)
        {
            if ( ! [TWTweetComposeViewController canSendTweet])
            {
                [UIAlertView showAlertViewWithTitle:@"Twitter Not Setup"
                                            message:@"Please setup a Twitter account in order to tweet a snapshot."
                                  cancelButtonTitle:nil
                                  otherButtonTitles:[NSArray arrayWithObject:@"OK"]
                                            handler:nil];
            }
            else
            {
                TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
                
                [tweetSheet addImage:imageHandler()];
                
                tweetSheet.completionHandler = ^(TWTweetComposeViewControllerResult result)
                {
                    if (result == TWTweetComposeViewControllerResultDone)
                        [TESTFLIGHT passCheckpoint:@"shared snapshot by Twitter"];

                    [viewController dismissModalViewControllerAnimated:YES];
                };
                
                [viewController presentModalViewController:tweetSheet animated:YES];
            }
        }];

        // save image action
        //
        [sheet addButtonWithTitle:@"Save Snapshot" handler:^(void)
        {
            UIImageWriteToSavedPhotosAlbum(imageHandler(), nil, nil, nil);
            
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
        }];
        
        sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    }
    
    return sheet;
}

@end