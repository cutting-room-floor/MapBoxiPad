//
//  SimpleKML.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKML.h"
#import "SimpleKMLFeature.h"

NSString *const SimpleKMLErrorDomain = @"SimpleKMLErrorDomain";

@interface SimpleKML (SimpleKMLPrivate)

- (id)initWithContentsOfFile:(NSString *)path error:(NSError **)error;

@end

#pragma mark -

@implementation SimpleKML

@synthesize feature;

+ (SimpleKML *)KMLWithContentsofURL:(NSURL *)URL error:(NSError **)error
{
    return [[[self alloc] initWithContentsOfURL:URL error:error] autorelease];
}

+ (SimpleKML *)KMLWithContentsOfFile:(NSString *)path error:(NSError **)error
{
    return [[[self alloc] initWithContentsOfFile:path error:error] autorelease];
}

- (id)initWithContentsOfURL:(NSURL *)URL error:(NSError **)error
{
    self = [super init];
    
    if (self != nil)
    {
        feature = nil;
        
        NSError *parseError = nil;
        
        CXMLDocument *document = [[[CXMLDocument alloc] initWithContentsOfURL:URL
                                                                      options:0
                                                                        error:&parseError] autorelease];
        
        // return nil if we can't properly parse this file
        //
        if (parseError)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unable to parse XML: %@", parseError]
                                                                 forKey:NSLocalizedFailureReasonErrorKey];
            
            *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
            
            return nil;
        }
        
        CXMLElement *rootElement = [document rootElement];
        
        // the root <kml> element should only have 0 or 1 children, plus the <kml> open & close
        //
        if ([rootElement childCount] < 2 || [rootElement childCount] > 3)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (root element has invalid child object count)" 
                                                                 forKey:NSLocalizedFailureReasonErrorKey];
            
            *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
            
            return nil;
        }
        
        // build up our Feature if we have one
        //
        if ([rootElement childCount] == 3)
        {
            CXMLNode *featureNode = [rootElement childAtIndex:1];
            
            Class featureClass = NSClassFromString([NSString stringWithFormat:@"SimpleKML%@", [featureNode name]]);
            
            parseError = nil;
            
            feature = [[featureClass alloc] initWithXMLNode:featureNode error:&parseError];
            
            if (parseError)
            {
                *error = parseError;
                
                return nil;
            }
            
            // we can only handle Feature for now
            //
            if ( ! featureClass || ! [feature isKindOfClass:[SimpleKMLFeature class]])
            {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Root element contains a child object unknown to this library" 
                                                                     forKey:NSLocalizedFailureReasonErrorKey];
                
                *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLUnknownObject userInfo:userInfo];
                
                return nil;
            }
        }
    }
    
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path error:(NSError **)error
{
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:path] error:error];
}

- (void)dealloc
{
    [feature release];
    
    [super dealloc];
}

#pragma mark -

+ (UIColor *)colorForString:(NSString *)colorString;
{
    // color string should be eight or nine characters (RGBA in hex, with or without '#' prefix)
    //
    if ([colorString length] < 8 || [colorString length] > 9)
        return nil;
    
    colorString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    NSMutableArray *parts = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < 8; i = i + 2)
    {
        NSString *part = [colorString substringWithRange:NSMakeRange(i, 2)];
        
        unsigned wholeValue;
        
        [[NSScanner scannerWithString:part] scanHexInt:&wholeValue];
        
        if (wholeValue < 0 || wholeValue > 255)
            return nil;
        
        [parts addObject:[NSNumber numberWithFloat:((CGFloat)wholeValue / (CGFloat)255)]];
    }
    
    UIColor *color = [UIColor colorWithRed:[[parts objectAtIndex:3] floatValue]
                                     green:[[parts objectAtIndex:2] floatValue]
                                      blue:[[parts objectAtIndex:1] floatValue]
                                     alpha:[[parts objectAtIndex:0] floatValue]];
    
    return color;
}

@end