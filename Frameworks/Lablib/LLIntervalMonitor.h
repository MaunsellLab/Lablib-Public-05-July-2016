//
//  LLIntervalMonitor.h
//  Lablib
//
//  Created by John Maunsell on Wed Jan 29 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLMonitor.h"
#import "LLIntervalMonitorSettings.h"

extern NSString	*doSuccessGreaterKey;
extern NSString	*doSuccessLessKey;
extern NSString	*doWarnDisarmKey;
extern NSString	*doWarnGreaterKey;
extern NSString	*doWarnLessKey;
extern NSString	*doWarnSequentialKey;
extern NSString	*successLessCountKey;
extern NSString	*successLessMSKey;
extern NSString	*successGreaterCountKey;
extern NSString	*successGreaterMSKey;
extern NSString	*warnGreaterCountKey;
extern NSString	*warnLessCountKey;
extern NSString	*warnSequentialCountKey;
extern NSString	*standardKey;

typedef struct {
    double 	n;			// number of events
    double 	sum;		// sum of time increments
    double 	sumsq;		// sum of squares of time increments
    double	overRange;	// number of events over range limit
    double	underRange;	// number of events under range limit
    double 	minValue;	// minimum time delta
    double 	maxValue; 	// maximum time delta
    double	rangeMinMS;	// lower limit of time range
    double	rangeMaxMS;	// upper limit of time range
} MonitorValues;

@interface  LLIntervalMonitor : NSObject <LLMonitor> {

@protected

	BOOL 			alarmActive;
	MonitorValues 	currentValues;
	NSString 		*descriptionString;				// First line in report
	MonitorValues 	cumulativeValues;
	long			greaterFailures;
	NSString 		*IDString;						// Short string for menu entry
	double 			lastTimeMS;						// last time an event occurred
	MonitorValues 	lastValues;
	long			lessFailures;
	long			sequenceCount;
	long			sequentialFailures;
	LLIntervalMonitorSettings *settings;
	double			targetIntervalMS;				// target to shoot for
	NSMutableArray	*times;
	BOOL			useTarget;						// use target rather than mean 
}

- (void)doAlarm:(NSString *)message;
- (void)initValues:(MonitorValues *)pValues;
- (id)initWithID:(NSString *)ID description:(NSString *)description;
- (void)recordEvent;
- (void)reset;
- (void)setTargetIntervalMS:(double)targetIntervalMS;
- (BOOL)success;
- (NSString *)valueString:(MonitorValues *)pValues;
- (NSString *)uniqueKey:(NSString *)commonKey;

@end


