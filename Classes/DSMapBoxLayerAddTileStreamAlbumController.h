//
//  DSMapBoxLayerAddTileStreamAlbumController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddAccountView.h"

#import "ASIHTTPRequestDelegate.h"

@interface DSMapBoxLayerAddTileStreamAlbumController : UIViewController <UIScrollViewDelegate, 
                                                                         DSMapBoxLayerAddAccountViewDelegate,
                                                                         ASIHTTPRequestDelegate>
{
}

@property (nonatomic, retain) IBOutlet UILabel *helpLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UIScrollView *accountScrollView;
@property (nonatomic, retain) IBOutlet UIPageControl *accountPageControl;

@end