//
//  DSMapBoxLayerAddTileView.m
//  MapBoxiPad
//
//  Created by Justin Miller on 6/29/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddTileView.h"

#import "ASIHTTPRequest.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLayerAddTileView ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) ASIHTTPRequest *imageRequest;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL touched;

@end

#pragma mark -

@implementation DSMapBoxLayerAddTileView

@synthesize delegate;
@synthesize image;
@synthesize imageView;
@synthesize label;
@synthesize imageRequest;
@synthesize originalSize;
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
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, rect.size.width - 20, rect.size.height - 20)];
        
        imageView.image = [UIImage imageNamed:@"placeholder.png"];
        
        imageView.layer.shadowOpacity = 0.5;
        imageView.layer.shadowOffset  = CGSizeMake(-5, 5);
        imageView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:imageView.bounds] CGPath];

        [self addSubview:imageView];

        image = imageView.image;
        
        // create label
        //
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, imageView.bounds.size.height - 20, imageView.bounds.size.width, 20)];
        
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textColor       = [UIColor whiteColor];
        label.font            = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        label.text            = [NSString stringWithFormat:@" %@", labelText];
        
        [imageView addSubview:label];
        
        if ( ! [imageURL isEqual:[NSNull null]])
        {
            // attach pinch preview gesture
            //
            UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
            [self addGestureRecognizer:pinch];

            // fire off image download request
            //
            imageRequest = [ASIHTTPRequest requestWithURL:imageURL];
            
            imageRequest.timeOutSeconds = 10;
            imageRequest.delegate = self;
            
            [imageRequest startAsynchronous];
            
            [DSMapBoxNetworkActivityIndicator addJob:imageRequest];
        }
        else
        {
            // add empty image
            //
            UIImageView *emptyView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, rect.size.width - 20, rect.size.height - 20)];
            
            emptyView.image = [UIImage imageNamed:@"empty.png"];

            [self addSubview:emptyView];

            // fill image view itself with solid white
            //
            UIGraphicsBeginImageContext(imageView.bounds.size);
            
            CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(), [[UIColor whiteColor] CGColor]);
            
            CGContextFillRect(UIGraphicsGetCurrentContext(), imageView.bounds);
            
            imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            // disable & grey out
            //
            self.userInteractionEnabled = NO;
            self.alpha = 0.75;
        }
        
        originalSize = rect.size;
    }
    
    return self;
}

- (void)dealloc
{
    [DSMapBoxNetworkActivityIndicator removeJob:imageRequest];
    
    [imageRequest clearDelegatesAndCancel];
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
        // scale down
        //
        [UIView beginAnimations:nil context:nil];

        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.1];
        
        self.imageView.transform = CGAffineTransformMakeScale(self.originalSize.width / self.frame.size.width * 0.9, self.originalSize.height / self.frame.size.height * 0.9);
        
        [UIView commitAnimations];
    }
    else
    {
        // scale back up
        //
        [UIView beginAnimations:nil context:nil];
        
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.1];
        
        self.imageView.transform = CGAffineTransformScale(self.imageView.transform, self.originalSize.width / self.frame.size.width / 0.9, self.originalSize.height / self.frame.size.height / 0.9);
        
        [UIView commitAnimations];
    }
    
    // update state
    //
    touched = flag;
}

#pragma mark -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // ignore top corner preview tap
    //
    if ([[touches anyObject] locationInView:self].x < self.bounds.size.width - 50 && [[touches anyObject] locationInView:self].y > 50)
    {
        self.touched  = YES;
        self.selected = ! self.selected;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.touched)
    {
        self.touched  = NO;
        self.selected = ! self.selected;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // catch top corner preview tap
    //
    if ([[touches anyObject] locationInView:self].x >= self.bounds.size.width - 50 && [[touches anyObject] locationInView:self].y <= 50)
    {
        // bring to front
        //
        [self.superview bringSubviewToFront:self];
        
        // go straight to preview
        //
        [self.delegate tileViewWantsToShowPreview:self];
        
        [TESTFLIGHT passCheckpoint:@"tapped TileStream layer corner to preview"];
    }

    else if (self.touched)
        self.touched = NO;
}

#pragma mark -

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
        
        [TESTFLIGHT passCheckpoint:@"used pinch gesture to preview TileStream layer"];
    }
}

#pragma mark -

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [DSMapBoxNetworkActivityIndicator removeJob:request];
    
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
        [corneredPath addLineToPoint:CGPointMake(self.imageView.bounds.size.width - cornerImage.size.width, 0)];
        [corneredPath addLineToPoint:CGPointMake(self.imageView.bounds.size.width, cornerImage.size.height)];
        [corneredPath addLineToPoint:CGPointMake(self.imageView.bounds.size.width, self.imageView.bounds.size.height)];
        [corneredPath addLineToPoint:CGPointMake(0, self.imageView.bounds.size.height)];
        [corneredPath closePath];

        // begin image mods
        //
        UIGraphicsBeginImageContext(self.imageView.bounds.size);
        
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        // fill background with white
        //
        CGContextAddPath(c, [[UIBezierPath bezierPathWithRect:self.imageView.bounds] CGPath]);
        CGContextSetFillColorWithColor(c, [[UIColor whiteColor] CGColor]);
        CGContextFillPath(c);
        
        // store unclipped version for later & reset context
        //
        [tileImage drawInRect:self.imageView.bounds];
        
        self.image = UIGraphicsGetImageFromCurrentImageContext();
        
        CGContextClearRect(c, self.imageView.bounds);
        
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
        [tileImage drawInRect:self.imageView.bounds];

        UIImage *clippedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();

        // add image view for corner graphic
        //
        UIImageView *cornerImageView = [[UIImageView alloc] initWithImage:cornerImage];
        
        cornerImageView.frame = CGRectMake(self.imageView.bounds.size.width - cornerImageView.bounds.size.width, 0, cornerImageView.bounds.size.width, cornerImageView.bounds.size.height);
        
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
        
        [self.imageView addSubview:cornerImageView];
        
        // update tile
        //
        self.imageView.image = clippedImage;
        
        // animate cover removal
        //
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration:0.1];
        
        self.imageView.layer.shadowPath = [corneredPath CGPath];
        cornerImageView.hidden = NO;

        [UIView commitAnimations];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    [DSMapBoxNetworkActivityIndicator removeJob:request];
}

@end