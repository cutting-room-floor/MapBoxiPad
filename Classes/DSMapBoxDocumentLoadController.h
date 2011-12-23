//
//  DSMapBoxDocumentLoadController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxLargeSnapshotView.h"

#import <MessageUI/MessageUI.h>

#define kDSSaveFolderName @"Saved Maps"
#define kDSSaveFileName   @"Saved Map"

@class DSMapBoxDocumentLoadController;

@protocol DSMapBoxDocumentLoadControllerDelegate

- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller didLoadDocumentWithName:(NSString *)name;
- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller wantsToSaveDocumentWithName:(NSString *)name;

@end

#pragma mark -

@interface DSMapBoxDocumentLoadController : UIViewController <UIActionSheetDelegate, 
                                                              UIScrollViewDelegate, 
                                                              DSMapBoxLargeSnapshotDelegate, 
                                                              MFMailComposeViewControllerDelegate,
                                                              UIAlertViewDelegate>

@property (nonatomic, weak) id <NSObject, DSMapBoxDocumentLoadControllerDelegate>delegate;
@property (nonatomic, strong) IBOutlet UIView *noDocsView;
@property (nonatomic, strong) IBOutlet UIScrollView *scroller;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIButton *actionButton;
@property (nonatomic, strong) IBOutlet UIButton *trashButton;

+ (NSString *)saveFolderPath;

- (IBAction)tappedSaveNowButton:(id)sender;
- (IBAction)tappedSendButton:(id)sender;
- (IBAction)tappedTrashButton:(id)sender;

@end