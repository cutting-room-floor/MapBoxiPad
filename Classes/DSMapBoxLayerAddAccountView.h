//
//  DSMapBoxLayerAddAccountView.h
//  MapBoxiPad
//
//  Created by Justin Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "ASIHTTPRequestDelegate.h"

@class DSMapBoxLayerAddAccountView;

@protocol DSMapBoxLayerAddAccountViewDelegate

@required

- (void)accountViewWasSelected:(DSMapBoxLayerAddAccountView *)accountView;

@end

#pragma mark -

@interface DSMapBoxLayerAddAccountView : UIView <ASIHTTPRequestDelegate>
{
    id <DSMapBoxLayerAddAccountViewDelegate>delegate;
    NSArray *previewImageURLs;
    UIImageView *imageView;
    UILabel *label;
    CGPoint originalCenter;
    CGSize originalSize;
    ASIHTTPRequest *primaryImageRequest;
    NSMutableArray *secondaryImageRequests;
    BOOL featured;
    BOOL touched;
    BOOL flicked;
}

@property (nonatomic, assign) id <DSMapBoxLayerAddAccountViewDelegate>delegate;
@property (nonatomic, assign) BOOL featured;
@property (nonatomic, assign) BOOL touched;

- (id)initWithFrame:(CGRect)rect imageURLs:(NSArray *)imageURLs labelText:(NSString *)labelText;

@end