//
//  DSMapBoxLayerController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxLayerManager;

@interface DSMapBoxLayerController : UITableViewController <UIAlertViewDelegate>
{
    DSMapBoxLayerManager *layerManager;
    
    @private
        NSUInteger baseLayerRowToDelete;
}

@property (nonatomic, retain) DSMapBoxLayerManager *layerManager;
@property (nonatomic, assign) NSUInteger baseLayerRowToDelete;

- (IBAction)tappedEditButton:(id)sender;
- (IBAction)tappedDoneButton:(id)sender;

@end