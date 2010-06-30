//
//  SimpleKML.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#kml
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"

@class SimpleKMLFeature;

@interface SimpleKML : NSObject
{
    SimpleKMLFeature *feature;
}

@property (nonatomic, retain) SimpleKMLFeature *feature;

+ (SimpleKML *)kmlWithContentsOfFile:(NSString *)path error:(NSError **)error;

@end