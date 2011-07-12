//
//  DSMapBoxLayerAddAccountView.h
//  MapBoxiPad
//
//  Created by Justin Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxLayerAddAccountView;

@protocol DSMapBoxLayerAddAccountViewDelegate

@required

- (void)accountViewWasSelected:(DSMapBoxLayerAddAccountView *)accountView;

@end

#pragma mark -

@interface DSMapBoxLayerAddAccountView : UIView
{
    id <DSMapBoxLayerAddAccountViewDelegate>delegate;
    UIImageView *imageView;
    UILabel *label;
    NSMutableData *receivedData;
    BOOL touched;
}

@property (nonatomic, assign) id <DSMapBoxLayerAddAccountViewDelegate>delegate;
@property (nonatomic, readonly, assign) UIImage *image;
@property (nonatomic, assign) BOOL touched;

- (id)initWithFrame:(CGRect)rect imageURL:(NSURL *)imageURL labelText:(NSString *)labelText;

@end