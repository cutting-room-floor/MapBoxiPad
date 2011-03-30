//
//  MapBoxWindow.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "MapBoxWindow.h"

@implementation MapBoxWindow

@synthesize presentationView;

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];

    if (self != nil)
    {
        touches = [[NSMutableDictionary dictionary] retain];
        active  = [[UIScreen screens] count] > 1 ? YES : NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenConnect:)
                                                     name:UIScreenDidConnectNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(screenDisconnect:)
                                                     name:UIScreenDidDisconnectNotification
                                                   object:nil];
    }
        
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification    object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];
    
    [presentationView release];
    [touches release];
    
    [super dealloc];
}

#pragma mark -

- (void)screenConnect:(NSNotification *)notification
{
    active = YES;
}

- (void)screenDisconnect:(NSNotification *)notification
{
    active = [[UIScreen screens] count] > 1 ? YES : NO;
}

#pragma mark -

- (void)sendEvent:(UIEvent *)event
{
    if (active)
    {
        NSSet *allTouches = [event allTouches];
        
        for (UITouch *touch in [allTouches allObjects])
        {
            NSNumber *hash = [NSNumber numberWithUnsignedInteger:[touch hash]];
            
            if ([touches objectForKey:hash])
            {
                UIImageView *touchView = [touches objectForKey:hash];
                
                if ([touch phase] == UITouchPhaseEnded || [touch phase] == UITouchPhaseCancelled)
                {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.3];
                    
                    touchView.frame = CGRectMake(touchView.center.x - touchView.frame.size.width, 
                                                 touchView.center.y - touchView.frame.size.height, 
                                                 touchView.frame.size.width  * 2, 
                                                 touchView.frame.size.height * 2);

                    touchView.alpha = 0.0;
                    
                    [UIView commitAnimations];
                
                    [touchView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.3];
                    
                    [touches removeObjectForKey:hash];
                }
                else if ([touch phase] == UITouchPhaseMoved)
                {
                    touchView.center = [touch locationInView:presentationView];
                }
            }
            else if ([touch phase] == UITouchPhaseBegan)
            {
                UIImageView *touchView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"touch.png"]] autorelease];
                
                touchView.alpha = 0.5;
                
                [presentationView addSubview:touchView];
                
                touchView.center = [touch locationInView:presentationView];
                
                [touches setObject:touchView forKey:hash];
            }
        }
    }
    
    [super sendEvent:event];
}

@end