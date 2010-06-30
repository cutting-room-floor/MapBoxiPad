//
//  SimpleKMLPoint.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/29/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLPoint.h"

extern NSString *SimpleKMLErrorDomain;

@implementation SimpleKMLPoint

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        location = nil;
        
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"coordinates"])
            {
                NSString *coordinatesString = [child stringValue];
                
                // coordinates should not have whitespace
                //
                if ([[coordinatesString componentsSeparatedByString:@" "] count] > 1)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Point coordinates have whitespace)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
                
                NSArray *parts = [coordinatesString componentsSeparatedByString:@","];

                // there should be longitude, latitude, and optionally, altitude
                //
                if ([parts count] < 2 || [parts count] > 3)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Invalid number of Point coordinates)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
                
                double longitude = [[parts objectAtIndex:0] doubleValue];
                double latitude  = [[parts objectAtIndex:1] doubleValue];
                
                // there should be valid values for latitude & longitude
                //
                if (longitude < -180 || longitude > 180 || latitude < -90 || latitude > 90)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Invalid Point coordinates values)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
                
                location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            }
        }
        
        if ( ! location)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Point has no coordinates)" 
                                                                 forKey:NSLocalizedFailureReasonErrorKey];
            
            *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
            
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [location release];
    
    [super dealloc];
}

#pragma mark -

- (CLLocationCoordinate2D)coordinate
{
    return location.coordinate;
}

@end