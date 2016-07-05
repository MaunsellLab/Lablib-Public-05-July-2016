//
//  LLXTSpikePlot.m
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTSpikePlot.h"
#import "LLViewUtilities.h"

@implementation LLXTSpikePlot

- (void)addSpike:(NSNumber *)time;
{
    [spikeLock lock];
    [spikeTimes addObject:time];
	[spikeLock unlock];
}

- (void)dealloc {

    [spikeLock release];
    [spikeTimes release];
    [super dealloc];
}

- (void)draw;
{
    long time;
    unsigned long index, limitTimeMS;
    
    [[NSColor blueColor] set];
	[spikeLock lock];
	
// Remove any expired spikes

	limitTimeMS = [[spikeTimes lastObject] longValue] - durationS * 1000.0;
	for (index = 0; index < [spikeTimes count]; index++) {
		if ([[spikeTimes objectAtIndex:index] longValue] >= limitTimeMS) {
			break;
		}
	}
	if (index > 0) {
		[spikeTimes removeObjectsInRange:NSMakeRange(0, index)];
	}

// Draw the spikes

    for (index = 0; index < [spikeTimes count]; index++) {
        time = [scale scaledY:[[spikeTimes objectAtIndex:index] longValue]];
        [NSBezierPath strokeLineFromPoint:NSMakePoint([scale scaledX:0.0], time)
                toPoint:NSMakePoint([scale scaledX:1.0], time)];
   }
   [spikeLock unlock];
}

- (void)clear {

	[spikeLock lock];
    [spikeTimes removeAllObjects];
	[spikeLock unlock];
}

- (id)init {

	if ((self = [super init]) != nil) {
        spikeTimes = [[NSMutableArray alloc] init];
        spikeLock = [[NSLock alloc] init];
	}
	return self;
}

- (void)setDurationS:(NSNumber *)durS {

    durationS = [durS floatValue];
}

- (void)setScale:(LLViewScale *)scaling {

    [scaling retain];
    if (scale != nil) {
        [scale release];
    }
    scale = scaling;
}

@end
