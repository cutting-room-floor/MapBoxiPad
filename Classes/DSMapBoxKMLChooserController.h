//
//  DSMapBoxKMLChooserController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxDataOverlayManager;

@interface DSMapBoxKMLChooserController : UITableViewController
{
    DSMapBoxDataOverlayManager *overlayManager;
    NSMutableArray *entities;
}

@property (nonatomic, retain) DSMapBoxDataOverlayManager *overlayManager;

@end