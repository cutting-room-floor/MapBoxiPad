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

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
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
    
    textField.text = @"http://tiles.mapbox.com/mapbox";
    
    [textField becomeFirstResponder];
    
    [self textField:textField shouldChangeCharactersInRange:NSMakeRange(0, [textField.text length]) replacementString:textField.text];
    
    
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    

    [super dealloc];
}


- (void)tappedNextButton:(id)sender
{
    
    DSMapBoxLayerAddTileStreamBrowseController *controller = [[[DSMapBoxLayerAddTileStreamBrowseController alloc] initWithNibName:nil bundle:nil] autorelease];
   
    
    controller.serverURL = [NSURL URLWithString:[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
    
    
    [(UINavigationController *)self.parentViewController pushViewController:controller animated:YES];
    
    
    
    
    
}

- (void)stopActivity
{
    [spinner stopAnimating];
    successImage.hidden = NO;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}


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
