//
//  DSMapBoxLayerController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxLayerManager;

@protocol DSMapBoxLayerControllerDelegate

- (void)zoomToLayer:(NSDictionary *)layer;
- (void)presentAddLayerHelper;

@end

#pragma mark -

@interface DSMapBoxLayerController : UITableViewController <UIAlertViewDelegate>
{
    DSMapBoxLayerManager *layerManager;
    id <DSMapBoxLayerControllerDelegate, NSObject>delegate;
}

@property (nonatomic, retain) DSMapBoxLayerManager *layerManager;
@property (nonatomic, assign) id <DSMapBoxLayerControllerDelegate, NSObject>delegate;

- (IBAction)tappedEditButton:(id)sender;
- (IBAction)tappedDoneButton:(id)sender;
- (BOOL)layerAtURLShouldShowCrosshairs:(NSURL *)layerURL;

@end