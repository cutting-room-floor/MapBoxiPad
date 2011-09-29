//
//  DSMapBoxDocumentSaveController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMapBoxDocumentSaveController : UIViewController <UITextFieldDelegate>
{
    IBOutlet UIImageView *snapshotView;
    IBOutlet UITextField *nameTextField;
}

@property (nonatomic, retain) UIImage *snapshot;
@property (nonatomic, retain) NSString *name;

@end