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

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet MapBoxMainViewController *viewController;
@property (nonatomic, assign) BOOL openingExternalFile;

- (BOOL)openExternalURL:(NSURL *)externalURL;

@end