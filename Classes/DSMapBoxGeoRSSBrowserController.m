//
//  DSMapBoxGeoRSSBrowserController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/7/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxGeoRSSBrowserController.h"

#define kBrowserStartURL @"http://localhost/~incanus/testing.html"

@implementation DSMapBoxGeoRSSBrowserController

@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [addressField becomeFirstResponder];
    
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kBrowserStartURL]]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark -

- (IBAction)tappedCancel:(id)sender
{
    [self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark -

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ( ! [textField.text hasPrefix:@"http://"] && ! [textField.text hasPrefix:@"https://"])
        textField.text = [NSString stringWithFormat:@"http://%@", textField.text];
    
    NSURL *requestURL = [NSURL URLWithString:textField.text];
    
    if (requestURL)
    {
        [webView loadRequest:[NSURLRequest requestWithURL:requestURL]];
    }
}

#pragma mark -

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] path] hasSuffix:@".xml"] || [[[request URL] path] hasSuffix:@".rss"])
    {
        if (self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(browserController:didVisitFeedURL:)])
            [self.delegate browserController:self didVisitFeedURL:[request URL]];
        
        [self tappedCancel:self];
    }
    
    else if ([[[request URL] scheme] hasPrefix:@"http"])
        return YES;
    
    return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // update URL bar
}

@end