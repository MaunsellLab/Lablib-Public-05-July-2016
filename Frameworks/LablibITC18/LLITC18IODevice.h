//
//  LLITC18IODevice.h
//  Lablib
//
//  Created by John Maunsell on Mon Jun 09 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import <Lablib/LLIODevice.h>
#import "LLITCMonitor.h"

@interface LLITC18IODevice : NSObject <LLIODevice> {

@private
    BOOL 				dataEnabled;
    NSLock				*deviceLock;
	unsigned short		digitalInputWord; 
	unsigned short		digitalOutputWord;
	BOOL				justStartedITC18;
	long				instrPerDigitalInput;
	BOOL				instructionsLoaded;
	Ptr					itc;
	BOOL				itcExists;
	long				ITCTicksPerInstruction;
	LLITCMonitor		*monitor;
    double 				nextSpikeTimeS;
	long				numInstr;
	int					*pInstructions;
	short				*pSamples;
	long				sampleCounter;
    double 				samplePeriodMS;
	double				sequenceStartTimeS;
	unsigned short		timestampActiveBits;
	unsigned short		timestampEnabledBits;
    long				timestampCount[kLLITC18DigitalBits];
	NSLock				*timestampLock;
	BOOL				timestampOverflow;
	NSMutableArray		*timestamps;
    double				timestampTickPerMS;
	long				timestampTime;
    ITCMonitorValues	values;
}

- (void)closeITC18;
- (id)initWithDevice:(long)deviceNum;
- (id <LLMonitor>)monitor;
- (BOOL)openITC18:(long)deviceNum;

@end
