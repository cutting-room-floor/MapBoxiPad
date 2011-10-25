//
//  DSSound.m
//  MapBoxiPad
//
//  Created by Justin Miller on 7/1/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSSound.h"

#import <AudioToolbox/AudioToolbox.h>

@interface DSSound ()

void DSSound_SoundCompletionProc(SystemSoundID sound, void *clientData);

@end

#pragma mark -

@implementation DSSound

+ (void)playSoundNamed:(NSString *)soundName
{
    NSString *type = [soundName pathExtension];
    NSString *base = [soundName stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", type]
                                                          withString:@"" 
                                                             options:NSBackwardsSearch & NSAnchoredSearch 
                                                               range:NSMakeRange(0, [soundName length])];
    
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:base ofType:type]];

    SystemSoundID sound;
    
    AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &sound);
    
    AudioServicesAddSystemSoundCompletion(sound, NULL, NULL, DSSound_SoundCompletionProc, self);
    
    AudioServicesPlaySystemSound(sound);
}

#pragma mark -

void DSSound_SoundCompletionProc(SystemSoundID sound, void *clientData)
{
    AudioServicesDisposeSystemSoundID(sound);
}

@end