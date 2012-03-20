    //
//  DSMapBoxHelpController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 12/7/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxHelpController.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxHelpController ()

@property (nonatomic, strong) IBOutlet UIView *logoView;
@property (nonatomic, strong) IBOutlet UITableView *helpTableView;
@property (nonatomic, strong) IBOutlet UILabel *versionInfoLabel;

@end

#pragma mark -

@implementation DSMapBoxHelpController

@synthesize logoView;
@synthesize helpTableView;
@synthesize versionInfoLabel;

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // round logo & add shadow
    //
    UIView *clippingView = [[UIView alloc] initWithFrame:self.logoView.bounds];
    
    clippingView.backgroundColor = [UIColor clearColor];
    clippingView.clipsToBounds = YES;
    clippingView.layer.cornerRadius = clippingView.bounds.size.width / 10;
    
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"iTunesArtwork"]];
    
    logoImageView.frame = clippingView.bounds;

    [clippingView addSubview:logoImageView];
    
    [self.logoView addSubview:clippingView];
    
    self.logoView.backgroundColor = [UIColor clearColor];
    
    self.logoView.layer.cornerRadius = clippingView.layer.cornerRadius;

    self.logoView.layer.shadowOpacity = 1.0;
    self.logoView.layer.shadowOffset  = CGSizeMake(0, 2);

    // style table view
    //
    self.helpTableView.layer.cornerRadius = 10.0;
    self.helpTableView.clipsToBounds      = YES;
    self.helpTableView.separatorColor     = [UIColor colorWithWhite:1.0 alpha:0.25];

    // populate version info
    //
    self.versionInfoLabel.text = [NSString stringWithFormat:@"%@ %@.%@", 
                                     [[NSProcessInfo processInfo] processName],
                                     [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                     [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] stringByReplacingOccurrencesOfString:@"." withString:@""]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)tappedHelpDoneButton:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *HelpCellIdentifier = @"HelpCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HelpCellIdentifier];
    
    if ( ! cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:HelpCellIdentifier];
        
        // white chevron, unlike black default
        //
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chevron.png"]];
        
        // background view for color highlighting
        //
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.selectedBackgroundView.backgroundColor = kMapBoxBlue;
        
        // normal text & background colors
        //
        cell.backgroundColor     = [UIColor blackColor];
        cell.textLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.75];
        
        // cell font
        //
        cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    }
    
    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = @"Getting Started Guide";
            break;
            
        case 1:
            cell.textLabel.text = @"View Release Notes";
            break;
        
        case 2:
            cell.textLabel.text = @"Contact Support";
            break;

        case 3:
            cell.textLabel.text = [NSString stringWithFormat:@"About %@", [[NSProcessInfo processInfo] processName]];
            break;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UIAlertView *alert;
    
    switch (indexPath.row)
    {
        // these get opened delayed to avoid button press glitches
        //
        case 0:
            [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                                    withObject:[NSURL URLWithString:kGettingStartedURL]
                                                    afterDelay:0.25];
            
            break;
            
        case 1:
            [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                                    withObject:[NSURL URLWithString:kReleaseNotesURL]
                                                    afterDelay:0.25];
            
            break;
            
        case 2:
            [[UIApplication sharedApplication] performSelector:@selector(openURL:)
                                                    withObject:[NSURL URLWithString:kSupportURL]
                                                    afterDelay:0.25];

            break;
            
        case 3:
            alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"About %@", [[NSProcessInfo processInfo] processName]]
                                                message:[NSString stringWithFormat:@"%@\n\n%@", 
                                                         self.versionInfoLabel.text, 
                                                         [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"about" ofType:@"txt"]
                                                                                   encoding:NSUTF8StringEncoding
                                                                                      error:NULL]]
                                               delegate:nil
                                      cancelButtonTitle:nil
                                      otherButtonTitles:@"OK", nil];
            
            [alert show];
            
            break;
    }
}

@end