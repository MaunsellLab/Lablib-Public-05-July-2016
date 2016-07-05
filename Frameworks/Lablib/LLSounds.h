//
//  LLSounds.h
//  Lablib
//
//  Created by John Maunsell on Sat Aug 23 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface LLSounds : NSObject {

	NSMutableDictionary 	*sounds;
	NSSound					*theSound;
}

- (void)playSound:(NSString *)soundName;

@end
