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
@class SimpleKMLContainer;
@class SimpleKMLDocument;

@interface SimpleKMLFeature : SimpleKMLObject
{
    NSString *name;
    NSString *featureDescription;
    NSString *sharedStyleID;
    SimpleKMLStyle *sharedStyle;
    SimpleKMLStyle *inlineStyle;
    SimpleKMLContainer *container;
    SimpleKMLDocument *document;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *featureDescription;
@property (nonatomic, retain) NSString *sharedStyleID;
@property (nonatomic, assign) SimpleKMLStyle *sharedStyle;
@property (nonatomic, assign) SimpleKMLStyle *inlineStyle;
@property (nonatomic, assign) SimpleKMLContainer *container;
@property (nonatomic, assign) SimpleKMLDocument *document;

@end