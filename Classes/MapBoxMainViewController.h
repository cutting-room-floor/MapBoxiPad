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

@class RMMapView;
@class BALabel;

@interface MapBoxMainViewController : UIViewController <UIActionSheetDelegate, 
                                                        DSMapBoxDocumentLoadControllerDelegate, 
                                                        DSMapBoxDataLayerHandlerDelegate,
                                                        UIAlertViewDelegate, 
                                                        MFMailComposeViewControllerDelegate,
                                                        DSMapBoxLayerControllerDelegate>

@property (nonatomic, strong) IBOutlet RMMapView *mapView;
@property (nonatomic, strong) IBOutlet UIImageView *watermarkImage;
@property (nonatomic, strong) IBOutlet BALabel *attributionLabel;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *layersButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *clusteringButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *downloadsButton;

- (void)restoreState:(id)sender;
- (void)saveState:(id)sender;
- (IBAction)tappedLayersButton:(id)sender;
- (IBAction)tappedClusteringButton:(id)sender;
- (IBAction)tappedDocumentsButton:(id)sender;
- (IBAction)tappedHelpButton:(id)sender;
- (IBAction)tappedShareButton:(id)sender;
- (IBAction)tappedDownloadsButton:(id)sender;
- (void)openKMLFile:(NSURL *)fileURL;
- (void)openRSSFile:(NSURL *)fileURL;
- (void)openGeoJSONFile:(NSURL *)fileURL;
- (void)openMBTilesFile:(NSURL *)fileURL;
- (void)checkPasteboardForURL;

@end