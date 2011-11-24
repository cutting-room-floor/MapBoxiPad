//
//  DSMapBoxLayerAddCustomServerController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "ASIHTTPRequestDelegate.h"

@interface DSMapBoxLayerAddCustomServerController : UIViewController <UITextFieldDelegate, 
                                                                      UITableViewDelegate, 
                                                                      UITableViewDataSource,
                                                                      ASIHTTPRequestDelegate>

@property (nonatomic, retain) IBOutlet UITextField *entryField;
@property (nonatomic, retain) IBOutlet UITableView *recentServersTableView;

- (IBAction)tappedNextButton:(id)sender;

@end