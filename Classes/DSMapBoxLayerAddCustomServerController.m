    //
//  DSMapBoxLayerAddCustomServerController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddCustomServerController.h"

#import "DSMapBoxLayerAddTileStreamBrowseController.h"

#import "ASIHTTPRequest.h"

#import "JSONKit.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLayerAddCustomServerController (DSMapBoxLayerAddTypeControllerPrivate)

- (void)setRecentServersHidden:(BOOL)flag;
- (void)updateRecentServersAppearance;

@end

#pragma mark -

@implementation DSMapBoxLayerAddCustomServerController

@synthesize finalURL;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Custom Source";

    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Custom Source"
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:nil 
                                                                             action:nil] autorelease];

    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Browse"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(tappedNextButton:)] autorelease];
    
    // text field styling
    //
    entryField.superview.backgroundColor    = [UIColor blackColor];
    entryField.superview.layer.cornerRadius = 10.0;
    entryField.superview.clipsToBounds      = YES;
    
    // table styling, including selection background clipping
    //
    recentServersTableView.layer.cornerRadius = 10.0;
    recentServersTableView.clipsToBounds      = YES;
    recentServersTableView.separatorColor     = [UIColor colorWithWhite:1.0 alpha:0.25];
    
    [TESTFLIGHT passCheckpoint:@"viewed custom TileStream servers"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.rightBarButtonItem.enabled = NO;

    [spinner stopAnimating];
    
    successImage.hidden = YES;

    [recentServersTableView reloadData];
    
    [self updateRecentServersAppearance];
    
    entryField.text = @"";

    [entryField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [entryField resignFirstResponder];
}

- (void)dealloc
{
    if (validationRequest)
    {
        [validationRequest clearDelegatesAndCancel];
        [validationRequest release];
    }

    [finalURL release];
    
    [super dealloc];
}


#pragma mark -

- (void)setRecentServersHidden:(BOOL)flag
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    
    recentServersTableView.hidden = flag;
    
    [UIView commitAnimations];
}

- (void)updateRecentServersAppearance
{
    recentServersTableView.frame = CGRectMake(recentServersTableView.frame.origin.x,
                                              recentServersTableView.frame.origin.y,
                                              recentServersTableView.frame.size.width,
                                              [recentServersTableView numberOfRowsInSection:0] * [recentServersTableView rowHeight] - 1);

    if ( ! [[NSUserDefaults standardUserDefaults] objectForKey:@"recentServers"] || [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] count] == 0)
        [self setRecentServersHidden:YES];
    
    else
        [self setRecentServersHidden:NO];
}

- (void)validateEntry
{
    if ([entryField.text length])
    {
        self.finalURL = nil;
        
        NSString *enteredValue = [entryField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                  enteredValue = [enteredValue    stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

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
            self.finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", kTileStreamHostingURL, enteredValue, kTileStreamTilesetAPIPath]];
        }
        
        if (self.finalURL)
        {
            [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
            
            validationRequest = [[ASIHTTPRequest requestWithURL:self.finalURL] retain];

            validationRequest.timeOutSeconds = 10;
            validationRequest.delegate = self;
            
            [validationRequest startAsynchronous];
            
            [spinner startAnimating];
        }
        
        else
            [spinner performSelector:@selector(stopAnimating) withObject:nil afterDelay:0.5];
    }

    else
        [spinner stopAnimating];
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
    DSMapBoxLayerAddTileStreamBrowseController *controller = [[[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil] autorelease];

    if ([[self.finalURL absoluteString] hasPrefix:kTileStreamHostingURL])
    {
        NSMutableString *serverName = [NSMutableString stringWithString:[self.finalURL absoluteString]];
        
        [serverName replaceOccurrencesOfString:kTileStreamHostingURL withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, [serverName length])];
        [serverName replaceOccurrencesOfString:@"/"                  withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, [serverName length])];
        
        controller.serverName = serverName;
    }
    
    else
        controller.serverName = [self.finalURL absoluteString];
    
    controller.serverURL  = self.finalURL;
    
    [(UINavigationController *)self.parentViewController pushViewController:controller animated:YES];
    
    [TESTFLIGHT passCheckpoint:@"added custom TileStream server"];
}

#pragma mark -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [NSObject cancelPreviousPerformRequestsWithTarget:spinner];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (validationRequest)
    {
        [validationRequest clearDelegatesAndCancel];
        [validationRequest release];
        validationRequest = nil;
    }

    [spinner startAnimating];
    
    successImage.hidden = YES;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
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

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [spinner stopAnimating];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [spinner stopAnimating];

    id layers = [request.responseData objectFromJSONData];

    if (layers && [layers isKindOfClass:[NSArray class]])
    {
        self.finalURL = [NSURL URLWithString:[[self.finalURL absoluteString] stringByReplacingOccurrencesOfString:kTileStreamTilesetAPIPath withString:@""]];
        
        successImage.hidden = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RecentServerCellIdentifier] autorelease];
        
        // white chevron, unlike black default
        //
        cell.accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chevron.png"]] autorelease];
        
        // background view for color highlighting
        //
        cell.selectedBackgroundView = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
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