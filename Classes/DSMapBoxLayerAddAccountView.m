//
//  DSMapBoxLayerAddAccountView.m
//  MapBoxiPad
//
//  Created by Justin Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddAccountView.h"

#import "UIImage+Alpha.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxLayerAddAccountView ()

@property (nonatomic, strong) NSArray *previewImageURLs;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSURLConnection *primaryImageDownload;
@property (nonatomic, strong) NSMutableArray *secondaryImageDownloads;
@property (nonatomic, assign) CGPoint originalCenter;
@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, assign) BOOL flicked;
@property (nonatomic, assign) BOOL touched;

- (void)downloadSecondaryImages;

@end

#pragma mark -

@implementation DSMapBoxLayerAddAccountView

@synthesize delegate;
@synthesize featured;
@synthesize previewImageURLs;
@synthesize imageView;
@synthesize label;
@synthesize primaryImageDownload;
@synthesize secondaryImageDownloads;
@synthesize originalCenter;
@synthesize originalSize;
@synthesize flicked;
@synthesize touched;

- (id)initWithFrame:(CGRect)rect imageURLs:(NSArray *)imageURLs labelText:(NSString *)labelText
{
    self = [super initWithFrame:rect];

    if (self)
    {
        // create front, inset image view
        //
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, rect.size.width - 20, rect.size.height - 20)];
        
        imageView.image = [UIImage imageNamed:@"placeholder.png"];
        
        imageView.layer.shadowOpacity = 0.5;
        imageView.layer.shadowOffset  = CGSizeMake(-5, 5);
        imageView.layer.shadowPath    = [[UIBezierPath bezierPathWithRect:imageView.bounds] CGPath];
        
        [self addSubview:imageView];
        
        // create label
        //
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, imageView.bounds.size.height - 21, imageView.bounds.size.width, 21)];
        
        label.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        label.text = [NSString stringWithFormat:@" %@", labelText];

        label.shadowOffset = CGSizeMake(0, 1);
        
        [self setFeatured:NO];
        
        [imageView addSubview:label];
        
        // attach flick open gesture
        //
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        [self addGestureRecognizer:pinch];

        // fire off primary image download request
        //
        DSMapBoxURLRequest *primaryImageRequest = [DSMapBoxURLRequest requestWithURL:[imageURLs objectAtIndex:0]];
        
        primaryImageRequest.timeoutInterval = 10;
        
        primaryImageDownload = [NSURLConnection connectionWithRequest:primaryImageRequest];
        
        __weak DSMapBoxLayerAddAccountView *selfCopy = self;
        
        primaryImageDownload.successBlock = ^(NSURLConnection *connection, NSURLResponse *response, NSData *responseData)
        {
            [DSMapBoxNetworkActivityIndicator removeJob:connection];
            
            UIImage *tileImage = [UIImage imageWithData:responseData];
            
            [selfCopy downloadSecondaryImages];
            
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
                [corneredPath addLineToPoint:CGPointMake(selfCopy.imageView.bounds.size.width - cornerImage.size.width, 0)];
                [corneredPath addLineToPoint:CGPointMake(selfCopy.imageView.bounds.size.width, cornerImage.size.height)];
                [corneredPath addLineToPoint:CGPointMake(selfCopy.imageView.bounds.size.width, selfCopy.imageView.bounds.size.height)];
                [corneredPath addLineToPoint:CGPointMake(0, selfCopy.imageView.bounds.size.height)];
                [corneredPath closePath];
                
                // begin image mods
                //
                UIGraphicsBeginImageContext(selfCopy.imageView.bounds.size);
                
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
                [tileImage drawInRect:selfCopy.imageView.bounds];
                
                UIImage *clippedImage = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
                
                // add image view for corner graphic
                //
                UIImageView *cornerImageView = [[UIImageView alloc] initWithImage:cornerImage];
                
                cornerImageView.frame = CGRectMake(selfCopy.imageView.bounds.size.width - cornerImageView.bounds.size.width, 0, cornerImageView.bounds.size.width, cornerImageView.bounds.size.height);
                
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
                
                [selfCopy.imageView addSubview:cornerImageView];
                
                // cover tile for animated reveal
                //
                cornerImageView.hidden = YES;
                
                UIImageView *coverView = [[UIImageView alloc] initWithFrame:selfCopy.bounds];
                
                coverView.image = selfCopy.imageView.image;
                
                [selfCopy addSubview:coverView];
                
                // update tile
                //
                selfCopy.imageView.image = [clippedImage transparentBorderImage:1];
                
                // animate cover removal
                //
                [UIView animateWithDuration:0.1
                                      delay:0.0
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^(void)
                                 {
                                     selfCopy.imageView.layer.shadowPath = [corneredPath CGPath];
                                     
                                     cornerImageView.hidden = NO;
                                     coverView.hidden       = YES;
                                 }
                                 completion:^(BOOL finished)
                                 {
                                     [coverView removeFromSuperview];
                                 }];
            }
        };
        
        primaryImageDownload.failureBlock = ^(NSURLConnection *connection, NSError *error)
        {
            [DSMapBoxNetworkActivityIndicator removeJob:connection];
            
            // we can still try for the secondaries
            //
            [selfCopy downloadSecondaryImages];
        };
        
        // save secondary image URLs for later
        //
        NSMutableArray *downloadURLs = [NSMutableArray arrayWithArray:imageURLs];
        [downloadURLs removeObjectAtIndex:0];
        previewImageURLs = [NSArray arrayWithArray:downloadURLs];
        
        secondaryImageDownloads = [NSMutableArray array];
        
        // add preview views underneath
        //
        NSArray *rotationValues = [NSArray arrayWithObjects:[NSNumber numberWithInt:-3], [NSNumber numberWithInt:4], [NSNumber numberWithInt:-1], nil];
        
        for (int i = 0; i < 3; i++)
        {
            UIImageView *preview = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder.png"]];
            
            preview.frame = imageView.frame;
            
            // hide if not enough thumbnails
            //
            if (i >= [previewImageURLs count])
                preview.hidden = YES;
            
            else
                preview.transform = CGAffineTransformMakeRotation(2 * M_PI * [[rotationValues objectAtIndex:i] intValue] / 360);
            
            [self insertSubview:preview belowSubview:imageView];
        }
        
        originalSize = rect.size;
        
        [DSMapBoxNetworkActivityIndicator addJob:primaryImageDownload];
        
        [primaryImageDownload start];
    }
    
    return self;
}

- (void)dealloc
{
    [DSMapBoxNetworkActivityIndicator removeJob:primaryImageDownload];
    
    for (NSURLConnection *download in secondaryImageDownloads)
        [DSMapBoxNetworkActivityIndicator removeJob:download];
}

#pragma mark -

- (void)setFeatured:(BOOL)flag
{
    if (flag)
    {
        CGColorRef color = CGColorCreateCopyWithAlpha([kMapBoxBlue CGColor], 0.8);
        
        self.label.backgroundColor = [UIColor colorWithCGColor:color];
        
        CGColorRelease(color);
        
        self.label.textColor   = [UIColor blackColor];
        self.label.shadowColor = [UIColor clearColor];
    }
    else
    {
        self.label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        self.label.textColor       = [UIColor whiteColor];
        self.label.shadowColor     = [UIColor blackColor];
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
    self.touched = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touched = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touched = NO;
    
    // this is timed to coincide with ending the scale up animation in setTouched:
    //
    [((NSObject *)self.delegate) performSelector:@selector(accountViewWasSelected:) withObject:self afterDelay:0.1];
}

#pragma mark -

- (void)pinchGesture:(UIGestureRecognizer *)recognizer
{
    UIPinchGestureRecognizer *gesture = (UIPinchGestureRecognizer *)recognizer;

    if (gesture.state == UIGestureRecognizerStateBegan && [self.previewImageURLs count])
    {
        [self.superview bringSubviewToFront:self];
        
        self.originalCenter = self.center;
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        
        self.label.alpha = 0.0;

        [UIView commitAnimations];
    }
    else if (gesture.state == UIGestureRecognizerStateChanged && gesture.scale > 1.0)
    {
        if ([self.previewImageURLs count] == 0)
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
            CGFloat kDistanceMax = 75.0;
            
            CGFloat distance = ((gesture.scale - 1.0) * 50) > kDistanceMax ? kDistanceMax : ((gesture.scale - 1.0) * 50);
            
            if ([gesture numberOfTouches] < 2)
            {
                // cancel to revert position
                //
                gesture.enabled = NO;
                gesture.enabled = YES;
                
                return;
            }
            
            if (distance == kDistanceMax && gesture.velocity > 40)
            {
                // flick gesture
                //
                self.flicked = YES;

                [UIView animateWithDuration:0.5
                                      delay:0.0
                                    options:UIViewAnimationCurveEaseInOut
                                 animations:^(void)
                                 {
                                     CGPoint myCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
                                     
                                     ((UIView *)[self.subviews objectAtIndex:0]).center = CGPointMake(myCenter.x - 2 * distance, myCenter.y - 2 * distance);
                                     ((UIView *)[self.subviews objectAtIndex:1]).center = CGPointMake(myCenter.x + 2 * distance, myCenter.y - 2 * distance);
                                     ((UIView *)[self.subviews objectAtIndex:2]).center = CGPointMake(myCenter.x - 2 * distance, myCenter.y + 2 * distance);
                                     ((UIView *)[self.subviews objectAtIndex:3]).center = CGPointMake(myCenter.x + 2 * distance, myCenter.y + 2 * distance);
                                     
                                     for (int i = 0; i < 4; i++)
                                         ((UIView *)[self.subviews objectAtIndex:i]).transform = CGAffineTransformScale(((UIView *)[self.subviews objectAtIndex:i]).transform, 1.2, 1.2);
                                         
                                     self.alpha = 0.0;
                                 }
                                 completion:^(BOOL finished)
                                 {
                                     // cancel gesture
                                     //
                                     gesture.enabled = NO;
                                     gesture.enabled = YES;

                                     // do the actual push
                                     //
                                     [self.delegate accountViewWasSelected:self];
                                 }];
                
                [TESTFLIGHT passCheckpoint:@"used flick gesture on TileStream account to browse"];
            }
            else
            {
                // regular spread gesture
                //
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
    }
    else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled)
    {
        if ([self.previewImageURLs count] == 0)
        {
            // rotate single tile back into place
            //
            UIView *frontView = ((UIView *)[self.subviews objectAtIndex:3]);

            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            [UIView setAnimationDuration:0.5];
            
            frontView.transform = CGAffineTransformMakeRotation(0);
            
            [UIView commitAnimations];
            
            [TESTFLIGHT passCheckpoint:@"tried pinch gesture on TileStream account with one set"];
        }
        else
        {
            // put stack tiles back together
            //
            if (self.flicked)
            {
                // invisibly on a delay for cleaning up after flicks
                //
                dispatch_delayed_ui_action(1.0, ^(void)
                {
                    self.center = self.originalCenter;

                    CGPoint myCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);

                    for (int i = 0; i < 4; i++)
                    {
                        UIView *subview = ((UIView *)[self.subviews objectAtIndex:i]);
                        
                        subview.transform = CGAffineTransformScale(subview.transform, 1 / 1.2, 1 / 1.2);
                        subview.center    = myCenter;
                    }

                    self.alpha = 1.0;
                    self.label.alpha = 1.0;

                    self.flicked = NO;
                });
            }
            else
            {
                // visibly animated swoop for normal spreads
                //
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                [UIView setAnimationDuration:0.25];
                
                self.center = self.originalCenter;
                
                CGPoint myCenter = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
                
                for (int i = 0; i < 4; i++)
                    ((UIView *)[self.subviews objectAtIndex:i]).center = myCenter;
                
                self.label.alpha = 1.0;

                [UIView commitAnimations];
                
                [TESTFLIGHT passCheckpoint:@"used pinch gesture on TileStream account to peek"];
            }
        }
    }
}

#pragma mark -

- (void)downloadSecondaryImages
{
    // queue up secondary image downloads
    //
    for (int i = 0; i < [self.previewImageURLs count]; i++)
    {
        DSMapBoxURLRequest *request = [DSMapBoxURLRequest requestWithURL:[self.previewImageURLs objectAtIndex:i]];
        
        request.timeoutInterval = 10;
        
        NSURLConnection *download = [NSURLConnection connectionWithRequest:request];
        
        [self.secondaryImageDownloads addObject:download];
        
        download.successBlock = ^(NSURLConnection *connection, NSURLResponse *response, NSData *responseData)
        {
            [DSMapBoxNetworkActivityIndicator removeJob:connection];
            
            UIImageView *preview = ((UIImageView *)[[self subviews] objectAtIndex:i]);
            
            UIImage *image = [UIImage imageWithData:responseData];
            
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
        };
        
        download.failureBlock = ^(NSURLConnection *connection, NSError *error)
        {
            [DSMapBoxNetworkActivityIndicator removeJob:connection];
        };
        
        [DSMapBoxNetworkActivityIndicator addJob:download];
        
        [download start];
    }
}

@end