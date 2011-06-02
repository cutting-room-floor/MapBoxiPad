//
//  DSMapBoxLayerAddTileStreamBrowseController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 5/17/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "iCarousel.h"

@interface DSMapBoxLayerAddTileStreamBrowseController : UIViewController <iCarouselDataSource, iCarouselDelegate>
{
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet iCarousel *tileCarousel;
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *detailsLabel;
    IBOutlet UILabel *helpLabel;
    
    NSURLConnection *downloadConnection;
    NSMutableData *receivedData;
    
    NSArray *items;
    NSMutableArray *imagesToDownload;
    
    NSUInteger activeDownloadIndex;
    
    NSMutableArray *selectedLayers;
    
    NSURL *serverURL;
}

@property (nonatomic, retain) NSURL *serverURL;

@end