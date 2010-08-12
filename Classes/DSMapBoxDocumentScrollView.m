//
//  DSMapBoxDocumentScrollView.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/11/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDocumentScrollView.h"

@interface DSMapBoxDocumentScrollView (DSMapBoxDocumentScrollViewPrivate)

- (void)performSetup;
- (void)notifyDelegateOfScrolling;

@end;

#pragma mark -

@implementation DSMapBoxDocumentScrollView

@synthesize documentViews;
@synthesize delegate;

- (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];

    if (self != nil)
        [self performSetup];
        
    return self;
}

- (void)awakeFromNib
{
    [self performSetup];
}

#pragma mark -

- (void)performSetup
{
    NSAssert(self.frame.size.width == kDSDocumentWidth * 3.0f && self.frame.size.height == kDSDocumentHeight, @"Document scroll view frame should be the same height as documents and three times the width");
    
    self.scrollsToTop                   = NO;
    self.showsVerticalScrollIndicator   = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.scrollEnabled                  = NO;
    self.pagingEnabled                  = NO;
    self.bounces                        = NO;
    
    index = 0;
}

#pragma mark -

- (NSArray *)documentViews
{
    NSAssert(NO, @"documentViews is not meant to be read");
    
    return nil;
}

- (void)setDocumentViews:(NSArray *)inDocumentViews
{
    // remove old subviews
    //
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    // add first, invisible view
    //
    UIView *startDummyView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    [self addSubview:startDummyView];
    startDummyView.frame = CGRectMake(0, 0, kDSDocumentWidth, kDSDocumentHeight);
    
    // add document views
    //
    for (NSUInteger i = 0; i < [inDocumentViews count]; i++)
    {
        UIView *documentView = [inDocumentViews objectAtIndex:i];
        
        [self addSubview:documentView];
        
        documentView.frame = CGRectMake(kDSDocumentWidth * (i + 1), 0, kDSDocumentWidth, kDSDocumentHeight);
    }
    
    // add last, invisible view
    //
    UIView *endDummyView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    [self addSubview:endDummyView];
    endDummyView.frame = CGRectMake(kDSDocumentWidth * ([inDocumentViews count] + 1), 0, kDSDocumentWidth, kDSDocumentHeight);
    
    // adjust content size
    //
    self.contentSize = CGSizeMake(kDSDocumentWidth * [self.subviews count], kDSDocumentHeight);

    index = 0;
    
    [self notifyDelegateOfScrolling];
}

#pragma mark -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchDown = [[touches anyObject] locationInView:self];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    touchUp = [[touches anyObject] locationInView:self];
    
    CGFloat delta    = touchUp.x - touchDown.x;
    CGFloat currentX = self.contentOffset.x;
    
    // scroll left if swiped to left & room to scroll
    //
    if (delta < -44.00 && currentX < self.contentSize.width - (kDSDocumentWidth * 3))
    {
        index = index + 1;
        [self setContentOffset:CGPointMake(currentX + kDSDocumentWidth, 0) animated:YES];
        [self notifyDelegateOfScrolling];
    }
    
    // scroll right if swiped to right & room to scroll
    //
    else if (delta > 44.0 && currentX > 0)
    {
        index = index - 1;
        [self setContentOffset:CGPointMake(currentX - kDSDocumentWidth, 0) animated:YES];
        [self notifyDelegateOfScrolling];
    }
    
    // consider as a tap selection if on current subview
    //
    else if (delta >= -44.0 && delta <= 44.0)
    {
        CGFloat currentViewLeftX  = currentX;
        CGFloat currentViewRightX = currentX + kDSDocumentWidth;
        
        NSUInteger tapIndex = (NSUInteger)(currentViewRightX / kDSDocumentWidth) - 1;
        
        if (currentViewLeftX <= (touchUp.x - kDSDocumentWidth) && (touchUp.x - kDSDocumentWidth) <= currentViewRightX)
            if ([self.delegate respondsToSelector:@selector(documentScrollView:didTapItemAtIndex:)])
                [self.delegate documentScrollView:self didTapItemAtIndex:tapIndex];
    }
}

#pragma mark -

- (void)notifyDelegateOfScrolling
{
    // notify delegate manually since we're programmatically scrolling
    //
    if ([self.delegate respondsToSelector:@selector(documentScrollView:didScrollToIndex:)])
        [self.delegate documentScrollView:self didScrollToIndex:index];
}

@end