//
//  MapBoxWindow.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapBoxWindow : UIWindow
{
    UIWindow *overlay;
    NSMutableDictionary *touches;
    BOOL active;
}

@end