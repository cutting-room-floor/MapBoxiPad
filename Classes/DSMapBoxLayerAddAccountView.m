//
//  DSMapBoxLayerAddAccountView.m
//  MapBoxiPad
//
//  Created by Justin Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddAccountView.h"

#import "MapBoxConstants.h"

#import "ASIHTTPRequest.h"

#import "UIImage+Alpha.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxLayerAddAccountView

@synthesize delegate;
@synthesize featured;
@synthesize touched;

- (id)initWithFrame:(CGRect)rect imageURLs:(NSArray *)imageURLs labelText:(NSString *)labelText
{
    self = [super initWithFrame:rect];

    if (self)
    {
        // create front, inset image view
        //
        imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 10, rect.size.width - 20, rect.size.height - 20)] autorelease];
        
        imageView.image = [UIImage imageNamed:@"placeholder.png"];
        
        imageView.layer.shadowOpacity = 0.5;
        imageView.layer.shadowOffset  = CGSizeMake(-5, 5);
        imageView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:imageView.bounds] CGPath];
        
        [self addSubview:imageView];
        
        // create label
        //
        label = [[[UILabel alloc] initWithFrame:CGRectMake(0, imageView.bounds.size.height - 20, imageView.bounds.size.width, 20)] autorelease];
        
        label.font            = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        label.text            = [NSString stringWithFormat:@" %@", labelText];

        self.featured = NO;
        
        [imageView addSubview:label];
        
        // attach gestures
        //
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)] autorelease];        
        longPress.minimumPressDuration = 0.01;
        [self addGestureRecognizer:longPress];
        
        UIPinchGestureRecognizer *pinch = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)] autorelease];
        [self addGestureRecognizer:pinch];

        // fire off primary image download request
        //
        [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
        
        primaryImageRequest = [[ASIHTTPRequest requestWithURL:[imageURLs objectAtIndex:0]] retain];
        
        primaryImageRequest.delegate = self;
        
        [primaryImageRequest startAsynchronous];
        
        // save secondary image URLs for later
        //
        NSMutableArray *downloadURLs = [NSMutableArray arrayWithArray:imageURLs];
        [downloadURLs removeObjectAtIndex:0];
        previewImageURLs = [[NSArray arrayWithArray:downloadURLs] retain];
        
        secondaryImageRequests = [[NSMutableArray array] retain];
        
        // add preview views underneath
        //
        for (int i = 0; i < 3; i++)
        {
            UIImageView *preview = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder.png"]] autorelease];
            
            preview.frame = imageView.frame;
            
            // hide if not enough thumbnails
            //
            if (i >= [previewImageURLs count])
                preview.hidden = YES;
            
            [self insertSubview:preview belowSubview:imageView];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [previewImageURLs release];
    
    [primaryImageRequest clearDelegatesAndCancel];
    [primaryImageRequest release];
    
    if ([secondaryImageRequests count])
    {
        for (ASIHTTPRequest *request in secondaryImageRequests)
        {
            [request clearDelegatesAndCancel];
            [request release];
        }
    }
    
    [secondaryImageRequests release];
    
    [super dealloc];
}

#pragma mark -

- (void)setFeatured:(BOOL)flag
{
    if (flag)
    {
        CGColorRef color = CGColorCreateCopyWithAlpha([kMapBoxBlue CGColor], 0.8);
        
        label.backgroundColor = [UIColor colorWithCGColor:color];
        
        CGColorRelease(color);
        
        label.textColor = [UIColor blackColor];
    }
    else
    {
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textColor       = [UIColor whiteColor];
    }

    featured = flag;    
}

- (void)setTouched:(BOOL)flag
{
    if (flag)
    {
        // scale down
        //
        [UIView beginAnimations:nil context:nil];

        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.1];
        
        imageView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        
        [UIView commitAnimations];
    }
    else
    {
        // scale back up & push server view
        //
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:UIViewAnimationCurveEaseInOut
                         animations:^(void)
                         {
                             imageView.transform = CGAffineTransformScale(imageView.transform, 1 / 0.9, 1 / 0.9);
                         }
                         completion:^(BOOL selected)
                         {
                             [self.delegate accountViewWasSelected:self];
                         }];
    }
    
    // update state
    //
    touched = flag;
}

#pragma mark -

- (void)downloadSecondaryImages
{
    // queue up secondary image downloads
    //
    NSArray *rotationValues = [NSArray arrayWithObjects:[NSNumber numberWithInt:-3], [NSNumber numberWithInt:4], [NSNumber numberWithInt:-1], nil];
    
    for (int i = 0; i < [previewImageURLs count]; i++)
    {
        __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[previewImageURLs objectAtIndex:i]];
        
        [secondaryImageRequests addObject:request];
        
        [request setCompletionBlock:^(void)
        {
            UIImageView *preview = ((UIImageView *)[[self subviews] objectAtIndex:i]);

            UIImage *image = [UIImage imageWithData:request.responseData];
            
            // begin image mods
            //
            UIGraphicsBeginImageContext(preview.bounds.size);
            
            CGContextRef c = UIGraphicsGetCurrentContext();
            
            // fill background with white
            //
            CGContextAddPath(c, [[UIBezierPath bezierPathWithRect:preview.bounds] CGPath]);
            CGContextSetFillColorWithColor(c, [[UIColor whiteColor] CGColor]);
            CGContextFillPath(c);
            
            // draw tile
            //
            [image drawInRect:preview.bounds];
            
            image = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();

            // update image view (adding border to fix jaggies)
            //
            preview.image = [image transparentBorderImage:1];
            
            // style shadow
            //
            preview.layer.shadowOpacity = 0.5;
            preview.layer.shadowOffset  = CGSizeMake(-1, 1);
            preview.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:preview.bounds] CGPath];
            
            // animate offset rotation
            //
            [UIView beginAnimations:nil context:nil];
            
            preview.transform = CGAffineTransformMakeRotation(2 * M_PI * [[rotationValues objectAtIndex:i] intValue] / 360);
            
            [UIView commitAnimations];
        }];
        
        [request startAsynchronous];
    }
}

#pragma mark -

- (void)longPressGesture:(UIGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            self.touched = YES;
            break;
            
        case UIGestureRecognizerStateEnded:
            self.touched = NO;
            break;
            
        default:
            break;
    }
}

- (void)pinchGesture:(UIGestureRecognizer *)recognizer
{
    UIPinchGestureRecognizer *gesture = (UIPinchGestureRecognizer *)recognizer;

    if (gesture.state == UIGestureRecognizerStateBegan && [previewImageURLs count])
    {
        [self.superview bringSubviewToFront:self];
        
        originalCenter = self.center;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        
        label.alpha = 0.0;

        [UIView commitAnimations];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged && gesture.scale > 1.0)
    {
        if ([previewImageURLs count] == 0)
        {
            // disallow stack gesture since not a stack
            //
            UIView *frontView = ((UIView *)[self.subviews objectAtIndex:3]);

            // rotate up to 10 degrees
            //
            int rotation = ((gesture.scale - 1.0) * 10) > 10 ? 10 : ((gesture.scale - 1.0) * 10);
            
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.5];
            
            frontView.transform = CGAffineTransformMakeRotation(2 * M_PI * rotation / 360);
            
            [UIView commitAnimations];
        }
        else
        {
            // spread stack tiles apart
            //
            CGFloat distance = ((gesture.scale - 1.0) * 50) > 75 ? 75 : ((gesture.scale - 1.0) * 50);
            
            if ([gesture numberOfTouches] < 2)
            {
                gesture.enabled = NO;
                gesture.enabled = YES;
                
                return;
            }
            
            [UIView beginAnimations:nil context:nil];
            
            CGPoint pointA = [gesture locationOfTouch:0 inView:self.superview];
            CGPoint pointB = [gesture locationOfTouch:1 inView:self.superview];
            
            self.center = CGPointMake((pointA.x + pointB.x) / 2, (pointA.y + pointB.y) / 2);

            CGPoint myCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);

            ((UIView *)[self.subviews objectAtIndex:0]).center = CGPointMake(myCenter.x - distance, myCenter.y - distance);
            ((UIView *)[self.subviews objectAtIndex:1]).center = CGPointMake(myCenter.x + distance, myCenter.y - distance);
            ((UIView *)[self.subviews objectAtIndex:2]).center = CGPointMake(myCenter.x - distance, myCenter.y + distance);
            ((UIView *)[self.subviews objectAtIndex:3]).center = CGPointMake(myCenter.x + distance, myCenter.y + distance);

            [UIView commitAnimations];
        }
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
    {
        if ([previewImageURLs count] == 0)
        {
            // rotate single tile back into place
            //
            UIView *frontView = ((UIView *)[self.subviews objectAtIndex:3]);

            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.5];
            
            frontView.transform = CGAffineTransformMakeRotation(0);
            
            [UIView commitAnimations];
        }
        else
        {
            // swoop stack tiles back together
            //
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            [UIView setAnimationDuration:0.25];
            
            self.center = originalCenter;
            
            CGPoint myCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            
            for (int i = 0; i < 4; i++)
                ((UIView *)[self.subviews objectAtIndex:i]).center = myCenter;
            
            label.alpha = 1.0;

            [UIView commitAnimations];
        }
    }
}

#pragma mark -

- (void)requestFailed:(ASIHTTPRequest *)request
{
    // we can still try for the secondaries
    //
    [self downloadSecondaryImages];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    UIImage *tileImage = [UIImage imageWithData:request.responseData];

    [self downloadSecondaryImages];
    
    // process & update primary image
    //
    if (tileImage)
    {
        // get corner image
        //
        UIImage *cornerImage = [UIImage imageNamed:@"corner_fold.png"];
        
        // create cornered path
        //
        UIBezierPath *corneredPath = [UIBezierPath bezierPath];
        
        [corneredPath moveToPoint:CGPointMake(0, 0)];
        [corneredPath addLineToPoint:CGPointMake(imageView.bounds.size.width - cornerImage.size.width, 0)];
        [corneredPath addLineToPoint:CGPointMake(imageView.bounds.size.width, cornerImage.size.height)];
        [corneredPath addLineToPoint:CGPointMake(imageView.bounds.size.width, imageView.bounds.size.height)];
        [corneredPath addLineToPoint:CGPointMake(0, imageView.bounds.size.height)];
        [corneredPath closePath];

        // begin image mods
        //
        UIGraphicsBeginImageContext(imageView.bounds.size);
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        // fill background with white
        //
        CGContextAddPath(c, [corneredPath CGPath]);
        CGContextSetFillColorWithColor(c, [[UIColor whiteColor] CGColor]);
        CGContextFillPath(c);
        
        // clip corner of drawing
        //
        CGContextAddPath(c, [corneredPath CGPath]);
        CGContextClip(c);

        // draw tile
        //
        [tileImage drawInRect:imageView.bounds];

        UIImage *clippedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();

        // add image view for corner graphic
        //
        UIImageView *cornerImageView = [[[UIImageView alloc] initWithImage:cornerImage] autorelease];
        
        cornerImageView.frame = CGRectMake(imageView.bounds.size.width - cornerImageView.bounds.size.width, 0, cornerImageView.bounds.size.width, cornerImageView.bounds.size.height);
        
        // add shadow to corner image
        //
        UIBezierPath *cornerPath = [UIBezierPath bezierPath];
        
        [cornerPath moveToPoint:CGPointMake(0, 0)];
        [cornerPath addLineToPoint:CGPointMake(cornerImage.size.width, cornerImage.size.height)];
        [cornerPath addLineToPoint:CGPointMake(0, cornerImage.size.height)];
        [cornerPath closePath];
        
        cornerImageView.layer.shadowOpacity = 0.5;
        cornerImageView.layer.shadowOffset  = CGSizeMake(-1, 1);
        cornerImageView.layer.shadowPath    = [cornerPath CGPath];
        
        [imageView addSubview:cornerImageView];
        
        // cover tile for animated reveal
        //
        cornerImageView.hidden = YES;
        
        UIImageView *coverView = [[[UIImageView alloc] initWithFrame:self.bounds] autorelease];
        
        coverView.image = imageView.image;
        
        [self addSubview:coverView];
        
        // update tile
        //
        imageView.image = [clippedImage transparentBorderImage:1];
        
        // animate cover removal
        //
        [UIView animateWithDuration:0.1
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^(void)
                         {
                             imageView.layer.shadowPath = [corneredPath CGPath];
                             
                             cornerImageView.hidden = NO;
                             coverView.hidden       = YES;
                         }
                         completion:^(BOOL finished)
                         {
                             [coverView removeFromSuperview];
                         }];
    }
}

@end