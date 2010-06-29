//
//  SimpleKMLObject.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#object
//

#import <Foundation/Foundation.h>
#import "TouchXML.h"

@interface SimpleKMLObject : NSObject
{
    NSString *id;
}

@property (nonatomic, retain) NSString *id;

@end