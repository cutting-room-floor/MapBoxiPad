//
//  DSMapBoxGeoRSSBrowserController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/7/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxGeoRSSBrowserController;

@protocol DSMapBoxGeoRSSBrowserControllerDelegate

- (void)browserController:(DSMapBoxGeoRSSBrowserController *)controller didVisitFeedURL:(NSURL *)feedURL;

@end

#pragma mark -

@interface DSMapBoxGeoRSSBrowserController : UIViewController <UITextFieldDelegate, UIWebViewDelegate>
{
    IBOutlet UITextField *addressField;
    IBOutlet UIWebView *webView;
    id <DSMapBoxGeoRSSBrowserControllerDelegate>delegate;
}

@property (nonatomic, assign) id <DSMapBoxGeoRSSBrowserControllerDelegate>delegate;

- (IBAction)tappedCancel:(id)sender;

@end