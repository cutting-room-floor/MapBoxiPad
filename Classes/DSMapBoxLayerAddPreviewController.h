//
//  DSMapBoxLayerAddPreviewController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/18/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@class DSMapView;
@class DSMapBoxDataOverlayManager;

@interface DSMapBoxLayerAddPreviewController : UIViewController
{
    IBOutlet DSMapView *mapView;
    IBOutlet UILabel *metadataLabel;
    
    DSMapBoxDataOverlayManager *overlayManager;
    NSDictionary *info;
}

@property (nonatomic, retain) NSDictionary *info;

@end