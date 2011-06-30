//
//  DSMapBoxLayerAddTileView.h
//  MapBoxiPad
//
//  Created by Justin Miller on 6/29/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DSMapBoxLayerAddTileView;

@protocol DSMapBoxLayerAddTileViewDelegate

@required

- (void)tileView:(DSMapBoxLayerAddTileView *)tileView selectionDidChange:(BOOL)selected;
- (void)tileViewWantsToShowPreview:(DSMapBoxLayerAddTileView *)tileView;

@end

#pragma mark -

@interface DSMapBoxLayerAddTileView : UIView
{
    id <DSMapBoxLayerAddTileViewDelegate>delegate;
    UIImageView *imageView;
    UILabel *label;
    NSMutableData *receivedData;
    BOOL selected;
    BOOL touched;
}

@property (nonatomic, assign) id <DSMapBoxLayerAddTileViewDelegate>delegate;
@property (nonatomic, readonly, assign) UIImage *image;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL touched;

- (id)initWithFrame:(CGRect)rect imageURL:(NSURL *)imageURL labelText:(NSString *)labelText;

@end