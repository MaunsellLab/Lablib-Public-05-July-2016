//
//  LLITC18DataDevice.h
//  Lablib
//
//  Created by John Maunsell on Mon Jun 09 2003.
//  Copyright (c) 2005. All rights reserved.
//

#import <Lablib/LLDataDevice.h>
#import "LLITCMonitor.h"

#define kMaxInstructions 			12
#define kMinSampleBuffer			8192

@interface LLITC18DataDevice : LLDataDevice {

    NSLock				*deviceLock;
	long				deviceNum;
	unsigned long		digitalOutputWord;
	BOOL				justStartedITC18;
	int					instructions[kMaxInstructions];
	Ptr					itc;
	double				ITCSamplePeriodS;
	long				ITCTicksPerInstruction;
	double				lastReadDataTimeS;
	LLITCMonitor		*monitor;
	double				monitorStartTimeS; 
	double				nextSampleTimeS[kLLITC18ADChannels];
	long				numInstructions;
	short				*samples;
	NSMutableData		*sampleData[kLLITC18ADChannels];
	NSLock				*sampleLock;
	NSData				*sampleResults[kLLITC18ADChannels];
	double				sampleTimeS;
	unsigned short		timestampActiveBits;
	NSMutableData		*timestampData[kLLITC18DigitalBits];
	NSLock				*timestampLock;
	NSData				*timestampResults[kLLITC18DigitalBits];
	double				timestampTickS[kLLITC18DigitalBits];
    NSArray             *topLevelObjects;
	BOOL				USB18;
    ITCMonitorValues	values;

	IBOutlet NSWindow 	*settingsWindow;
}

- (IBAction)ok:(id)sender;

- (void)allocateSampleBuffer:(short **)ppBuffer size:(long)sizeInShorts;
- (void)closeITC18;
- (int)getAvailable;
- (id)initWithDevice:(long)deviceNum;
- (Ptr)itc;
- (void)loadInstructions;
- (id <LLMonitor>)monitor;
- (BOOL)openITC18:(long)deviceNum;
- (void)readData;

@end
