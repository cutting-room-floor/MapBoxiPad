    //
//  DSMapBoxLayerAddTypeController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddTypeController.h"

#import "DSMapBoxLayerAddTileStreamBrowseController.h"

#import "MapBoxConstants.h"

#import "JSONKit.h"

@implementation DSMapBoxLayerAddTypeController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = @"Server Details";
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                           target:self.parentViewController
                                                                                           action:@selector(dismissModalViewControllerAnimated:)] autorelease];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Browse Server"
                                                                               style:UIBarButtonItemStyleBordered
                                                                              target:self
                                                                              action:@selector(tappedNextButton:)] autorelease];
    
    receivedData = [[NSMutableData data] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationItem.rightBarButtonItem.enabled = NO;

    [spinner stopAnimating];
    
    successImageButton.hidden = YES;

    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"recentServers"] && [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] count])
        recentServersTableView.hidden = NO;
    
    else
        recentServersTableView.hidden = YES;
    
    entryField.text = @"";
    
    [recentServersTableView reloadData];
    
    [entryField becomeFirstResponder];
}

- (void)dealloc
{
    if (validationConnection)
    {
        [validationConnection cancel];
        [validationConnection release];
    }

    [receivedData release];
    
    [super dealloc];
}


#pragma mark -

- (void)validateEntry
{
    NSString *enteredValue = [entryField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ( ! [enteredValue hasPrefix:@"http"])
        enteredValue = [NSString stringWithFormat:@"http://%@", enteredValue];
    
    NSURL *validationURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", enteredValue, kTileStreamAPIPath]];
    
    if (validationURL)
        validationConnection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:validationURL] delegate:self];
    
    else
        [spinner performSelector:@selector(stopAnimating) withObject:nil afterDelay:0.5];
}


- (IBAction)tappedNextButton:(id)sender
{
    DSMapBoxLayerAddTileStreamBrowseController *controller = [[[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil] autorelease];
   
    NSString *enteredValue = [entryField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ( ! [enteredValue hasPrefix:@"http"])
        enteredValue = [NSString stringWithFormat:@"http://%@", enteredValue];
    
    // save the server to recents
    //
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *recents = [NSMutableArray array];

    if ([defaults objectForKey:@"recentServers"])
    {
        [recents addObjectsFromArray:[defaults arrayForKey:@"recentServers"]];
        [recents removeObject:enteredValue];
    }
    
    [recents insertObject:enteredValue atIndex:0];
    [defaults setObject:recents forKey:@"recentServers"];
    [defaults synchronize];

    // browse the server
    //
    controller.serverURL = [NSURL URLWithString:enteredValue];
    
    [(UINavigationController *)self.parentViewController pushViewController:controller animated:YES];
}

#pragma mark -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [NSObject cancelPreviousPerformRequestsWithTarget:spinner];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (validationConnection)
    {
        [validationConnection cancel];
        [validationConnection release];
        validationConnection = nil;
    }
    
    [UIView beginAnimations:nil context:nil];
    
    if ([textField.text length])
        recentServersTableView.hidden = YES;
    
    else if ([[NSUserDefaults standardUserDefaults] objectForKey:@"recentServers"] && [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] count])
        recentServersTableView.hidden = NO;

    [UIView commitAnimations];
    
    [spinner startAnimating];
    
    successImageButton.hidden = YES;
    
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

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (recentServersTableView.hidden && [[NSUserDefaults standardUserDefaults] objectForKey:@"recentServers"] && [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] count])
    {
        [UIView beginAnimations:nil context:nil];

        recentServersTableView.hidden = NO;
        
        [UIView commitAnimations];
    }
    
    return YES;
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [spinner stopAnimating];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [spinner startAnimating];
    
    [receivedData setData:[NSData data]];    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [spinner stopAnimating];

    id layers = [receivedData objectFromJSONData];

    if (layers && [layers isKindOfClass:[NSArray class]] && [layers count])
    {
        successImageButton.hidden = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    entryField.text = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"recentServers"] objectAtIndex:indexPath.row];
    
    [self tappedNextButton:self];
}

#pragma mark -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *RecentServerCellIdentifier = @"RecentServerCellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RecentServerCellIdentifier];
    
    if ( ! cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RecentServerCellIdentifier] autorelease];
        
        cell.backgroundColor     = [UIColor blackColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *recents = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"recentServers"]];
    
    [recents removeObjectAtIndex:indexPath.row];
    
    [defaults setObject:recents forKey:@"recentServers"];
    [defaults synchronize];
    
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
    
    if ([recents count] == 0)
    {
        [UIView beginAnimations:nil context:nil];

        tableView.hidden = YES;
        
        [UIView commitAnimations];
    }
}

@end