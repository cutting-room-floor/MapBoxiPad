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

@interface DSMapBoxHelpController : UIViewController <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>
{
    UIButton *moviePlayButton;
    MPMoviePlayerController *moviePlayer;
    UITableView *helpTableView;
    UILabel *versionInfoLabel;
}

@property (nonatomic, retain) IBOutlet UIButton *moviePlayButton;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) IBOutlet UITableView *helpTableView;
@property (nonatomic, retain) IBOutlet UILabel *versionInfoLabel;

- (IBAction)tappedVideoButton:(id)sender;
- (void)tappedEmailSupportButton:(id)sender;

@end
