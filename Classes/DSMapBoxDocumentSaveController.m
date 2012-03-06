//
//  DSMapBoxDocumentSaveController.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxDocumentSaveController.h"

#import "DSMapBoxDarkTextField.h"

@implementation DSMapBoxDocumentSaveController

@synthesize snapshotView;
@synthesize nameTextField;
@synthesize snapshot;
@synthesize name;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle    = UIBarStyleBlackTranslucent;
    self.navigationController.navigationBar.translucent = YES;
    
    snapshotView.image = self.snapshot;
    self.nameTextField.text = self.name;
    
    // watch for edits
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateName:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.nameTextField];
    
    [TestFlight passCheckpoint:@"prompted to save document"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.nameTextField becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nameTextField];
}

#pragma mark -

- (void)updateName:(NSNotification *)notification
{
    self.name = self.nameTextField.text;
    
    if ([self.name length] && [[self.name componentsSeparatedByString:@"/"] count] < 2) // no slashes
        self.navigationItem.rightBarButtonItem.enabled = YES;
    
    else
        self.navigationItem.rightBarButtonItem.enabled = NO;
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (self.navigationItem.rightBarButtonItem.enabled)
    {
        UIBarButtonItem *item = self.navigationItem.rightBarButtonItem;
        
        [item.target performSelector:item.action withObject:item];
    }
    
    return NO;
}

@end