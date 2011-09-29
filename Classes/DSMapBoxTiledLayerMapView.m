//
//  DSMapBoxTiledLayerMapView.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Development Seed. All rights reserved.
//

#import "DSMapBoxTiledLayerMapView.h"

#import "RMMarker.h"

@interface RMMapView (DSMapBoxTiledLayerMapView)

- (void)performInitialSetup;

@end

#pragma mark -

@interface DSMapBoxTiledLayerMapView ()

- (BOOL)checkForOverlayTouches:(NSSet *)touches;

@end

#pragma mark -

@implementation DSMapBoxTiledLayerMapView

@synthesize masterView;
@synthesize tileSetURL;

- (void)dealloc
{
    [masterView release];
    [tileSetURL release];
    
    [super dealloc];
}

#pragma mark -

- (void)setMasterView:(DSMapView *)mapView
{
    NSAssert(([mapView isMemberOfClass:[DSMapView class]] || ! mapView), @"Master view must be an instance of DSMapView or nil");
    
    [masterView release];
    masterView = [mapView retain];
    
    if (mapView)
        self.userInteractionEnabled = YES;
    
    else
        self.userInteractionEnabled = NO;
}

#pragma mark -

- (void)performInitialSetup
{
    [super performInitialSetup];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.userInteractionEnabled = NO;
    self.opaque = NO;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self checkForOverlayTouches:touches])
        [super touchesBegan:touches withEvent:event];

    else
        [self.masterView touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self checkForOverlayTouches:touches])
        [super touchesCancelled:touches withEvent:event];

    else
        [self.masterView touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([self checkForOverlayTouches:touches])
        [super touchesEnded:touches withEvent:event];

    else
        [self.masterView touchesEnded:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // don't allow moves on the marker overlay
    //
    [self.masterView touchesMoved:touches withEvent:event];
}

#pragma mark -

- (BOOL)checkForOverlayTouches:(NSSet *)touches
{
    /**
     * This is copied from RMMapView to determine whether our touches
     * were on just us or on our overlay view (i.e., markers).
     */

    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    
	id furthestLayerDown = [self.contents.overlay hitTest:[touch locationInView:self]];
	
    return [[furthestLayerDown class] isSubclassOfClass:[RMMarker class]];
}
    
@end