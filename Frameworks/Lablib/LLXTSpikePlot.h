//
//  LLXTSpikePlot.h
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTPlot.h"

@interface LLXTSpikePlot : NSObject <LLXTPlot> {

@protected
    float			durationS;
    LLViewScale		*scale;
	NSLock			*spikeLock;
    NSMutableArray	*spikeTimes;
}

- (void)addSpike:(NSNumber *)time;
- (void)clear;
- (void)draw;

@end
