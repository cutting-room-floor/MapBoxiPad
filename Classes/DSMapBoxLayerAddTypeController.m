    //
//  DSMapBoxLayerAddTypeController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLayerAddTypeController.h"

#import "DSMapBoxLayerAddTileStreamBrowseController.h"

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

    [textField becomeFirstResponder];
    
    [self textField:textField shouldChangeCharactersInRange:NSMakeRange(0, [textField.text length]) replacementString:textField.text];
}

#pragma mark -

- (void)tappedNextButton:(id)sender
{
    DSMapBoxLayerAddTileStreamBrowseController *controller = [[[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil] autorelease];
   
    NSString *enteredValue = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ( ! [enteredValue hasPrefix:@"http"])
        enteredValue = [NSString stringWithFormat:@"http://%@", enteredValue];
    
    controller.serverURL = [NSURL URLWithString:enteredValue];
    
    [(UINavigationController *)self.parentViewController pushViewController:controller animated:YES];
}

- (void)stopActivity
{
    [spinner stopAnimating];
    successImage.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

#pragma mark -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [NSObject cancelPreviousPerformRequestsWithTarget:spinner];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [spinner stopAnimating];
    
    if ( ! spinner.isAnimating)
        [spinner performSelector:@selector(startAnimating) withObject:nil afterDelay:0.5];
    
    successImage.hidden = YES;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    [self performSelector:@selector(stopActivity) withObject:nil afterDelay:2.5];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (self.navigationItem.rightBarButtonItem.enabled)
        [self tappedNextButton:self];
        
    return YES;
}

@end