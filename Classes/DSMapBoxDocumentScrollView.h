//
//  DSMapBoxDocumentScrollView.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/11/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDSDocumentWidth  800.0f
#define kDSDocumentHeight 600.0f

@class DSMapBoxDocumentScrollView;

@protocol DSMapBoxDocumentScrollViewDelegate

@optional

- (void)documentScrollView:(DSMapBoxDocumentScrollView *)scrollView didScrollToIndex:(NSUInteger)index;
- (void)documentScrollView:(DSMapBoxDocumentScrollView *)scrollView didTapItemAtIndex:(NSUInteger)index;

@end

#pragma mark -

@interface DSMapBoxDocumentScrollView : UIScrollView
{
    CGPoint touchDown;
    CGPoint touchUp;
    id <NSObject, UIScrollViewDelegate, DSMapBoxDocumentScrollViewDelegate>delegate;
    NSUInteger index;
}

@property (nonatomic, retain) NSArray *documentViews;
@property (nonatomic, assign) id <NSObject, UIScrollViewDelegate, DSMapBoxDocumentScrollViewDelegate>delegate;
@property (nonatomic, readonly, assign) NSUInteger index;

@end