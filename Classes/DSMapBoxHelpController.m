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

@synthesize moviePlayer;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerDidExitFullscreenNotification
                                                  object:self.moviePlayer];
    
    [moviePlayer release];
    
    [super dealloc];
}

#pragma mark -

- (IBAction)tappedVideoButton:(id)sender
{
    if ( ! self.moviePlayer)
    {
        NSURL *movieURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"intro" ofType:@"mov"]];
        
        self.moviePlayer = [[[MPMoviePlayerController alloc] initWithContentURL:movieURL] autorelease];
        
        self.moviePlayer.fullscreen = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayerDidExit:)
                                                     name:MPMoviePlayerDidExitFullscreenNotification
                                                   object:self.moviePlayer];
    }

    [self.parentViewController.view addSubview:moviePlayer.view];

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

- (void)moviePlayerDidExit:(NSNotification *)notification
{
    [self.moviePlayer stop];
    
    [self.moviePlayer.view removeFromSuperview];
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