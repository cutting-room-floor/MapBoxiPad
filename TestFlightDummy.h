//
//  TestFlightDummy.h
//  MapBoxiPad
//
//  Created by Justin Miller on 9/26/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

@interface TestFlight : NSObject
{    
}

+ (void)addCustomEnvironmentInformation:(NSString *)information forKey:(NSString*)key;
+ (void)takeOff:(NSString *)teamToken;
+ (void)setOptions:(NSDictionary*)options;
+ (void)passCheckpoint:(NSString *)checkpointName;
+ (void)openFeedbackView;

@end