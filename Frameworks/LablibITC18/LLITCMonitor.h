//
//  LLITCMonitor.h
//  Lablib
//
//  Created by John Maunsell on Wed Jan 29 2003.
//  Copyright (c) 2003 . All rights reserved.
//

#import "LLITC18.h"
#import "LLITCMonitorSettings.h"
#import <Lablib/LLMonitor.h>
//#import <Lablib/LLIODevice.h>

extern NSString	*doWarnDriftKey;
extern NSString	*driftLimitKey;

typedef struct {
	short 	ADMaxValues[kLLITC18ADChannels];
	short 	ADMinValues[kLLITC18ADChannels];
	double	cumulativeTimeMS;							// duration of sequence based on CPU clock
	long	samples;									// number of sample sets collected
    double	samplePeriodMS;								// period for one sample set
    long	instructions;								// number of sampling instructions completed
    double	instructionPeriodMS;						// period for one instruction
	long 	sequences;
	long	timestampCount[kLLITC18DigitalBits];
} ITCMonitorValues;

@interface  LLITCMonitor : NSObject <LLMonitor> {
@private
	BOOL 					alarmActive;
	ITCMonitorValues 		cumulative;
	NSString 				*descriptionString;				// First line in report
	NSString 				*IDString;						// Short string for menu entry
	ITCMonitorValues 		previous;
	double					samplePeriodMS;
	double 					sequenceStartTimeMS;			// start of current sequence
	LLITCMonitorSettings	*settings;
}

- (void)doAlarm:(NSString *)message;
- (void)initValues:(ITCMonitorValues *)pValues;
- (id)initWithID:(NSString *)ID description:(NSString *)description;
- (void)resetCounters;
- (void)sequenceValues:(ITCMonitorValues)current;
- (BOOL)success;
- (NSString *)valueString:(ITCMonitorValues *)pValues;
- (NSString *)uniqueKey:(NSString *)commonKey;

@end


