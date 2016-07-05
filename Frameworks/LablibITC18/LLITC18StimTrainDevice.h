//
//  LLITC18StimTrainDevice.h
//  Lablib
//
//  Created by John Maunsell on Mon Jun 09 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import <Lablib/LLStimTrainDevice.h>

@interface LLITC18StimTrainDevice : NSObject <LLStimTrainDevice>  {

@private
    BOOL 				dataEnabled;
    NSLock				*deviceLock;
	unsigned short		digitalInputWord;
	unsigned short		digitalOutputWord;
	long				FIFOSize;
	BOOL				justStartedITC18;
	long				instrPerDigitalInput;
	BOOL				instructionsLoaded;
	Ptr					itc;
	BOOL				itcExists;
	long				ITCTicksPerInstruction;
    double 				nextSpikeTimeS;
	long				numInstr;
	int					*pInstructions;
	short				*pSamples;
	long				sampleCounter;
    double 				samplePeriodMS;
	double				sequenceStartTimeS;
	BOOL				USB18;
}

- (void)close;
- (void)doInitializationWithDevice:(long)numDevice;
- (id)initWithDevice:(long)numDevice;
- (BOOL)open:(long)numDevice;

@end
