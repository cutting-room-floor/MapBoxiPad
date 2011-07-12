//
//  DSMapBoxLayerAddAccountView.m
//  MapBoxiPad
//
//  Created by Justin Miller on 7/11/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxLayerAddAccountView.h"

#import "MapBoxConstants.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapBoxLayerAddAccountView

@synthesize delegate;
@synthesize image;
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
        
        // create label
        //
        label = [[[UILabel alloc] initWithFrame:CGRectMake(0, imageView.bounds.size.height - 20, imageView.bounds.size.width, 20)] autorelease];
        
        label.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.textColor       = [UIColor whiteColor];
        label.font            = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
        label.text            = [NSString stringWithFormat:@" %@", labelText];
        
        [imageView addSubview:label];
        
        // fire off image download request
        //
        [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:imageURL] delegate:self];
    }
    
    return self;
}

#pragma mark -

- (UIImage *)image
{
    return imageView.image;
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
}

#pragma mark -

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // TODO: detect if offline and/or retry
    //
    NSLog(@"%@", error);
    
    [connection autorelease];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    receivedData = [[NSMutableData data] retain];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [connection autorelease];
    
    UIImage *tileImage = [UIImage imageWithData:receivedData];
    
    [receivedData release];
    
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
        imageView.image = clippedImage;
        
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