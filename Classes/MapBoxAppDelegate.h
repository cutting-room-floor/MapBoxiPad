//
//  MapBoxAppDelegate.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Development Seed 2010. All rights reserved.
//

@class DSFingerTipWindow;
@class MapBoxMainViewController;

@interface MapBoxAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate>
{
    DSFingerTipWindow *window;
    MapBoxMainViewController *viewController;
    BOOL openingExternalFile;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MapBoxMainViewController *viewController;
@property (nonatomic, assign) BOOL openingExternalFile;

- (BOOL)openExternalURL:(NSURL *)externalURL;

@end