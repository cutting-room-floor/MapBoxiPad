//
//  MapBoxiPadDemoViewController.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMMapView.h"

@interface MapBoxiPadDemoViewController : UIViewController <RMMapViewDelegate>
{
    IBOutlet RMMapView *mapView;
    IBOutlet UIToolbar *toolbar;
    IBOutlet UILabel *clickLabel;
    IBOutlet UIImageView *clickStripe;
    NSMutableDictionary *lastMarkerInfo;
    NSTimer *timer;
}

- (IBAction)tappedAllowRotationButton:(id)sender;
- (IBAction)tappedRecenterButton:(id)sender;
- (IBAction)tappedKMLButton:(id)sender;

@end