//
//  MapBoxAppDelegate.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Development Seed 2010. All rights reserved.
//

#import "DirectoryWatcher.h"

@class MapBoxMainViewController;

@interface MapBoxAppDelegate : NSObject <UIApplicationDelegate, UIAlertViewDelegate, DirectoryWatcherDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MapBoxMainViewController *viewController;
@property (nonatomic, assign) BOOL openingExternalFile;

- (BOOL)openExternalURL:(NSURL *)externalURL;

@end