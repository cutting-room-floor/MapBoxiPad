//
//  SimpleKMLObject.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLObject.h"

@interface SimpleKMLObject (SimpleKMLObjectPrivate)

- (NSString *)cachePath;

@end

#pragma mark -

@implementation SimpleKMLObject

@synthesize objectID;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super init];
    
    if (self != nil)
    {
        source = [[NSString stringWithString:[node XMLString]] retain];
        
        objectID = [[[[((CXMLElement *)node) attributeForName:@"id"] stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] retain];
    }
    
#pragma mark TODO: assert that abstract classes aren't being instantiated
    
    return self;
}

- (void)dealloc
{
    [source release];
    [objectID release];
    
    [super dealloc];
}

#pragma mark -

- (void)setCacheObject:(id)object forKey:(NSString *)key
{
    NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfFile:[self cachePath]];
    
    if ( ! cache)
        cache = [NSMutableDictionary dictionary];
    
    [cache setObject:object forKey:key];
    
    [cache writeToFile:[self cachePath] atomically:YES];
}

- (id)cacheObjectForKey:(NSString *)key
{
    NSMutableDictionary *cache = [NSMutableDictionary dictionaryWithContentsOfFile:[self cachePath]];

    return [cache objectForKey:key];
}

- (NSString *)cachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    return [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], [self class]];
}

@end