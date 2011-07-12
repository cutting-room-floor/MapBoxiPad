//
//  DSMapBoxLayerAddTileStreamBrowseController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMapBoxLayerAddTileView.h"

extern NSString *const DSMapBoxLayersAdded;

@interface DSMapBoxLayerAddTileStreamBrowseController : UIViewController <UIScrollViewDelegate, DSMapBoxLayerAddTileViewDelegate>
{
    IBOutlet UILabel *helpLabel;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UIScrollView *tileScrollView;
    IBOutlet UIPageControl *tilePageControl;
    
    NSMutableData *receivedData;
    
    NSArray *layers;
    
    NSMutableArray *selectedLayers;
    NSMutableArray *selectedImages;
    
    NSString *serverTitle;
    NSURL *serverURL;
}

@property (nonatomic, retain) NSString *serverTitle;
@property (nonatomic, retain) NSURL *serverURL;

@end