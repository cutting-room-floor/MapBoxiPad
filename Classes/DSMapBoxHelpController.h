//
//  DSMapBoxHelpController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 12/7/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import <MediaPlayer/MediaPlayer.h>

@interface DSMapBoxHelpController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UIButton *moviePlayButton;
@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;
@property (nonatomic, retain) IBOutlet UITableView *helpTableView;
@property (nonatomic, retain) IBOutlet UILabel *versionInfoLabel;

- (IBAction)tappedVideoButton:(id)sender;

@end
