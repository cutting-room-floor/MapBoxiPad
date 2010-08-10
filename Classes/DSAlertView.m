//
//  DSAlertView.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/10/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSAlertView.h"

@implementation DSAlertView

@synthesize contextInfo;

- (void)dealloc
{
    [contextInfo release];
    
    [super dealloc];
}

@end