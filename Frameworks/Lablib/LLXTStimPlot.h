//
//  LLXTStimPlot.h
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTPlot.h"

@interface LLXTStimPlot : NSObject <LLXTPlot> {

@protected
    float			durationS;
    LLViewScale		*scale;
	NSLock			*stimLock;
    NSMutableArray	*stim;
}

- (void)addStim:(NSColor *)name time:(NSNumber *)time;
- (void)clear;
- (void)draw;

@end
