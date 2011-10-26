//
//  DSMapBoxLayerAddTileStreamBrowseController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddTileView.h"

#import "ASIHTTPRequestDelegate.h"

extern NSString *const DSMapBoxLayersAdded;

@interface DSMapBoxLayerAddTileStreamBrowseController : UIViewController <UIScrollViewDelegate, 
                                                                          DSMapBoxLayerAddTileViewDelegate,
                                                                          ASIHTTPRequestDelegate>

@property (nonatomic, retain) IBOutlet UILabel *helpLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UIScrollView *tileScrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *tilePageControl;
@property (nonatomic, retain) NSString *serverName;
@property (nonatomic, retain) NSURL *serverURL;

@end