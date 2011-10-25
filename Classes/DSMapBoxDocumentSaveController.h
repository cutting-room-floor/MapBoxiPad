//
//  DSMapBoxDocumentSaveController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

@interface DSMapBoxDocumentSaveController : UIViewController <UITextFieldDelegate>
{
}

@property (nonatomic, retain) IBOutlet UIImageView *snapshotView;
@property (nonatomic, retain) IBOutlet UITextField *nameTextField;
@property (nonatomic, retain) UIImage *snapshot;
@property (nonatomic, retain) NSString *name;

@end