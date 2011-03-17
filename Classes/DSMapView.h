//
//  DSMapView.h
//  MapBoxiPad
//
//  Created by Justin R. Miller on 3/8/11.
//  Copyright 2011 Code Sorcery Workshop. All rights reserved.
//

#import "RMMapView.h"

@interface DSMapView : RMMapView
{
    id currentInteractivityValue;
}

@property (nonatomic, retain) id currentInteractivityValue;

@end