//
//  DSMapBoxLargeSnapshotView.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/11/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDSDocumentWidth  800.0f
#define kDSDocumentHeight 600.0f

@class DSMapBoxLargeSnapshotView;

@protocol DSMapBoxLargeSnapshotDelegate

- (void)snapshotViewWasTapped:(DSMapBoxLargeSnapshotView *)snapshotView withName:(NSString *)snapshotName;

@end

#pragma mark -

@interface DSMapBoxLargeSnapshotView : UIView
{
    NSString *snapshotName;
    id <NSObject, DSMapBoxLargeSnapshotDelegate>delegate;
}

@property (nonatomic, retain) NSString *snapshotName;
@property (nonatomic, assign) id <NSObject, DSMapBoxLargeSnapshotDelegate>delegate;

- (id)initWithSnapshot:(UIImage *)snapshot;

@end