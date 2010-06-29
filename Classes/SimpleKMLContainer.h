//
//  SimpleKMLContainer.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#container
//

#import "SimpleKMLFeature.h"

@interface SimpleKMLContainer : SimpleKMLFeature
{
    NSArray *features;
}

@property (nonatomic, retain) NSArray *features;

@end