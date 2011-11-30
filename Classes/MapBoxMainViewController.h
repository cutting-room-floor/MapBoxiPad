//
//  MapBoxMainViewController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Development Seed 2010. All rights reserved.
//

#import "DSMapBoxDocumentLoadController.h"
#import "DSMapBoxLayerController.h"
#import "DSMapBoxLayerManager.h"

#import <MessageUI/MessageUI.h>

@class DSMapView;
@class BALabel;

@interface MapBoxMainViewController : UIViewController <UIActionSheetDelegate, 
                                                        DSMapBoxDocumentLoadControllerDelegate, 
                                                        DSMapBoxDataLayerHandlerDelegate,
                                                        UIAlertViewDelegate, 
                                                        MFMailComposeViewControllerDelegate,
                                                        DSMapBoxLayerControllerDelegate>

@property (nonatomic, retain) IBOutlet DSMapView *mapView;
@property (nonatomic, retain) IBOutlet BALabel *attributionLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *layersButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *clusteringButton;

- (void)restoreState:(id)sender;
- (void)saveState:(id)sender;
- (IBAction)tappedLayersButton:(id)sender;
- (IBAction)tappedClusteringButton:(id)sender;
- (IBAction)tappedDocumentsButton:(id)sender;
- (IBAction)tappedHelpButton:(id)sender;
- (IBAction)tappedShareButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;
- (void)openRSSFile:(NSURL *)fileURL;
- (void)openGeoJSONFile:(NSURL *)fileURL;
- (void)openMBTilesFile:(NSURL *)fileURL;
- (void)checkPasteboardForURL;

@end