//
//  LLScheduleController.m
//
//  Created by John Maunsell on Sat Aug 31 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import "LLScheduleController.h"
#import "LLSchedule.h"


@implementation LLScheduleController

// Report whether a schdule is still active

- (BOOL)abort:(id)schedule {

	if (![scheduleArray containsObject:schedule]) {			// Return true if there is nothing to abort
		return YES;
	}
	[(LLSchedule *)schedule abort];
	return NO;											// Report that the abort is not complete
}

- (void)dealloc;
{
	[scheduleArray release];
	[statLock release];
	[scheduleArrayLock release];
	[super dealloc];
}

- (id)init {

	self = [super init];
	statLock = [[NSLock alloc] init];
	scheduleArrayLock = [[NSLock alloc] init];
	scheduleArray = [[NSMutableArray alloc] init];
	maxValue = -1e100;
	minValue = 1e100;
	return self;
}

// Report whether a schdule is still active

- (BOOL)isActive:(id)schedule;
{
	return [scheduleArray containsObject:schedule];
}

- (NSString *)report {

	return [NSString stringWithFormat:
		@"Latency: mean %.2f ms, SD %.2f ms (n = %.0f)\nRange %.2f to %.2f ms", 
		sum / n * 1000.0, sqrt((sumsq - sum * sum / n) / (n - 1.0)) * 1000.0, n,
		minValue * 1000.0, maxValue * 1000.0];
}
		
- (id)schedule:(SEL)selector toTarget:(id)target {

	[self schedule:selector toTarget:(id)target withObject:nil];
	return nil;
}

- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object {

    IMP method;
	void (*function)(id);
	
	if ([self selectorOK:selector toTarget:target]) {
		method = [target methodForSelector:selector];
  	  	function = (void (*)(id))method;
   		function(object);
   	}
   	return nil;
}

- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				delayMS:(unsigned long)delay {

	return [self schedule:selector toTarget:target withObject:object delayMS:delay
				count:1 periodMS:0 dropOutOK:false];

}

- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				delayMS:(unsigned long)delay count:(unsigned long)count
				periodMS:(unsigned long)period {

	return [self schedule:selector toTarget:target withObject:object delayMS:delay
				count:count periodMS:period dropOutOK:false];
}

- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				count:(unsigned long)count periodMS:(unsigned long)period {

	return [self schedule:selector toTarget:target withObject:object delayMS:0
				count:count periodMS:period dropOutOK:false];
}

- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				count:(unsigned long)count periodMS:(unsigned long)period
				dropOutOK:(BOOL)dropFlag {

	return [self schedule:selector toTarget:target withObject:object delayMS:0
				count:count periodMS:period dropOutOK:dropFlag];
}

- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				delayMS:(unsigned long)delay count:(unsigned long)count
				periodMS:(unsigned long)period dropOutOK:(BOOL)dropFlag {

	ScheduleSettings settings;
	LLSchedule *server;
	
	if (![self selectorOK:selector toTarget:target]) {
		return nil;
	}
	settings.target = target;
	settings.selector = selector;
	settings.object = object;
	settings.delayMS = delay;
	settings.count = count;
	settings.periodMS = period;
	settings.dropOutOK = dropFlag;
	settings.pN = &n;
	settings.pSum = &sum;
	settings.pSumsq = &sumsq;
	settings.pMax = &maxValue;
	settings.pMin = &minValue;
	settings.lock = statLock;
	settings.controller = self;
	server = [[LLSchedule alloc] initWithSettings:settings];
	[scheduleArray addObject:server];
	[NSThread detachNewThreadSelector:@selector(run) toTarget:server withObject:nil];
	return server;
}

// The following method is called by every schedule when it has finished running.  
// We were getting occasional crashes because the object was not in scheduleArray.
// I've switchted to removeObjectIdenticalTo rather than removeObject so that it
// compares the object address rather than the isEqual result.removeObjectIdenticalTo

- (void)scheduleCompleted:(id)schedule;
{
	[scheduleArrayLock lock];
	[scheduleArray removeObjectIdenticalTo:schedule];
	[schedule autorelease];					 // autorelease because schedule needs to clean up
	[scheduleArrayLock unlock];
}

- (BOOL)selectorOK:(SEL)selector toTarget:(id)target
{
	BOOL result;
    NSAlert *theAlert;
	
	result = [target respondsToSelector:selector];
	if (!result) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLSchedule: Scheduling error"];
        [theAlert setInformativeText:[NSString stringWithFormat:@"Target does not respond to method \"%@\"",
                                      NSStringFromSelector(selector)]];
        [theAlert runModal];
        [theAlert release];
//		NSRunAlertPanel(@"LLSchedule: Scheduling error",
//				@"Target does not respond to method \"%@\"", @"OK", nil, nil,
//				NSStringFromSelector(selector));
	}
	return result;
}
@end
