    //
//  DSMapBoxLayerAddCustomServerController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddCustomServerController.h"

#import "DSMapBoxLayerAddTileStreamBrowseController.h"
#import "DSMapBoxTileStreamCommon.h"

#import "JSONKit.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLayerAddCustomServerController ()

- (void)setRecentServersHidden:(BOOL)flag;
- (void)startActivity;
- (void)indicateSuccess;
- (void)indicateFailure;
- (void)updateRecentServersAppearance;

@property (nonatomic, strong) NSURLConnection *validationDownload;
@property (nonatomic, strong) NSURL *finalURL;

@end

#pragma mark -

@implementation DSMapBoxLayerAddCustomServerController

@synthesize entryField;
@synthesize recentServersTableView;
@synthesize validationDownload;
@synthesize finalURL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Custom Source";

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Custom Source"
                                                                             style:UIBarButtonItemStyleBordered
                                                                            target:nil 
                                                                            action:nil];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Browse"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(tappedNextButton:)];
    
    // text field styling
    //
    self.entryField.superview.backgroundColor    = [UIColor blackColor];
    self.entryField.superview.layer.cornerRadius = 10.0;
    self.entryField.superview.clipsToBounds      = YES;
    
    // table styling, including selection background clipping
    //
    self.recentServersTableView.layer.cornerRadius = 10.0;
    self.recentServersTableView.clipsToBounds      = YES;
    self.recentServersTableView.separatorColor     = [UIColor colorWithWhite:1.0 alpha:0.25];
    
    [TESTFLIGHT passCheckpoint:@"viewed custom TileStream servers"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.rightBarButtonItem.enabled = NO;

    [self.recentServersTableView reloadData];
    
    [self updateRecentServersAppearance];
    
    self.entryField.text = @"";

    self.entryField.rightView     = nil;
    self.entryField.rightViewMode = UITextFieldViewModeAlways;

    [self.entryField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.entryField resignFirstResponder];
}

- (void)dealloc
{
    [DSMapBoxNetworkActivityIndicator removeJob:validationDownload];
}

#pragma mark -

- (void)setRecentServersHidden:(BOOL)flag
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    
    self.recentServersTableView.hidden = flag;
    
    [UIView commitAnimations];
}

- (void)startActivity
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    self.navigationItem.rightBarButtonItem.enabled = NO;

    if ( ! [self.entryField.rightView isKindOfClass:[UIActivityIndicatorView class]])
        self.entryField.rightView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    ((UIActivityIndicatorView *)self.entryField.rightView).hidesWhenStopped = YES;
    
    [(UIActivityIndicatorView *)self.entryField.rightView startAnimating];
}

- (void)indicateSuccess
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if ([self.entryField.rightView isKindOfClass:[UIActivityIndicatorView class]])
        [(UIActivityIndicatorView *)self.entryField.rightView stopAnimating];
    
    self.entryField.rightView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"check.png"]];
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)indicateFailure
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if ([self.entryField.rightView isKindOfClass:[UIActivityIndicatorView class]])
        [(UIActivityIndicatorView *)self.entryField.rightView stopAnimating];
}

- (void)updateRecentServersAppearance
{
    self.recentServersTableView.frame = CGRectMake(self.recentServersTableView.frame.origin.x,
                                                   self.recentServersTableView.frame.origin.y,
                                                   self.recentServersTableView.frame.size.width,
                                                   [self.recentServersTableView numberOfRowsInSection:0] * [self.recentServersTableView rowHeight] - 1);

    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"recentServers"] || [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] count] == 0)
        [self setRecentServersHidden:YES];
    
    else
        [self setRecentServersHidden:NO];
}

- (void)validateEntry
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    if ([self.entryField.text length])
    {
        self.finalURL = nil;
        
        NSString *enteredValue = [self.entryField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                  enteredValue = [enteredValue         stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

        if ([[enteredValue componentsSeparatedByString:@"."] count] > 1 || [[enteredValue componentsSeparatedByString:@":"] count] > 1 || [[enteredValue componentsSeparatedByString:@"localhost"] count] > 1)
        {
            // assume server hostname/IP if it contains a period
            //
            if ( ! [enteredValue hasPrefix:@"http"])
                enteredValue = [NSString stringWithFormat:@"http://%@", enteredValue];
            
            self.finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", enteredValue, kTileStreamTilesetAPIPath]];
        }
        else
        {
            // assume hosting account username
            //
            self.finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [DSMapBoxTileStreamCommon serverHostnamePrefix], enteredValue, kTileStreamTilesetAPIPath]];
        }
        
        if (self.finalURL)
        {
            DSMapBoxURLRequest *validationRequest = [DSMapBoxURLRequest requestWithURL:self.finalURL];
            
            validationRequest.timeoutInterval = 10;
            
            self.validationDownload = [NSURLConnection connectionWithRequest:validationRequest];
            
            __weak DSMapBoxLayerAddCustomServerController *selfCopy = self;
            
            self.validationDownload.successBlock = ^(NSURLConnection *connection, NSURLResponse *response, NSData *responseData)
            {
                [DSMapBoxNetworkActivityIndicator removeJob:connection];
                
                id layers = [responseData objectFromJSONData];
                
                if (layers && [layers isKindOfClass:[NSArray class]] && [layers count])
                {
                    selfCopy.finalURL = [NSURL URLWithString:[[selfCopy.finalURL absoluteString] stringByReplacingOccurrencesOfString:kTileStreamTilesetAPIPath withString:@""]];
                    
                    [selfCopy indicateSuccess];
                }
                
                else
                    [selfCopy indicateFailure];
            };
            
            self.validationDownload.failureBlock = ^(NSURLConnection *connection, NSError *error)
            {
                [DSMapBoxNetworkActivityIndicator removeJob:connection];
                
                [selfCopy indicateFailure];
            };
            
            [DSMapBoxNetworkActivityIndicator addJob:self.validationDownload];
            
            [self startActivity];
            
            [self.validationDownload start];
        }
        
        else
            [self performSelector:@selector(indicateFailure) withObject:nil afterDelay:0.5];
    }

    else
        [self indicateFailure];
}


- (IBAction)tappedNextButton:(id)sender
{
    // save the server to recents
    //
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recents  = [NSMutableArray array];

    if ([defaults objectForKey:@"recentServers"])
    {
        // get current values
        //
        [recents addObjectsFromArray:[defaults arrayForKey:@"recentServers"]];

        // remove new one if there previously
        //
        [recents removeObject:[self.finalURL absoluteString]];

        // trim to 6 total (before new one)
        //
        if ([recents count] > 7)
            recents = [NSMutableArray arrayWithArray:[recents subarrayWithRange:NSMakeRange(0, 7)]];
    }
    
    // add new one
    //
    [recents insertObject:[self.finalURL absoluteString] atIndex:0];

    // save to disk
    //
    [defaults setObject:recents forKey:@"recentServers"];
    [defaults synchronize];

    // browse the server
    //
    DSMapBoxLayerAddTileStreamBrowseController *controller = [[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil];

    if ([[self.finalURL absoluteString] hasPrefix:[DSMapBoxTileStreamCommon serverHostnamePrefix]])
    {
        NSMutableString *serverName = [NSMutableString stringWithString:[self.finalURL absoluteString]];
        
        [serverName replaceOccurrencesOfString:[DSMapBoxTileStreamCommon serverHostnamePrefix]
                                    withString:@"" 
                                       options:NSAnchoredSearch 
                                         range:NSMakeRange(0, [serverName length])];

        [serverName replaceOccurrencesOfString:@"/" 
                                    withString:@"" 
                                       options:NSAnchoredSearch 
                                         range:NSMakeRange(0, [serverName length])];
        
        controller.serverName = serverName;
    }
    
    else
        controller.serverName = [self.finalURL absoluteString];
    
    controller.serverURL = self.finalURL;
    
    [(UINavigationController *)self.parentViewController pushViewController:controller animated:YES];
    
    [TESTFLIGHT passCheckpoint:@"added custom TileStream server"];
}

#pragma mark -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.validationDownload)
        [validationDownload cancel];

    [self startActivity];
    
    [self performSelector:@selector(validateEntry) withObject:nil afterDelay:0.5];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (self.navigationItem.rightBarButtonItem.enabled)
        [self tappedNextButton:self];
    
    return NO;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.finalURL = [NSURL URLWithString:[[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] objectAtIndex:indexPath.row]];
    
    [self tappedNextButton:self];
    
    [TESTFLIGHT passCheckpoint:@"tapped custom TileStream server in history"];
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *RecentServerCellIdentifier = @"RecentServerCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RecentServerCellIdentifier];
    
    if ( ! cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RecentServerCellIdentifier];
        
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
    
    cell.textLabel.text = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] objectAtIndex:indexPath.row];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] count];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        NSMutableArray *recents = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"recentServers"]];
        
        [recents removeObjectAtIndex:indexPath.row];
        
        [defaults setObject:recents forKey:@"recentServers"];
        [defaults synchronize];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        
        [self updateRecentServersAppearance];
    }
}

@end