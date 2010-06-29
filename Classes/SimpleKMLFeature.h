//
//  SimpleKMLFeature.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#feature
//

#import "SimpleKMLObject.h"

@class SimpleKMLStyle;

@interface SimpleKMLFeature : SimpleKMLObject
{
    NSString *name;
    NSString *description;
    SimpleKMLStyle *style;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) SimpleKMLStyle *style;

@end