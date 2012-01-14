//
//  DSMapBoxLayerController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

@class DSMapBoxLayerManager;

@protocol DSMapBoxLayerControllerDelegate

- (void)zoomToLayer:(NSDictionary *)layer;
- (void)presentAddLayerHelper;

@end

#pragma mark -

@interface DSMapBoxLayerController : UITableViewController

@property (nonatomic, strong) DSMapBoxLayerManager *layerManager;
@property (nonatomic, weak) id <DSMapBoxLayerControllerDelegate, NSObject>delegate;

@end