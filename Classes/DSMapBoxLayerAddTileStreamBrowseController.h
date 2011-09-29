//
//  DSMapBoxLayerAddTileStreamBrowseController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxLayerAddTileView.h"

#import "ASIHTTPRequestDelegate.h"

extern NSString *const DSMapBoxLayersAdded;

@interface DSMapBoxLayerAddTileStreamBrowseController : UIViewController <UIScrollViewDelegate, 
                                                                          DSMapBoxLayerAddTileViewDelegate,
                                                                          ASIHTTPRequestDelegate>
{
    IBOutlet UILabel *helpLabel;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UIScrollView *tileScrollView;
    IBOutlet UIPageControl *tilePageControl;
    
    NSArray *layers;
    
    NSMutableArray *selectedLayers;
    NSMutableArray *selectedImages;
    
    ASIHTTPRequest *layersRequest;
    
    NSString *serverName;
    NSURL *serverURL;
    
    UIView *animatedTileView;
    CGPoint originalTileViewCenter;
    CGSize originalTileViewSize;
}

@property (nonatomic, retain) NSString *serverName;
@property (nonatomic, retain) NSURL *serverURL;

@end