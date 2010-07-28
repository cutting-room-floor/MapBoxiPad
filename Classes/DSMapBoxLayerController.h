//
//  DSMapBoxLayerController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxLayerManager;

@interface DSMapBoxLayerController : UITableViewController
{
    DSMapBoxLayerManager *layerManager;
}

@property (nonatomic, retain) DSMapBoxLayerManager *layerManager;

- (IBAction)tappedEditButton:(id)sender;
- (IBAction)tappedDoneButton:(id)sender;

@end