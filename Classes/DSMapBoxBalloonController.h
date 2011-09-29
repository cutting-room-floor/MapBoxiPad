//
//  DSMapBoxBalloonController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

@interface DSMapBoxBalloonController : UIViewController <UIWebViewDelegate>
{
    IBOutlet UIWebView *webView;
    NSString *name;
    NSString *description;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *description;

@end