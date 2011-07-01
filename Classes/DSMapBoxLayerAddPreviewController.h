//
//  DSMapBoxLayerAddPreviewController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/18/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapView;

@interface DSMapBoxLayerAddPreviewController : UIViewController
{
    IBOutlet DSMapView *mapView;
    IBOutlet UILabel *metadataLabel;
    
    NSDictionary *info;
}

@property (nonatomic, retain) NSDictionary *info;

@end