//
//  SimpleKMLColorStyle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLColorStyle.h"

extern NSString *SimpleKMLErrorDomain;

@implementation SimpleKMLColorStyle

@synthesize color;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        color = nil;
        
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"color"])
            {
                NSString *colorString = [child stringValue];
                
                // color string should be eight or nine characters (RGBA in hex, with or without '#' prefix)
                //
                if ([colorString length] < 8 || [colorString length] > 9)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (ColorStyle color specifier is invalid length)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }

                colorString = [colorString stringByReplacingOccurrencesOfString:@"#" withString:@""];
                
                NSMutableArray *parts = [NSMutableArray array];
                
                for (NSUInteger i = 0; i < 8; i = i + 2)
                {
                    NSString *part = [colorString substringWithRange:NSMakeRange(i, 2)];
                    
                    unsigned wholeValue;
                    
                    [[NSScanner scannerWithString:part] scanHexInt:&wholeValue];
                    
                    if (wholeValue < 0 || wholeValue > 255)
                    {
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Invalid ColorStyle color specifier)" 
                                                                             forKey:NSLocalizedFailureReasonErrorKey];
                        
                        *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                        
                        return nil;
                    }
                    
                    [parts addObject:[NSNumber numberWithFloat:((CGFloat)wholeValue / (CGFloat)255)]];
                }
                
                color = [[UIColor colorWithRed:[[parts objectAtIndex:0] floatValue]
                                         green:[[parts objectAtIndex:1] floatValue]
                                          blue:[[parts objectAtIndex:2] floatValue]
                                         alpha:[[parts objectAtIndex:3] floatValue]] retain];
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    [color release];
    
    [super dealloc];
}

@end