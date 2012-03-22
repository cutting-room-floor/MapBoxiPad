//
//  DSMapBoxLayerAddTileView.h
//  MapBoxiPad
//
//  Created by Justin Miller on 6/29/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@class DSMapBoxLayerAddTileView;

@protocol DSMapBoxLayerAddTileViewDelegate

@required

- (void)tileView:(DSMapBoxLayerAddTileView *)tileView selectionDidChange:(BOOL)selected;
- (void)tileViewWantsToShowPreview:(DSMapBoxLayerAddTileView *)tileView;

@end

#pragma mark -

@interface DSMapBoxLayerAddTileView : UIView

@property (nonatomic, weak) id <DSMapBoxLayerAddTileViewDelegate>delegate;
@property (nonatomic, readonly, strong) UIImage *image;

- (id)initWithFrame:(CGRect)rect imageURL:(NSURL *)imageURL labelText:(NSString *)labelText;
- (void)startDownload;

@end