//
//  DSMapBoxLayerAddTileStreamAlbumController.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddAccountView.h"

@interface DSMapBoxLayerAddTileStreamAlbumController : UIViewController <DSMapBoxLayerAddAccountViewDelegate>

@property (nonatomic, strong) IBOutlet UILabel *helpLabel;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UIScrollView *accountScrollView;

@end