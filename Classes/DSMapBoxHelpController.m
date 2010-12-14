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

@synthesize shouldPlayImmediately;
@synthesize moviePlayButton;
@synthesize moviePlayer;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.shouldPlayImmediately)
        [self tappedVideoButton:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:MPMoviePlayerPlaybackDidFinishNotification 
                                                  object:nil];
    
    [moviePlayButton release];
    [moviePlayer release];
    
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

- (IBAction)tappedEmailSupportButton:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[[MFMailComposeViewController alloc] init] autorelease];
        
        mailer.mailComposeDelegate = self;
        
        [mailer setToRecipients:[NSArray arrayWithObject:KSupportEmail]];
        
        mailer.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentModalViewController:mailer animated:YES];
    }
    else
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Mail Not Setup"
                                                         message:@"Please setup Mail first."
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"OK", nil] autorelease];
        
        [alert show];
    }
}

#pragma mark -

- (void)movieDidFinish:(NSNotification *)notification
{
    if (self.moviePlayer.fullscreen)
        [self.moviePlayer setFullscreen:NO animated:YES];
}

#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultFailed:
            
            [self dismissModalViewControllerAnimated:NO];
            
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Mail Failed"
                                                             message:@"There was a problem sending the mail."
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil] autorelease];
            
            [alert show];
            
            break;
            
        default:
            
            [self dismissModalViewControllerAnimated:YES];
    }
}

@end