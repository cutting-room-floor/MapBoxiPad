//
//  DSMapBoxLargeSnapshotView.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 8/11/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#define kDSDocumentWidth  800.0f
#define kDSDocumentHeight 600.0f

@class DSMapBoxLargeSnapshotView;

@protocol DSMapBoxLargeSnapshotDelegate

- (void)snapshotViewWasTapped:(DSMapBoxLargeSnapshotView *)snapshotView withName:(NSString *)snapshotName;

@end

#pragma mark -

@interface DSMapBoxLargeSnapshotView : UIView

@property (nonatomic, strong) NSString *snapshotName;
@property (nonatomic, weak) id <NSObject, DSMapBoxLargeSnapshotDelegate>delegate;
@property (nonatomic, assign) BOOL isActive;

- (id)initWithSnapshot:(UIImage *)snapshot;

@end