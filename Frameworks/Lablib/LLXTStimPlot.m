//
//  LLXTStimPlot.m
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTStimPlot.h"
#import "LLViewUtilities.h"

typedef struct {
	long time;
	NSColor *color;
} StimDesc;

@implementation LLXTStimPlot

- (void)addStim:(NSColor *)color time:(NSNumber *)time;
{
	StimDesc s;
	
	[color retain];
	s.color = color;
	s.time = [time longValue];
	[stimLock lock];
    [stim addObject:[NSValue value:&s withObjCType:@encode(StimDesc)]];
	[stimLock unlock];
}

- (void)clear {

	[stimLock lock];
	[stim removeAllObjects];
	[stimLock unlock];
}

- (void)dealloc {

	long index;
	StimDesc s;
	
    for (index = 0; index < [stim count]; index++) {
		[[stim objectAtIndex:index] getValue:&s];
		[s.color release];
    }
    [stim release];
	[stimLock release];
    [super dealloc];
}

- (void)draw {

    long index, j, limitTimeMS;
    float lastYPix, yHeightPix;
	StimDesc s;
    NSRect r;
    
	[stimLock lock];

// Clear out expired times, but always leave two expired values,
// to give the color to start with at the time limit.

	[[stim lastObject] getValue:&s];
	limitTimeMS = s.time - (durationS + 1) * 1000.0;
	for (index = 0; index < [stim count]; index++) {
		[[stim objectAtIndex:index] getValue:&s];
		if (s.time >= limitTimeMS) {
			break;
		}
	}

	if (index > 2) {
		for (j = 0; j < index; j++) {
			[[stim objectAtIndex:index] getValue:&s];
			[s.color release];
		}
		[stim removeObjectsInRange:NSMakeRange(0, index - 1)];
	}

// Draw the stimuli

    r = [scale viewRect];
    if ([stim count] > 0) {
		[[stim objectAtIndex:0] getValue:&s];
        [s.color set];
        lastYPix = MAX(r.origin.y, [scale scaledY:s.time]);
        for (index = 1; index < [stim count]; index++) {
			[[stim objectAtIndex:index] getValue:&s];
            yHeightPix = [scale scaledY:s.time] - lastYPix;
            [NSBezierPath fillRect:NSMakeRect(r.origin.x, lastYPix, r.size.width, yHeightPix)];
            lastYPix = lastYPix + yHeightPix;
            [s.color set];
        }
        [NSBezierPath fillRect:NSMakeRect(r.origin.x, lastYPix,
                    r.size.width, r.origin.y + r.size.height - lastYPix)];
    }
    [[NSColor lightGrayColor] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(r.origin.x, r.origin.y)
            toPoint:NSMakePoint(r.origin.x, r.origin.y + r.size.height)];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y)
            toPoint:NSMakePoint(r.origin.x + r.size.width, r.origin.y + r.size.height)];
	
	[stimLock unlock];
}

- (id)init  {

	if ((self = [super init]) != nil) {
        stim = [[NSMutableArray alloc] init];
        stimLock = [[NSLock alloc] init];
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
