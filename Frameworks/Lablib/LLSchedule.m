//
//  LLSchedule.m
//
//  Created by John Maunsell on Sat Aug 31 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import "LLSchedule.h"
#import "LLScheduleController.h"

#define kAutoreleaseIntS	10

@implementation LLSchedule

- (void)abort {

	abortFlag = true;
}

- (LLSchedule *)initWithSettings:(ScheduleSettings)settings {

    IMP method;

	if ([super init]) {
        target = settings.target;
        selector = settings.selector;
        method = [settings.target methodForSelector:settings.selector];
	    function = (void (*)(id, SEL, ...))method;
	    object = settings.object;
	    delayS = settings.delayMS / 1000.0;
	    count = settings.count;
	    periodS = settings.periodMS / 1000.0;
	    dropOutOK = settings.dropOutOK;
	    pGrandN = settings.pN;
	    pGrandSum = settings.pSum;
	    pGrandSumsq = settings.pSumsq;
	    pGrandMax = settings.pMax;
	    pGrandMin = settings.pMin;
	    statLock = settings.lock;
	    controller = settings.controller;
    	statUpdates = 0.0;
  	}
   	return self;
}

- (void)run {

    unsigned long index;
    NSDate *targetDate, *tempDate, *nextRelease;
	double latencyS;
    NSAutoreleasePool *threadPool;

// Initialize and get the start time for this schedule

    threadPool = [[NSAutoreleasePool alloc] init];
	nextRelease = [NSDate dateWithTimeIntervalSinceNow:kAutoreleaseIntS];
    maximum = -1000000;
    minimum = 1000000;
    n = sum = sumsq = 0;
    startDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];
//    [startDate retain];

// If there is a delay before the first execution, delay here

    if (delayS > 0) {
        targetDate = [startDate dateByAddingTimeInterval:delayS];
        if ([targetDate timeIntervalSinceNow] > 0) {
			[NSThread sleepUntilDate:targetDate];
		}
        latencyS = -[targetDate timeIntervalSinceNow];
        n++;
        sum += latencyS;
        sumsq += latencyS * latencyS;
        maximum = MAX(maximum, latencyS);
        minimum = MIN(minimum, latencyS);
    }
    
    for (index = 0; index < count || count == 0; index++) {
		function(target, selector, object);			// Run the function one time
        
// If it is not yet time for the next execution, make the thread sleep

        targetDate = [startDate dateByAddingTimeInterval:(delayS + (index + 1) * periodS)];
        if ([targetDate timeIntervalSinceNow] > 0) {
			[NSThread sleepUntilDate:targetDate];
			if ([nextRelease timeIntervalSinceNow] < 0.0) {
				[threadPool release];
				threadPool = [[NSAutoreleasePool alloc] init];
				nextRelease = [NSDate dateWithTimeIntervalSinceNow:kAutoreleaseIntS];
			}
		}
		latencyS = -[targetDate timeIntervalSinceNow];

// If we are allowed to drop runs, and we are behind, skip the missed runs

		if (dropOutOK) {
			while (latencyS >= periodS) {
				index++;
				latencyS -= periodS;
			}
		}
		n++;
		sum += latencyS;
		sumsq += latencyS * latencyS;
		maximum = MAX(maximum, latencyS);
		minimum = MIN(minimum, latencyS);
		
// If it is time to update the statistics, do that now

		[self updateStats:false];

// Check for index overflow

		if (index == ULONG_MAX) {
			tempDate = [startDate dateByAddingTimeInterval:index * periodS];
			[startDate release];
			startDate = tempDate;
			[startDate retain];
			index = 0;
		}
		if (abortFlag) {
			break;
		}
    }

    [self updateStats:true];
    [startDate release];
    [controller scheduleCompleted:self];
    [threadPool release];
}

// Pass the statistics back to the schedule controller.  If the mustUpdate flag is set,
// the update will be done. Otherwise it will only be done of the kStatUpdatePeriodMS has
// elapsed and the lock is available

- (void)updateStats:(BOOL)mustUpdate {

	if (mustUpdate) {
		[statLock lock];
	}
	else {
		if ((statUpdates + 1) * kStatUpdatePeriodS > -[startDate timeIntervalSinceNow]) {
			return;
		}
		if (![statLock tryLock]) {
			return;
		}
	}
    *pGrandN += n;
    *pGrandSum += sum;
    *pGrandSumsq += sumsq;
    *pGrandMax = MAX(*pGrandMax, maximum);
    *pGrandMin = MIN(*pGrandMin, minimum);
    [statLock unlock];

    n = sum = sumsq = 0;
	statUpdates++;
}

@end
