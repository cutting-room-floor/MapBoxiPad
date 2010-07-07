//
//  DSMapBoxBalloonController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMapBoxBalloonController : UIViewController <UIWebViewDelegate>
{
    IBOutlet UIWebView *webView;
    NSString *name;
    NSString *description;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *description;

@end