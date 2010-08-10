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
    
    snapshotView.image = snapshot;
    nameTextField.text = name;
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
    [snapshot release];
    [name release];
    
    [super dealloc];
}

@end