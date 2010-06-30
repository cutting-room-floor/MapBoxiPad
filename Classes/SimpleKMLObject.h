//
//  SimpleKMLObject.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#object
//

#import "SimpleKML.h"

@interface SimpleKMLObject : NSObject
{
    @protected
        NSString *source;
    
    @public
        NSString *objectID;
}

@property (nonatomic, retain) NSString *objectID;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error;

@end