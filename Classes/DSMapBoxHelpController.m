    //
//  DSMapBoxHelpController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 12/7/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxHelpController.h"

#import "MapBoxConstants.h"

@implementation DSMapBoxHelpController

@synthesize moviePlayButton;
@synthesize moviePlayer;
@synthesize helpTableView;
@synthesize versionInfoLabel;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.helpTableView.backgroundView  = nil;
    self.helpTableView.tableFooterView = versionInfoLabel;
    self.versionInfoLabel.text = [NSString stringWithFormat:@"MapBox %@.%@", 
                                     [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                     [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByReplacingOccurrencesOfString:@"." withString:@""]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:MPMoviePlayerPlaybackDidFinishNotification 
                                                  object:nil];
    
    [moviePlayer stop];
    
    [moviePlayButton release];
    [moviePlayer release];
    [helpTableView release];
    [versionInfoLabel release];
    
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -

- (IBAction)tappedVideoButton:(id)sender
{
    if ( ! self.moviePlayer)
    {
        NSURL *movieURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"intro" ofType:@"mov"]];
        
        self.moviePlayer = [[[MPMoviePlayerController alloc] initWithContentURL:movieURL] autorelease];
        
        self.moviePlayer.view.frame = self.moviePlayButton.frame;
        [self.view insertSubview:self.moviePlayer.view aboveSubview:self.moviePlayButton];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(movieDidFinish:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:self.moviePlayer];
    }

    [self.moviePlayer play];
}

- (void)tappedHelpDoneButton:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (void)movieDidFinish:(NSNotification *)notification
{
    if (self.moviePlayer.fullscreen)
        [self.moviePlayer setFullscreen:NO animated:YES];
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *HelpCellIdentifier = @"HelpCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HelpCellIdentifier];
    
    if ( ! cell)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:HelpCellIdentifier] autorelease];
    
    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = @"Contact Support";
            break;
        
        case 1:
            cell.textLabel.text = @"View Release Notes";
            break;

        case 2:
            cell.textLabel.text = @"About MapBox";
            break;
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIAlertView *alert;
    
    switch (indexPath.row)
    {
        case 0:
            // open delayed to avoid button press glitches
            //
            [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                                    withObject:[NSURL URLWithString:kSupportLink]
                                                    afterDelay:0.25];

            break;
            
        case 1:
            // open delayed to avoid button press glitches
            //
            [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                                    withObject:[NSURL URLWithString:kReleaseNotes]
                                                    afterDelay:0.25];
            
            break;
            
        case 2:
            alert = [[[UIAlertView alloc] initWithTitle:@"About MapBox"
                                                message:[NSString stringWithFormat:@"%@\n\n%@", 
                                                         self.versionInfoLabel.text, 
                                                         [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"txt"]
                                                                                   encoding:NSUTF8StringEncoding
                                                                                      error:NULL]]
                                               delegate:nil
                                      cancelButtonTitle:nil
                                      otherButtonTitles:@"OK", nil] autorelease];
            
            [alert show];
            
            break;
    }
}

@end