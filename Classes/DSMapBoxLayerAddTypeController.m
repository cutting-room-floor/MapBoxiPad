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

#import "CJSONDeserializer.h"

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
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [spinner stopAnimating];
    
    successImage.hidden = YES;
    
    receivedData = [[NSMutableData data] retain];

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


- (void)tappedNextButton:(id)sender
{
    DSMapBoxLayerAddTileStreamBrowseController *controller = [[[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil] autorelease];
   
    NSString *enteredValue = [entryField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ( ! [enteredValue hasPrefix:@"http"])
        enteredValue = [NSString stringWithFormat:@"http://%@", enteredValue];
    
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
    
    [spinner startAnimating];
    
    successImage.hidden = YES;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self performSelector:@selector(validateEntry) withObject:nil afterDelay:0.5];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.navigationItem.rightBarButtonItem.enabled)
        [self tappedNextButton:self];
        
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

    NSError *error = nil;
    
    NSArray *layers = [[CJSONDeserializer deserializer] deserializeAsArray:receivedData error:&error];

    if ( ! error && [layers count])
    {
        successImage.hidden = NO;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

@end