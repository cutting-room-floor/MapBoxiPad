//
//  DSTiledLayerMapView.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/26/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "RMMapView.h"

@interface DSTiledLayerMapView : RMMapView
{
    /* Setting this to another map view will cause us to respond to overlay 
     * (i.e., marker) touches, but not regular pan/zoom touches. Those instead will
     * be forwarded to the master map view.
     *
     * Not setting this will cause us to pass user touches as if we didn't exist.
     *
     * This is useful for tile layer map views where we want to the top-most one
     * to own the markers & their touch events, but to pass pan/zoom events to the 
     * master who will move us implicitly.
     */

    RMMapView *masterView;
}

@property (nonatomic, retain) RMMapView *masterView;

@end