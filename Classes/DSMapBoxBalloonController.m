//
//  DSMapBoxBalloonController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxBalloonController.h"

@implementation DSMapBoxBalloonController

@synthesize name;
@synthesize description;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    self = [super initWithNibName:nibName bundle:nibBundle];

    if (self != nil)
    {
        name        = [[NSString stringWithString:@""] retain];
        description = [[NSString stringWithString:@""] retain];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *balloon = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"balloon" ofType:@"html"]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    balloon = [balloon stringByReplacingOccurrencesOfString:@"##name##"        withString:self.name];
    balloon = [balloon stringByReplacingOccurrencesOfString:@"##description##" withString:self.description];
    
    [webView loadHTMLString:balloon baseURL:nil];
}

- (void)dealloc
{
    [name release];
    [description release];
    
    [super dealloc];
}

#pragma mark -

- (void)setName:(NSString *)inName
{
    [name release];
    
    if ( ! inName)
        name = [[NSString stringWithString:@"Untitled"] retain];
    
    else
        name = [inName retain];
}

- (void)setDescription:(NSString *)inDescription
{
    [description release];
    
    if ( ! inDescription)
        description = [[NSString stringWithString:@"(no description)"] retain];
    
    else
        description = [inDescription retain];
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    // first load is about:blank before content is injected
    //
    if ( ! [[[request URL] scheme] isEqualToString:@"about"])
    {
        // we may want to put an alert in here prompting the user first
        //
        [[UIApplication sharedApplication] openURL:[request URL]];
        
        return NO;
    }
    
    return YES;
}

@end