//
//  DSMapBoxLayerAddPreviewController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@class DSMapView;

@interface DSMapBoxLayerAddPreviewController : UIViewController
{
}

@property (nonatomic, retain) IBOutlet DSMapView *mapView;
@property (nonatomic, retain) IBOutlet UILabel *metadataLabel;
@property (nonatomic, retain) NSDictionary *info;

@end