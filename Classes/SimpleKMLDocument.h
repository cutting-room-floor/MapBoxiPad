//
//  SimpleKMLDocument.h
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//
//  http://code.google.com/apis/kml/documentation/kmlreference.html#document
//

#import "SimpleKMLContainer.h"

@class SimpleKMLStyle;

@interface SimpleKMLDocument : SimpleKMLContainer
{
    NSArray *sharedStyles;
}

// abstract class

@property (nonatomic, retain) NSArray *sharedStyles;

- (SimpleKMLStyle *)sharedStyleWithID:(NSString *)styleID;

@end