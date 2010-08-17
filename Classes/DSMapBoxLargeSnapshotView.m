//
//  DSMapBoxLargeSnapshotView.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/11/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxLargeSnapshotView.h"

#import <QuartzCore/QuartzCore.h>

#define kDSSnapshotInset kDSDocumentWidth / 32.0f

@implementation DSMapBoxLargeSnapshotView

@synthesize snapshotName;
@synthesize delegate;

- (id)initWithSnapshot:(UIImage *)snapshot
{
    self = [super initWithFrame:CGRectMake(0, 0, kDSDocumentWidth, kDSDocumentHeight)];
    
    if (self != nil)
    {
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:snapshot] autorelease];
        
        [self addSubview:imageView];

        CGFloat width;
        CGFloat height;
        
        if (snapshot.size.width > snapshot.size.height)
        {
            width  = kDSDocumentWidth;
            height = kDSDocumentHeight;
        }
        else
        {
            width  = kDSDocumentHeight;
            height = kDSDocumentHeight;
        }
        
        imageView.frame = CGRectMake(kDSSnapshotInset, 
                                     kDSSnapshotInset, 
                                     width  - kDSSnapshotInset * 2, 
                                     height - kDSSnapshotInset * 2);

        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.center      = self.center;

        // TODO: add image shadow here (performance concerns)
        //
        //imageView.layer.shadowOpacity   = 1.0;
        //imageView.layer.shadowOffset    = CGSizeMake(0.0, 1.0);
        //imageView.layer.shouldRasterize = YES;

        /*
         * Here we could do some fancy stuff like rotate the image slightly,
         * put a visual "stack" of images behind it more like Keynote does,
         * page curl it a bit, or things like that.
         */
    }
    
    return self;
}

#pragma mark -

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self.delegate respondsToSelector:@selector(snapshotViewWasTapped:withName:)])
        [self.delegate snapshotViewWasTapped:self withName:snapshotName];
}

@end