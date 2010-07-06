//
//  SimpleKMLLineString.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/6/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "SimpleKMLLineString.h"
#import <CoreLocation/CoreLocation.h>

extern NSString *SimpleKMLErrorDomain;

@implementation SimpleKMLLineString

@synthesize coordinates;

- (id)initWithXMLNode:(CXMLNode *)node error:(NSError **)error
{
    self = [super initWithXMLNode:node error:error];
    
    if (self != nil)
    {
        coordinates = nil;
        
        for (CXMLNode *child in [node children])
        {
            if ([[child name] isEqualToString:@"coordinates"])
            {
                NSMutableArray *parsedCoordinates = [NSMutableArray array];
                
                NSArray *coordinateStrings = [[child stringValue] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                
                for (NSString *coordinateString in coordinateStrings)
                {
                    if ([[coordinateString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length])
                    {
                        // coordinates should not have whitespace
                        //
                        if ([[coordinateString componentsSeparatedByString:@" "] count] > 1)
                        {
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (LineString coordinates have whitespace)" 
                                                                                 forKey:NSLocalizedFailureReasonErrorKey];
                            
                            *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                            
                            return nil;
                        }
                        
                        NSArray *parts = [coordinateString componentsSeparatedByString:@","];
                        
                        // there should be longitude, latitude, and optionally, altitude
                        //
                        if ([parts count] < 2 || [parts count] > 3)
                        {
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Invalid number of LineString coordinates)" 
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
                            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (Invalid LineString coordinates values)" 
                                                                                 forKey:NSLocalizedFailureReasonErrorKey];
                            
                            *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                            
                            return nil;
                        }
                        
                        CLLocation *coordinate = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
                        
                        [parsedCoordinates addObject:coordinate]; 
                    }
                }
                
                coordinates = [[NSArray arrayWithArray:parsedCoordinates] retain];
                
                // there should be two or more coordinates
                //
                if ([coordinates count] < 2)
                {
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (LineString has less than two coordinates)" 
                                                                         forKey:NSLocalizedFailureReasonErrorKey];
                    
                    *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
                    
                    return nil;
                }
            }
        }
        
        if ( ! coordinates)
        {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Improperly formed KML (LineString has no coordinates)" 
                                                                 forKey:NSLocalizedFailureReasonErrorKey];
            
            *error = [NSError errorWithDomain:SimpleKMLErrorDomain code:SimpleKMLParseError userInfo:userInfo];
            
            return nil;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [coordinates release];
    
    [super dealloc];
}

@end