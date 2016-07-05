//
//  LLScheduleController.h
//
//  Created by John Maunsell on Sat Aug 31 2002.
//  Copyright (c) 2002. All rights reserved.
//

#define	kStatUpdatePeriodS		1.0

typedef struct ScheduleSettings {
	id				controller;			// LLScheduleController
	unsigned long 	count;				// number of times the method is run
	unsigned long 	delayMS;			// delay in ms before method is run (first time)
	BOOL			dropOutOK;			// do not need to run every cycle
	NSLock			*lock;				// lock
	id				object;				// optional argument for method
	unsigned long 	periodMS;			// period of method run in ms
	double			*pN;				// pointer for N to update with scheduling stats
	double			*pSum;				// pointer for sum to update with scheduling stats
	double			*pSumsq;			// pointer for sumsq to update with scheduling stats
	double			*pMin;				// pointer for sumsq to update with scheduling stats
	double			*pMax;				// pointer for sumsq to update with scheduling stats
	SEL				selector;			// selector for method in target
	id				target;				// target of the scheduled method
} ScheduleSettings;

@interface LLScheduleController : NSObject {

	double 			n;
	double			maxValue;
	double			minValue;
	NSMutableArray 	*scheduleArray;
	NSLock			*scheduleArrayLock;
	NSLock			*statLock;
	double 			sum;
	double 			sumsq;
}

- (BOOL)abort:(id)schedule;
- (BOOL)isActive:(id)schedule;
- (NSString *)report;
- (id)schedule:(SEL)selector toTarget:(id)target;
- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object;
- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				delayMS:(unsigned long)delay;
- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				delayMS:(unsigned long)delay count:(unsigned long)count
				periodMS:(unsigned long)period;
- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				count:(unsigned long)count periodMS:(unsigned long)period;
- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				count:(unsigned long)count periodMS:(unsigned long)period
				dropOutOK:(BOOL)dropFlag;
- (id)schedule:(SEL)selector toTarget:(id)target withObject:(id)object 
				delayMS:(unsigned long)delay count:(unsigned long)count
				periodMS:(unsigned long)period dropOutOK:(BOOL)dropFlag;
- (void)scheduleCompleted:(id)schedule;
- (BOOL)selectorOK:(SEL)selector toTarget:(id)target;

@end


