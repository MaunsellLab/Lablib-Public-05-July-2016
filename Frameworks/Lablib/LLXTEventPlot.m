//
//  LLXTEventPlot.m
//  Lablib
//
//  Created by John Maunsell on Thu May 22 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLXTEventPlot.h"
#import "LLViewUtilities.h"

@implementation LLXTEventPlot

- (void)addEvent:(NSString *)name time:(NSNumber *)time;
{
 //   unsigned long index, limitTime;
    
    [eventLock lock];
    [eventNames addObject:name];
    [eventTimes addObject:time];
	[eventLock unlock];
/*    limitTime = [time longValue] - durationS * 1000.0;
	if ([eventLock tryLock]) {
		for (index = 0; index < [eventTimes count]; index++) {
			if ([[eventTimes objectAtIndex:index] longValue] >= limitTime) {
				break;
			}
		}
		if (index > 0) {
			[eventTimes removeObjectsInRange:NSMakeRange(0, index)];
			[eventNames removeObjectsInRange:NSMakeRange(0, index)];
		}
		[eventLock unlock];
	} */
}

- (void)clear {

	[eventLock lock];
    [eventNames removeAllObjects];
    [eventTimes removeAllObjects];
	[eventLock unlock];
}

- (void)dealloc {

	[eventLock release];
    [eventNames release];
    [eventTimes release];
    [super dealloc];
}

- (void)draw {

    unsigned long index, limitTime;
    float yValue, midPoint, yPix, lastYPix, xLeftPix, xRightPix;
    NSSize textSize = {0, 0};
    
    [[NSColor blackColor] set];
    xLeftPix = [scale scaledX:0.0];
    xRightPix = [scale scaledX:1.0];
    lastYPix = -100;
    textSize.height = -100;
	
// First remove any events that are beyond the range that we are saving
	
	[eventLock lock];
	limitTime = [[eventTimes lastObject] longValue] - durationS * 1000.0;
	for (index = 0; index < [eventTimes count]; index++) {
		if ([[eventTimes objectAtIndex:index] longValue] >= limitTime) {
			break;
		}
	}
	if (index > 0) {
		[eventTimes removeObjectsInRange:NSMakeRange(0, index)];
		[eventNames removeObjectsInRange:NSMakeRange(0, index)];
	}

// Display the remaining events

    for (index = 0; index < [eventTimes count]; index++) {
        yValue = [[eventTimes objectAtIndex:index] longValue];
        yPix = [scale scaledY:yValue];
        if (lastYPix + textSize.height < yPix) {
            [LLViewUtilities drawString:[eventNames objectAtIndex:index]  
                    rightAndCenterAtPoint:NSMakePoint(xRightPix, yPix) rotation:0.0 
                    withAttributes:nil];
            textSize = [[eventNames objectAtIndex:index] sizeWithAttributes:nil];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xLeftPix, yPix)
                    toPoint:NSMakePoint(xRightPix - textSize.width - 4, yPix)];
        }
        else {
            midPoint = (xLeftPix + xRightPix - textSize.width) / 2.0;
            [LLViewUtilities drawString:[eventNames objectAtIndex:index]  
                    rightAndCenterAtPoint:NSMakePoint(xRightPix, lastYPix + textSize.height) 
                    rotation:0.0 withAttributes:nil];
            textSize = [[eventNames objectAtIndex:index] sizeWithAttributes:nil];
            [NSBezierPath strokeLineFromPoint:
                NSMakePoint(midPoint, lastYPix + textSize.height)
                toPoint:NSMakePoint(xRightPix - textSize.width - 4, lastYPix + textSize.height)];
            [NSBezierPath strokeLineFromPoint:
                    NSMakePoint(midPoint, lastYPix + textSize.height)
                    toPoint:NSMakePoint(midPoint, MAX(yPix, lastYPix))];
            [NSBezierPath strokeLineFromPoint:NSMakePoint(xLeftPix, MAX(yPix, lastYPix))
                    toPoint:NSMakePoint(midPoint, yPix)];
        }
        lastYPix = yPix;
    }
	
	[eventLock unlock];
}

- (id)init;
{
	if ((self = [super init]) != nil) {
        eventNames = [[NSMutableArray alloc] init];
        eventTimes = [[NSMutableArray alloc] init];
		eventLock = [[NSLock alloc] init];
	}
	return self;
}

- (void)setDurationS:(NSNumber *)durS;
{
    durationS = [durS floatValue];
}

- (void)setScale:(LLViewScale *)scaling;
{
    [scaling retain];
	[scale release];
    scale = scaling;
}

@end
