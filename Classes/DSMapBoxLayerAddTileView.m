//
//  DSMapBoxLayerAddTileView.m
//  MapBoxiPad
//
//  Created by Justin Miller on 6/29/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddTileView.h"

#import "MapBoxConstants.h"

#import "ASIHTTPRequest.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxLayerAddTileView

@synthesize delegate;
@synthesize image;
@synthesize selected;
@synthesize touched;

- (id)initWithFrame:(CGRect)rect imageURL:(NSURL *)imageURL labelText:(NSString *)labelText
{
    self = [super initWithFrame:rect];

    if (self)
    {
        // prep selection indicator
        //
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 10.0;
        
        // create inset image view
        //
        imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 10, rect.size.width - 20, rect.size.height - 20)] autorelease];
        
        imageView.image = [UIImage imageNamed:@"placeholder.png"];
        
        imageView.layer.shadowOpacity = 0.5;
        imageView.layer.shadowOffset  = CGSizeMake(-5, 5);
        imageView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:imageView.bounds] CGPath];

        [self addSubview:imageView];

        image = [imageView.image retain];
        
        // create label
        //
        label = [[[UILabel alloc] initWithFrame:CGRectMake(0, imageView.bounds.size.height - 20, imageView.bounds.size.width, 20)] autorelease];
        
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textColor       = [UIColor whiteColor];
        label.font            = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        label.text            = [NSString stringWithFormat:@" %@", labelText];
        
        [imageView addSubview:label];
        
        // attach gesture
        //
        UILongPressGestureRecognizer *longPress = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)] autorelease];        
        longPress.minimumPressDuration = 0.05;
        [self addGestureRecognizer:longPress];
        
        UIPinchGestureRecognizer *pinch = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)] autorelease];
        [self addGestureRecognizer:pinch];

        // fire off image download request
        //
        [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
        
        imageRequest = [[ASIHTTPRequest requestWithURL:imageURL] retain];
        
        imageRequest.timeOutSeconds = 10;
        imageRequest.delegate = self;
        
        [imageRequest startAsynchronous];
    }
    
    return self;
}

- (void)dealloc
{
    [imageRequest clearDelegatesAndCancel];
    [imageRequest release];
    [image release];
    
    [super dealloc];
}

#pragma mark -

- (void)setSelected:(BOOL)flag
{
    // set flag
    //
    selected = flag;
    
    // animate background color change
    //
    [UIView beginAnimations:nil context:nil];
    
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.1];
    
    self.backgroundColor = (flag ? kMapBoxBlue : [UIColor clearColor]);
    
    [UIView commitAnimations];

    // notify delegate
    //
    if (self.delegate)
        [self.delegate tileView:self selectionDidChange:flag];
}

- (void)setTouched:(BOOL)flag
{
    if (flag)
    {
        // toggle selection
        //
        self.selected = ! self.selected;
        
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
        // scale back up
        //
        [UIView beginAnimations:nil context:nil];
        
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.1];
        
        imageView.transform = CGAffineTransformScale(imageView.transform, 1 / 0.9, 1 / 0.9);
        
        [UIView commitAnimations];
    }
    
    // update state
    //
    touched = flag;
}

#pragma mark -

- (void)longPressGesture:(UIGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            
            // top corner preview
            //
            if ([recognizer locationInView:self].x >= self.bounds.size.width - 50 && [recognizer locationInView:self].y <= 50)
            {
                // cancel gesture to avoid any animation
                //
                recognizer.enabled = NO;
                recognizer.enabled = YES;
                
                // go straight to preview
                //
                [self.delegate tileViewWantsToShowPreview:self];
            }
            
            else
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
    
    if (gesture.state == UIGestureRecognizerStateChanged && gesture.scale > 1.0)
    {
        // cancel gesture to avoid any animation
        //
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        
        // bring to front
        //
        [self.superview bringSubviewToFront:self];
        
        // go straight to preview
        //
        [self.delegate tileViewWantsToShowPreview:self];
    }
}

#pragma mark -

- (void)requestFinished:(ASIHTTPRequest *)request
{
    UIImage *tileImage = [UIImage imageWithData:request.responseData];
    
    if (tileImage)
    {
        // get corner image
        //
        UIImage *cornerImage = [UIImage imageNamed:@"corner_fold_preview.png"];
        
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
        CGContextAddPath(c, [[UIBezierPath bezierPathWithRect:imageView.bounds] CGPath]);
        CGContextSetFillColorWithColor(c, [[UIColor whiteColor] CGColor]);
        CGContextFillPath(c);
        
        // store unclipped version for later & reset context
        //
        [tileImage drawInRect:imageView.bounds];
        
        [image release];
        
        image = [UIGraphicsGetImageFromCurrentImageContext() retain];
        
        CGContextClearRect(c, imageView.bounds);
        
        // fill background with white again, but cornered
        //
        CGContextAddPath(c, [corneredPath CGPath]);
        CGContextSetFillColorWithColor(c, [[UIColor whiteColor] CGColor]);
        CGContextFillPath(c);

        // clip corner of drawing
        //
        CGContextAddPath(c, [corneredPath CGPath]);
        CGContextClip(c);

        // draw again for our display
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
        
        // update tile
        //
        imageView.image = clippedImage;
        
        // animate cover removal
        //
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.1];
        
        imageView.layer.shadowPath = [corneredPath CGPath];
        cornerImageView.hidden = NO;

        [UIView commitAnimations];
    }
}

@end