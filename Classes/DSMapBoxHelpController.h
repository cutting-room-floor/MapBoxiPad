//
//  DSMapBoxHelpController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 12/7/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MessageUI.h>
#import <MediaPlayer/MediaPlayer.h>

@interface DSMapBoxHelpController : UIViewController <MFMailComposeViewControllerDelegate>
{
    BOOL shouldPlayImmediately;
    UIButton *moviePlayButton;
    MPMoviePlayerController *moviePlayer;
}

@property (nonatomic, assign) BOOL shouldPlayImmediately;
@property (nonatomic, retain) IBOutlet UIButton *moviePlayButton;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;

- (IBAction)tappedVideoButton:(id)sender;
- (IBAction)tappedEmailSupportButton:(id)sender;

@end
