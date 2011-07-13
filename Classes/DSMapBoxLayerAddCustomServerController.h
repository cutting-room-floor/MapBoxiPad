//
//  DSMapBoxLayerAddCustomServerController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMapBoxLayerAddCustomServerController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>
{
    IBOutlet UITextField *entryField;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UIImageView *successImage;
    IBOutlet UILabel *recentServersLabel;
    IBOutlet UITableView *recentServersTableView;
    NSURLConnection *validationConnection;
    NSMutableData *receivedData;
    NSURL *finalURL;
}

@property (nonatomic, retain) NSURL *finalURL;

- (IBAction)tappedNextButton:(id)sender;

@end