//
//  DSMapView.m
//  MapBoxiPad
//
//  Created by Justin R. Miller on 3/8/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapView.h"

#import "RMMBTilesTileSource.h"

#import <QuartzCore/QuartzCore.h>

@implementation DSMapView

@synthesize currentInteractivityValue;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // single touch on an interactive tile set
    //
    if ([touches count] == 1 && 
        [self.contents.tileSource isKindOfClass:[RMMBTilesTileSource class]] && 
        [((RMMBTilesTileSource *)self.contents.tileSource) supportsInteractivity])
    {
        // convert touch to map view
        //
        CGPoint touchPoint = [[[touches allObjects] lastObject] locationInView:self];

        // determine renderer scroll layer sub-layer touched
        //
        CALayer *rendererLayer = [self.contents.renderer valueForKey:@"layer"];
        CALayer *tileLayer     = [rendererLayer hitTest:touchPoint];
        
        // convert touch to sub-layer
        //
        CGPoint layerPoint = [tileLayer convertPoint:touchPoint fromLayer:rendererLayer];

        // normalize tile touch to 256px
        //
        float normalizedX = (layerPoint.x / tileLayer.bounds.size.width)  * 256;
        float normalizedY = (layerPoint.y / tileLayer.bounds.size.height) * 256;
        
        // determine lat & lon of touch
        //
        CLLocationCoordinate2D touchLocation = [self.contents pixelToLatLong:touchPoint];
        
        // use lat & lon to determine TMS tile (per http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames)
        //
        int tileZoom = (int)(roundf(self.contents.zoom));
        
        int tileX = (int)(floor((touchLocation.longitude + 180.0) / 360.0 * pow(2.0, tileZoom)));
        int tileY = (int)(floor((1.0 - log(tan(touchLocation.latitude * M_PI / 180.0) + 1.0 / \
                           cos(touchLocation.latitude * M_PI / 180.0)) / M_PI) / 2.0 * pow(2.0, tileZoom)));
        
        tileY = pow(2.0, tileZoom) - tileY - 1.0;
        
        RMTile tile = {
            .zoom = tileZoom,
            .x    = tileX,
            .y    = tileY,
        };

        // fetch interactivity data for tile & point in it
        //
        CGPoint tilePoint = CGPointMake(normalizedX, normalizedY);
        
        NSDictionary *interactivityData = [((RMMBTilesTileSource *)self.contents.tileSource) interactivityDataForPoint:tilePoint inTile:tile];
        
        // TODO: run interactivity data through the tile source formatter function
        //
        if (interactivityData)
            self.currentInteractivityValue = [interactivityData objectForKey:@"data"];
        
        else
            self.currentInteractivityValue = @"";
    }

    // all other touches behave normally
    //
    else
        [super touchesBegan:touches withEvent:event];
}

- (void)dealloc
{
    [currentInteractivityValue release];
    
    [super dealloc];
}

@end