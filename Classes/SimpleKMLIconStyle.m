//
//  SimpleKMLIconStyle.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLIconStyle.h"
#import "SimpleKML_UIImage.h"

#define kSimpleKMLIconStyleDefaultScale    1.0f
#define kSimpleKMLIconStyleDefaultHeading  0.0f
#define kSimpleKMLIconStyleBaseIconSize   32.0f

extern NSString *SimpleKMLErrorDomain;

@implementation SimpleKMLIconStyle

@synthesize icon;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        icon = nil;
        
        UIImage *baseIcon   = nil;
        CGFloat baseScale   = kSimpleKMLIconStyleDefaultScale;
        CGFloat baseHeading = kSimpleKMLIconStyleDefaultHeading;
        
#pragma mark TODO: read in parent ColorStyle color & auto-apply to icon
        
        for (CXMLNode *child in [node children])
        {
#pragma mark TODO: we should be case folding here
            if ([[child name] isEqualToString:@"Icon"])
            {
#pragma mark TODO: only read in a given URL once
                
                if ([child childCount] != 3)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (no href specified for IconStyle Icon)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
                
                CXMLNode *href = [child childAtIndex:1];
                
                NSURL *imageURL = [NSURL URLWithString:[href stringValue]];
                
                if ( ! imageURL)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (invalid icon URL specified in IconStyle)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
                
                NSData *data = [NSData dataWithContentsOfURL:imageURL];
                
                baseIcon = [UIImage imageWithData:data];
                
                if ( ! baseIcon)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (unable to retrieve icon specified for IconStyle)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
            }
            else if ([[child name] isEqualToString:@"scale"])
            {
                baseScale = (CGFloat)[[child stringValue] floatValue];

                if (baseScale <= 0)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (invalid icon scale specified in IconStyle)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
            }
            else if ([[child name] isEqualToString:@"heading"])
            {
                baseHeading = (CGFloat)[[child stringValue] floatValue];

                if (baseHeading < 0 || baseHeading > 360)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (invalid icon heading specified in IconStyle)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
            }
        }
        
#pragma mark TODO: rotate image according to heading

        CGFloat newWidth  = kSimpleKMLIconStyleBaseIconSize * baseScale;
        CGFloat newHeight = kSimpleKMLIconStyleBaseIconSize * baseScale;
        
        icon = [[baseIcon imageWithWidth:newWidth height:newHeight] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [icon release];
    
    [super dealloc];
}




@end