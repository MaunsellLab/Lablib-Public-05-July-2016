//
//  LLSounds.m
//  Lablib
//
//  Created by John Maunsell on Sat Aug 23 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLSounds.h"

@implementation LLSounds

- (void)dealloc {

	[sounds release];
	[super dealloc];
}

- (id)init {

	if ((self = [super init]) != nil) {
	
// Create the sounds dictionary and fill it with default entries

		sounds = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			@"6C", 	@"LLFixOnSound",	
			nil];
	}
	return self;
}

- (void)playSound:(NSString *)soundKey {

	NSString *soundName;
	
	soundName = [sounds objectForKey:soundKey];
	if (soundName != nil) {
		NSLog(@"Playing sound called %@ with path %@", soundKey, soundName);
		theSound = [NSSound soundNamed:soundName];
		[[NSSound soundNamed:soundName] play];
	}
}

@end
