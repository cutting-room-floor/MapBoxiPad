//
//  MapBoxiPadDemoAppDelegate.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapBoxiPadDemoViewController;

@interface MapBoxiPadDemoAppDelegate : NSObject <UIApplicationDelegate>
{
    UIWindow *window;
    MapBoxiPadDemoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MapBoxiPadDemoViewController *viewController;

@end