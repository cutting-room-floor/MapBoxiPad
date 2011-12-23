//
//  DSMapBoxLayerAddPreviewController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@class DSMapView;

@interface DSMapBoxLayerAddPreviewController : UIViewController

@property (nonatomic, strong) IBOutlet DSMapView *mapView;
@property (nonatomic, strong) IBOutlet UILabel *metadataLabel;
@property (nonatomic, strong) NSDictionary *info;

@end