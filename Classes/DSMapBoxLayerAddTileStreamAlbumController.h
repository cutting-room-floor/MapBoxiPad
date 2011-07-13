//
//  DSMapBoxLayerAddTileStreamAlbumController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/11/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxLayerAddAccountView.h"

#import "ASIHTTPRequestDelegate.h"

@interface DSMapBoxLayerAddTileStreamAlbumController : UIViewController <UIScrollViewDelegate, 
                                                                         DSMapBoxLayerAddAccountViewDelegate,
                                                                         ASIHTTPRequestDelegate>
{
    IBOutlet UILabel *helpLabel;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UIScrollView *accountScrollView;
    IBOutlet UIPageControl *accountPageControl;
    
    NSArray *servers;
}

@end