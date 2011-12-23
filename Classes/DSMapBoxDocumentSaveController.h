//
//  DSMapBoxDocumentSaveController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

@class DSMapBoxDarkTextField;

@interface DSMapBoxDocumentSaveController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *snapshotView;
@property (nonatomic, strong) IBOutlet DSMapBoxDarkTextField *nameTextField;
@property (nonatomic, strong) UIImage *snapshot;
@property (nonatomic, strong) NSString *name;

@end