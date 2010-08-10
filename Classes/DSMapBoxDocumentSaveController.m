    //
//  DSMapBoxDocumentSaveController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDocumentSaveController.h"

@implementation DSMapBoxDocumentSaveController

@synthesize snapshot;
@synthesize name;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    snapshotView.image = self.snapshot;
    nameTextField.text = self.name;
    
    nameTextField.clearButtonMode = UITextFieldViewModeAlways;
        
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateName:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nameTextField];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [nameTextField becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nameTextField];
    
    [snapshot release];
    [name release];
    
    [super dealloc];
}

#pragma mark -

- (void)updateName:(NSNotification *)notification
{
    self.name = nameTextField.text;
    
    if ([self.name length] && [[self.name componentsSeparatedByString:@"/"] count] < 2) // no slashes
        self.navigationItem.rightBarButtonItem.enabled = YES;
    
    else
        self.navigationItem.rightBarButtonItem.enabled = NO;
}

@end