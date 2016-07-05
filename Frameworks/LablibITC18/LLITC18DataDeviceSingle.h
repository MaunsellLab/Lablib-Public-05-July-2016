//
//  LLITC18DataDeviceSingle.h
//  Lablib
//
//  Created by John Maunsell on Mon Jun 09 2003.
//  Copyright (c) 2005. All rights reserved.
//

#import "LLITC18.h" 
#import "LLITC18DataSettings.h" 
#import "LLITCMonitor.h"
#import <Lablib/LLDataDevice.h>

@interface LLITC18DataDeviceSingle : LLDataDevice {

    NSLock				*deviceLock;
	unsigned short		digitalOutputWord;
	BOOL				justStartedITC18;
	long				instrPerDigitalInput;
	BOOL				instructionsLoaded;
	Ptr					itc;
	long				ITCTicksPerInstruction;
	LLITCMonitor		*monitor;
    double 				nextSpikeTimeS;
	long				numInstr;
	int					*pInstructions;
	short				*pSamples;
	long				sampleCounter;
	NSMutableData		*sampleData[kLLITC18ADChannels];
	NSLock				*sampleLock;
	NSData				*sampleResults[kLLITC18ADChannels];
	LLITC18DataSettings *settingsController;
	double				sequenceStartTimeS;
	unsigned short		timestampActiveBits;
	NSMutableData		*timestampData[kLLITC18DigitalBits];
	unsigned short		timestampEnabledBits;
    long				timestampCount[kLLITC18DigitalBits];
	NSLock				*timestampLock;
	BOOL				timestampOverflow;
	NSData				*timestampResults[kLLITC18DigitalBits];
	long				timestampTime;
    ITCMonitorValues	values;

}

- (void)closeITC18;
- (id)initWithDevice:(long)deviceNum;
- (void)loadInstructionSequence;
- (id <LLMonitor>)monitor;
- (BOOL)openITC18:(long)deviceNum;
- (void)readData;

@end
