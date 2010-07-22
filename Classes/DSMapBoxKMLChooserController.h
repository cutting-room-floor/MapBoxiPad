//
//  DSMapBoxKMLChooserController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxOverlayManager;

@interface DSMapBoxKMLChooserController : UITableViewController
{
    DSMapBoxOverlayManager *overlayManager;
    NSMutableArray *entities;
}

@property (nonatomic, retain) DSMapBoxOverlayManager *overlayManager;

@end