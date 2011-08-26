//
//  DSMapBoxLayerController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RMLatLong.h"

#import <MessageUI/MessageUI.h>

@class DSMapBoxLayerManager;

@protocol DSMapBoxLayerControllerDelegate

- (void)zoomToLayer:(NSDictionary *)layer;
- (void)presentAddLayerHelper;

@end

#pragma mark -

@interface DSMapBoxLayerController : UITableViewController <UIAlertViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
    DSMapBoxLayerManager *layerManager;
    id <DSMapBoxLayerControllerDelegate, NSObject>delegate;
    
    @private
        NSIndexPath *indexPathToDelete;
        NSURL *layerURLToShare;
}

@property (nonatomic, retain) DSMapBoxLayerManager *layerManager;
@property (nonatomic, assign) id <DSMapBoxLayerControllerDelegate, NSObject>delegate;
@property (nonatomic, retain) NSIndexPath *indexPathToDelete;
@property (nonatomic, retain) NSURL *layerURLToShare;

- (IBAction)tappedEditButton:(id)sender;
- (IBAction)tappedDoneButton:(id)sender;
- (BOOL)layerAtURLShouldShowCrosshairs:(NSURL *)layerURL;

@end