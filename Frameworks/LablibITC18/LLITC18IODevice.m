//
//  LLITC18IODevice.m 
//  Lablib
//
//  Created by John Maunsell on Mon Jun 09 2003.
//  Copyright (c) 2003. All rights reserved. 
//

#import "LLITC18.h" 
#import "LLITC18IODevice.h" 
#import <Lablib/LLIODeviceController.h>
#import <Lablib/LLSystemUtil.h>
#import <ITC/Itcmm.h>
#import <ITC/ITC18.h>

#define kDriftTimeLimitMS	0.010
#define kDriftFractionLimit	0.001
#define kGarbageLength		3					// Invalid entries at the start of sequence
#define	kITC18TicksPerMS	800L				// Time base for ITC18
#define kOverSample			4

@implementation LLITC18IODevice

- (BOOL)ADData:(short *)pArray {

	short index, bitIndex, sampleChannel;
	unsigned short whichBit;
	BOOL bitOn;
	int available;
	TimestampData timestamp;

	if (itc == nil) {							// do nothing if there is no ITC
		return NO;
	}

    [deviceLock lock];

// When a sequence is started, the first three entries in the FIFO 
// are garbage.  They should be thrown out.  

	if (justStartedITC18) {
		ITC18_GetFIFOReadAvailable(itc, &available);
		if (available < kGarbageLength + 1) {
            [deviceLock unlock];
			return NO ;
		}
		ITC18_ReadFIFO(itc, kGarbageLength, pSamples);
		justStartedITC18 = NO;
	}

// If no real data are ready, there is nothing to do.
		
	ITC18_GetFIFOReadAvailable(itc, &available);
	if (available < numInstr + 1) {
        [deviceLock unlock];
		return NO ;
	}
	
// Data are ready, load the A/D values, and save the digital bits

	ITC18_ReadFIFO(itc, numInstr, pSamples);
	for (index = sampleChannel = 0; index < numInstr; index++) {	// for every instruction
		if ((index % instrPerDigitalInput) == 0) {					// digital input instruction
			digitalInputWord = pSamples[index];						// save the digital input word
			for (bitIndex = 0; bitIndex < kLLITC18DigitalBits; bitIndex++) { // check every bit
				whichBit = (0x1 << bitIndex);						// get the bit pattern for one bit
                if (whichBit & timestampEnabledBits) {				// enabled bit?
                    bitOn = (whichBit & pSamples[index]); 			// bit on?
                    if (timestampActiveBits & whichBit) {			// was active
                        if (!bitOn) {								//  but now inactive
                            timestampActiveBits &= ~whichBit;		//  so clear flag
                        }
                    }
                    else if (bitOn) {								// active now but was not before
                        timestampActiveBits |= whichBit;			// flag channel as active
                        values.timestampCount[bitIndex]++;			// increment timestamp ount
                        timestamp.channel = bitIndex;				// store channel
                        timestamp.time = timestampTime;				// store timestamp
                        [timestampLock lock];						// add to buffer
                        [timestamps addObject:[NSValue value:&timestamp withObjCType:@encode(TimestampData)]];
                        [timestampLock unlock];
                    }
                }
			}

// If this is the end of a digital cycle, advance the time base for digial input

			if (((index / instrPerDigitalInput) % kOverSample) == (kOverSample - 1)) {
				timestampTime++;
			}
		}
		else if (sampleChannel < kLLITC18ADChannels && pArray != nil) {
			pArray[sampleChannel++] = pSamples[index];
		}
	}
    values.samples++;    
    [deviceLock unlock];
	return (pArray != nil);
}

- (BOOL)canConfigure {

	return NO;
}

// Close the ITC18.  

- (void)closeITC18 {

	if (itc != nil) {
		[deviceLock lock];
		ITC18_Close(itc);
		free(itc);
		itc = nil;
		[deviceLock unlock];
	}
}

- (void)configure {
	
	return;
}

- (BOOL)dataEnabled {
	
	return dataEnabled;
}

- (void)dealloc {

	[self closeITC18];
	[timestamps release];
	[timestampLock release];
	[monitor release];
	[deviceLock release];
	[super dealloc];
}

- (void)digitalOutputBitsOff:(unsigned short)bits {

	if (itc != nil) {
		digitalOutputWord &= ~bits;
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)digitalOutputBitsOn:(unsigned short)bits {

	if (itc != nil) {
		digitalOutputWord |= bits;
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)disableTimestampBits:(NSNumber *)bits {
		
	timestampEnabledBits &= ~[bits unsignedShortValue];
}

- (void)doInitializationWithDevice:(long)deviceNum {

	long index; 
	int ranges[ITC18_AD_CHANNELS];

	itc = nil;
	timestamps = [[NSMutableArray alloc] init];
	timestampLock = [[NSLock alloc] init];
	deviceLock = [[NSLock alloc] init];
	monitor = [[LLITCMonitor alloc] initWithID:@"ITC-18" description:@"Instrutech ITC-18 Lab I/O"];
	if ([self openITC18:deviceNum]) {
		for (index = 0; index < ITC18_AD_CHANNELS; index++) {	// Set AD voltage range
			ranges[index] = ITC18_AD_RANGE_10V;
		}
		ITC18_SetRange(itc, ranges);
		ITC18_SetDigitalInputMode(itc, YES, NO);				// latch and do not invert
	}
}


- (void)enableTimestampBits:(NSNumber *)bits {

	timestampEnabledBits |= [bits unsignedShortValue];

}

- (unsigned short)digitalInputValues {

	return digitalInputWord;
}

- (BOOL)hasITC18 {

	return itcExists;
}

// Initialization tests for the existence of the ITC, and initializes it if it is there.
// The ITC initialization sets thd AD voltage, and also set the digital input to latch.
// ITC-18 latching is not the same thing as edge triggering.  A short pulse will produce a positive 
// value at the next read, but a steady level can also produce a series of positive values.

- (id)init {

	if ((self = [super init]) != Nil) {
		[self doInitializationWithDevice:0];
	}
	return self;
}

// Do the initialize with a particular ITC-18 device, rather than the default

- (id)initWithDevice:(long)deviceNum {

	if ((self = [super init]) != Nil) {
		[self doInitializationWithDevice:deviceNum];
	}
	return self;
}

// Make the instruction sequence.  The sequence contains 4 * the number of digital
// inputs needed to match the requested spike resolution.  We need to oversample so
// that we can see an on level and an off level associated with each spike.  While
// a factor of 2 might seem adequate, it is not because we use digital latching.
// We must latch because spikes are generally marked with short pulses, and we would
// be unlikely to catch these pulses.  To detect a low level when latching is enabled,
// we must have 2 digital samples while the level is low.  If we allow for a worst 
// case of a 50% duty cycle on the spike signal, then we need 4 samples per spike
// period.  

// AD sample instructions are inserted between the digital input commands, at a 
// density that insures that each channel will be sampled once per sequence.  
// The AD samples are all packed at the start of the sequence, and Nil commands
// are used to maintain the spacing of the digital commands after all ADs are samled.  

- (void)loadInstructionSequence {

	short channel, adInstruction;
	int *pInstrBuff;
	long chunk;
	long digitalInputsPerCycle, ADsPerDigitalInput;
	
	static long instructionBufferLength = 0;
	static long	ADInstructions[] = {ITC18_INPUT_AD0, ITC18_INPUT_AD1, ITC18_INPUT_AD2, 
									ITC18_INPUT_AD3, ITC18_INPUT_AD4, ITC18_INPUT_AD5, 
									ITC18_INPUT_AD6, ITC18_INPUT_AD7}; 

	if (itc == nil) {
		return;
	}
	
// Check ranges

	if (samplePeriodMS < 1 || samplePeriodMS > 100) {
		NSRunAlertPanel(@"LLITC18IODevice",  @"A sample period of %.1f is not supported", 
					@"OK", nil, nil, samplePeriodMS);
		return;
	}
	if (timestampTickPerMS < 1 || timestampTickPerMS > 10) {
		NSRunAlertPanel(@"LLITC18IODevice",  @"%f timestamp ticks per ms is not supported",
					@"OK", nil, nil, timestampTickPerMS);
		return;
	}

// Get values

	digitalInputsPerCycle = samplePeriodMS * timestampTickPerMS * kOverSample;
	for (ADsPerDigitalInput = 1; ADsPerDigitalInput * digitalInputsPerCycle < kLLITC18ADChannels;
			ADsPerDigitalInput++) {};
	instrPerDigitalInput = ADsPerDigitalInput + 1;
	numInstr = instrPerDigitalInput * digitalInputsPerCycle;
	ITCTicksPerInstruction = samplePeriodMS * kITC18TicksPerMS / numInstr;

// The number of ITC ticks per instruction must be exact, or timing will drift.  If it's not,
// try making an adjustment to bring it into line.

	if (ITCTicksPerInstruction != ((double)(samplePeriodMS * kITC18TicksPerMS)) / numInstr) {
		ADsPerDigitalInput++;
		instrPerDigitalInput = ADsPerDigitalInput + 1;
		numInstr = instrPerDigitalInput * digitalInputsPerCycle;
		ITCTicksPerInstruction = samplePeriodMS * kITC18TicksPerMS / numInstr;
 	}
	if (ITCTicksPerInstruction != ((double)(samplePeriodMS * kITC18TicksPerMS)) / numInstr) {
		NSRunAlertPanel(@"LLITC18IODevice",  @"Fatal error: Invalid sample or spike resolution.", 
					@"OK", nil, nil);
		exit(0);
	}
	
	// Make the instruction sequence, allocating memory first if needed

	if (instructionBufferLength < numInstr) {
		if (pInstructions != nil) {
			free((char *)pInstructions);
		}
		pInstructions = (int *)malloc(numInstr * sizeof(int));
		if (pInstructions == nil) {
			NSRunAlertPanel(@"LLITC18IODevice",  @"Fatal error: Could not alloc pInstructions memory.", 
						@"OK", nil, nil);
			exit(0);
		}
		if (pSamples != nil) {
			free((char *)pSamples);
		}
		pSamples = (short *)malloc(numInstr * sizeof(short));
		if (pSamples == nil) {
			NSRunAlertPanel(@"LLITC18IODevice",  @"Fatal error: Could not alloc pSamples memory.", 
						@"OK", nil, nil);
			exit(0);
		}
		instructionBufferLength = numInstr;
	}

// NB: No new values are read into the ITC until a command with the ITC18_INPUT_UPDATE bit
// set is read.  This applies to the digital input lines as well as the AD lines.  For this
// reason, every digital input command must have the update bit set.   FURTHERMORE, it is
// essential that none of the AD read commands does an update.  If it does, it will cause
// the digital values to be updated, clearing any latched bits.  When the next digital
// read command goes, its update will cause the a new digital word to be read, so that any
// previously latched values that were updated by the Analog read command would be lost.

	for (chunk = channel = 0, pInstrBuff = pInstructions; chunk < digitalInputsPerCycle; chunk++) {
        *pInstrBuff++ = ITC18_INPUT_DIGITAL | ITC18_INPUT_UPDATE | ((chunk == 0 && channel == 0) ? 0x1 : 0x0);
		for (adInstruction = 0; adInstruction < ADsPerDigitalInput; adInstruction++) {
			*pInstrBuff++ = (channel < kLLITC18ADChannels) ? ADInstructions[channel] : ITC18_INPUT_SKIP;
			channel++;
		}
	}
	
// Load the ITC18 with the correct sequence for the sampling periods that have been
// requested

	ITC18_SetSequence(itc, numInstr, pInstructions); 
	instructionsLoaded = YES;
}

- (id <LLMonitor>)monitor {

	return monitor;
}

- (NSString *)name {

	return @"ITC-18";
}

// Open and initialize the ITC18

- (BOOL)openITC18:(long)deviceNum {

    [deviceLock lock];
	if (itc == nil) {						// current opened?
		if ((itc = malloc(ITC18_GetStructureSize())) == nil) {
			NSRunAlertPanel(@"LLITC18IODevice",  @"Failed to allocate pLocal memory.", @"OK", nil, nil);
			exit(0);
		}
	}
	else {
        ITC18_Close(itc);
	}

// Now the ITC is closed, and we have a valid pointer

	if (ITC18_Open(itc, deviceNum) != noErr) {			// no ITC, return
		free(itc);
		itc = nil;
		itcExists = NO;
        [deviceLock unlock];
		return itcExists;
	}

// the ITC has opened, now initialize it

	if (ITC18_Initialize(itc, ITC18_STANDARD) != noErr) { 
		free(itc);
		if (itcExists) {
			NSRunAlertPanel(@"LLITC18IODevice",  @"An ITC18 Laboratory Interface card was found, but the\
						remote device did not initialize correctly.", @"OK", nil, nil);
		}
		itcExists = NO;
        [deviceLock unlock];
		return itcExists;
	}
	itcExists = YES;
    [deviceLock unlock];
	return itcExists;
}

- (long)samplePeriodMS;
{
	return samplePeriodMS;
}

- (BOOL)setDataEnabled:(BOOL)state {

    int available;
	BOOL previousState;
    short samples[kLLITC18ADChannels];
	
	if (itc == nil) {
		return NO;
	}
	previousState = dataEnabled;
	if (state && !dataEnabled && instructionsLoaded) {
        [deviceLock lock];
		timestampOverflow = NO;
		timestampTime = 0;
        timestampActiveBits = 0x0;
        justStartedITC18 = YES;
        [monitor initValues:&values];
        values.samplePeriodMS = samplePeriodMS;
        values.instructionPeriodMS = samplePeriodMS / numInstr;
//        ITC18_InitializeAcquisition(itc);
		ITC18_StopAndInitialize(itc, YES, YES);
        ITC18_SetSamplingInterval(itc, ITCTicksPerInstruction, false);
        sequenceStartTimeS = [LLSystemUtil getTimeS];
        ITC18_Start(itc, NO, NO, NO, NO);		// no trigger, no output, no stopOnOverflow, (reserved)
		dataEnabled = YES;
        [deviceLock unlock];
	}
	else if (!state && dataEnabled) {
        values.cumulativeTimeMS = ([LLSystemUtil getTimeS] - sequenceStartTimeS) * 1000.0;
        [deviceLock lock];
        ITC18_Stop(itc);										// stop the ITC18
		[deviceLock unlock];
       
// Check whether the number of samples collected is what is predicted based on the elapsed time.
// This is a check for drift between the computer clock and the ITC-18 clock.  The first step
// is to drain any complete sample sets from the FIFO.  Then we see how many instructions
// remain in the FIFO (as an incomplete sample set).

        while ([self ADData:samples]) {};						// drain FIFO
        ITC18_GetFIFOReadAvailable(itc, &available);
        values.sequences = 1;
        values.instructions = values.samples * numInstr + available; 
		if (values.instructions == 0) {
			NSLog(@" ");
			NSLog(@"WARNING: LLITC18: values.instructions == 0");
			NSLog(@"sequenceStartTimeS: %f", sequenceStartTimeS);
			NSLog(@"time now: %f", [LLSystemUtil getTimeS]);
			NSLog(@"timestampTime: %ld", timestampTime);
			NSLog(@"justStartedITC18: %d", justStartedITC18);
			NSLog(@"dataEnabled: %d", dataEnabled);
			NSLog(@"values.cumulativeTimeMS: %f", values.cumulativeTimeMS);
			NSLog(@"values.samples: %ld", values.samples);
			NSLog(@"values.samplePeriodMS: %f", values.samplePeriodMS);
			NSLog(@"values.instructions: %ld", values.instructions);
			NSLog(@"values.instructionPeriodMS: %f", values.instructionPeriodMS);
			NSLog(@"values.sequences: %ld", values.sequences);
			NSLog(@" ");
		}
		else {
			[monitor sequenceValues:values];
		}
		dataEnabled = NO;
	}
	return previousState;
}

- (void)setSamplePeriodMS:(double)period {

	samplePeriodMS = period;
	if (samplePeriodMS > 0 && timestampTickPerMS > 0) {
		[self loadInstructionSequence];
	}
}

- (void)setTimestampTickPerMS:(double)timestampTicksPerMS {

		timestampTickPerMS = timestampTicksPerMS;
		if (samplePeriodMS > 0 && timestampTickPerMS > 0) {
			[self loadInstructionSequence];
		}
}

- (BOOL)timestampData:(TimestampData *)pData {

	if (itc == nil || [timestamps count] == 0) {
		return NO;
	}
	[timestampLock lock];
	[[timestamps objectAtIndex:0] getValue:pData];
	[timestamps removeObjectAtIndex:0];
	[timestampLock unlock];
	return YES;
}

- (long)timestampTickPerMS;
{
	return timestampTickPerMS;
}

@end