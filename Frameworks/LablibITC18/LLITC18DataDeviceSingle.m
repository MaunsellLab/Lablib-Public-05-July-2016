//
//  LLITC18DataDeviceSingle.m 
//  Lablib
//
// This version of the ITC18 data device forces all sample and timestamp channels to have
// the same timing
//  Created by John Maunsell on Mon Jun 09 2003.
//  Copyright (c) 2006. All rights reserved. 
//

#import "LLITC18DataDeviceSingle.h" 
#import <Lablib/LLSystemUtil.h>
#import <ITC/Itcmm.h>
#import <ITC/ITC18.h>

#define kDriftTimeLimitMS		0.010
#define kDriftFractionLimit		0.001
#define kGarbageLength			3					// Invalid entries at the start of sequence
#define	kITC18TicksPerMS		800L				// Time base for ITC18
#define kOverSample				4
/*
NSString *LLITC18SamplePeriodMS0Key = @"LLITC18SamplePeriodMS0";
NSString *LLITC18SamplePeriodMS1Key = @"LLITC18SamplePeriodMS1";
NSString *LLITC18SamplePeriodMS2Key = @"LLITC18SamplePeriodMS2";
NSString *LLITC18SamplePeriodMS3Key = @"LLITC18SamplePeriodMS3";
NSString *LLITC18SamplePeriodMS4Key = @"LLITC18SamplePeriodMS4";
NSString *LLITC18SamplePeriodMS5Key = @"LLITC18SamplePeriodMS5";
NSString *LLITC18SamplePeriodMS6Key = @"LLITC18SamplePeriodMS6";
NSString *LLITC18SamplePeriodMS7Key = @"LLITC18SamplePeriodMS7";

NSString *LLITC18TimestampTicksMS00Key = @"LLITC18TimestampTicksMS00";
NSString *LLITC18TimestampTicksMS01Key = @"LLITC18TimestampTicksMS01";
NSString *LLITC18TimestampTicksMS02Key = @"LLITC18TimestampTicksMS02";
NSString *LLITC18TimestampTicksMS03Key = @"LLITC18TimestampTicksMS03";
NSString *LLITC18TimestampTicksMS04Key = @"LLITC18TimestampTicksMS04";
NSString *LLITC18TimestampTicksMS05Key = @"LLITC18TimestampTicksMS05";
NSString *LLITC18TimestampTicksMS06Key = @"LLITC18TimestampTicksMS06";
NSString *LLITC18TimestampTicksMS07Key = @"LLITC18TimestampTicksMS07";
NSString *LLITC18TimestampTicksMS08Key = @"LLITC18TimestampTicksMS08";
NSString *LLITC18TimestampTicksMS09Key = @"LLITC18TimestampTicksMS09";
NSString *LLITC18TimestampTicksMS10Key = @"LLITC18TimestampTicksMS10";
NSString *LLITC18TimestampTicksMS11Key = @"LLITC18TimestampTicksMS11";
NSString *LLITC18TimestampTicksMS12Key = @"LLITC18TimestampTicksMS12";
NSString *LLITC18TimestampTicksMS13Key = @"LLITC18TimestampTicksMS13";
NSString *LLITC18TimestampTicksMS14Key = @"LLITC18TimestampTicksMS14";
NSString *LLITC18TimestampTicksMS15Key = @"LLITC18TimestampTicksMS15";
*/
@implementation LLITC18DataDeviceSingle

// Close the ITC18.  

- (void)closeITC18 {

	if (itc != nil) {
		[deviceLock lock];
		ITC18_Close(itc);
		DisposePtr(itc);
		itc = nil;
		[deviceLock unlock];
	}
}

- (void)configure;
{
	if (settingsController == nil) {
		settingsController = [[LLITC18DataSettings alloc] init];
	}
	[settingsController runPanel];
}

- (void)dealloc;
{
	long index;
	
	[self closeITC18];
	for (index = 0; index < kLLITC18ADChannels; index++) {
		[sampleData[index] release];
	}
	for (index = 0; index < kLLITC18DigitalBits; index++) {
		[timestampData[index] release];
	}
	[sampleLock release];
	[timestampLock release];
	[monitor release];
	[deviceLock release];
	[settingsController release];
	[super dealloc];
}

- (void)digitalOutputBits:(unsigned long)bits;
{
	if (itc != nil) {
		digitalOutputWord = bits;
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)digitalOutputBitsOff:(unsigned short)bits;
{
	if (itc != nil) {
		digitalOutputWord &= ~bits;
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)digitalOutputBitsOn:(unsigned short)bits;
{
	if (itc != nil) {
		digitalOutputWord |= bits;
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)doInitializationWithDevice:(long)deviceNum;
{
	long index; 
	int ranges[ITC18_AD_CHANNELS];
	long channel, ticks;
	float period;
	NSUserDefaults *defaults;
	NSString *defaultsPath;
    NSDictionary *defaultsDict;
	NSString *sampleKey = @"LLITC18SamplePeriodMS";
	NSString *timestampKey = @"LLITC18TimestampTicksMS";
	NSString *keySuffix;

// Register default sampling values

	defaultsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"LLITC18DataDeviceSingle" ofType:@"plist"];
	defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
	defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:defaultsDict];
	
// Initialize data buffers

	for (index = 0; index < kLLITC18ADChannels; index++) {
		sampleData[index] = [[NSMutableData alloc] initWithLength:0];
	}
	for (index = 0; index < kLLITC18DigitalBits; index++) {
		timestampData[index] = [[NSMutableData alloc] initWithLength:0];
	}
	
// Load sampling values

	for (channel = 0; channel < kLLITC18ADChannels; channel++)  {
		keySuffix = [NSString stringWithFormat:@"%1d", channel];
		period = [defaults floatForKey:[sampleKey stringByAppendingString:keySuffix]];
		[samplePeriodMS addObject:[NSNumber numberWithFloat:period]];
	}
	for (channel = 0; channel < kLLITC18DigitalBits; channel++)  {
		keySuffix = [NSString stringWithFormat:@"%02d", channel];
		ticks = [defaults integerForKey:[timestampKey stringByAppendingString:keySuffix]];
		[timestampTicksPerMS addObject:[NSNumber numberWithLong:ticks]];
	}

	itc = nil;
	sampleLock = [[NSLock alloc] init];
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

// Load instructions into the ITC
	
	[self loadInstructionSequence];
}

// Initialization tests for the existence of the ITC, and initializes it if it is there.
// The ITC initialization sets thd AD voltage, and also set the digital input to latch.
// ITC-18 latching is not the same thing as edge triggering.  A short pulse will produce a positive 
// value at the next read, but a steady level can also produce a series of positive values.

- (id)init;
{
    if ((self = [super init]) != nil) {
		[self doInitializationWithDevice:0];
	}
	return self;
}

// Do the initialize with a particular ITC-18 device, rather than the default

- (id)initWithDevice:(long)deviceNum {

	if ((self = [super init]) != nil) {
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

- (void)loadInstructionSequence;
{
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

	if ([[samplePeriodMS objectAtIndex:0] floatValue] < 1 || [[samplePeriodMS objectAtIndex:0] floatValue] > 100) {
		NSRunAlertPanel(@"LLITC18IODevice",  @"A sample period of %.1f is not supported", 
					@"OK", nil, nil, samplePeriodMS);
		return;
	}
	if ([[timestampTicksPerMS objectAtIndex:0] longValue] < 1 || [[timestampTicksPerMS objectAtIndex:0] longValue] > 10) {
		NSRunAlertPanel(@"LLITC18IODevice",  @"%d timestamp ticks per ms is not supported", 
					@"OK", nil, nil, [[timestampTicksPerMS objectAtIndex:0] longValue]);
		return;
	}

// Get values

	digitalInputsPerCycle = [[samplePeriodMS objectAtIndex:0] floatValue] * [[timestampTicksPerMS objectAtIndex:0] longValue] * kOverSample;
	for (ADsPerDigitalInput = 1; ADsPerDigitalInput * digitalInputsPerCycle < kLLITC18ADChannels;
			ADsPerDigitalInput++) {};
	instrPerDigitalInput = ADsPerDigitalInput + 1;
	numInstr = instrPerDigitalInput * digitalInputsPerCycle;
	ITCTicksPerInstruction = [[samplePeriodMS objectAtIndex:0] floatValue] * kITC18TicksPerMS / numInstr;

// The number of ITC ticks per instruction must be exact, or timing will drift.  If it's not,
// try making an adjustment to bring it into line.

	if (ITCTicksPerInstruction != ((double)([[samplePeriodMS objectAtIndex:0] floatValue] * kITC18TicksPerMS)) / numInstr) {
		ADsPerDigitalInput++;
		instrPerDigitalInput = ADsPerDigitalInput + 1;
		numInstr = instrPerDigitalInput * digitalInputsPerCycle;
		ITCTicksPerInstruction = [[samplePeriodMS objectAtIndex:0] floatValue] * kITC18TicksPerMS / numInstr;
 	}
	if (ITCTicksPerInstruction != ((double)([[samplePeriodMS objectAtIndex:0] floatValue] * kITC18TicksPerMS)) / numInstr) {
		NSRunAlertPanel(@"LLITC18IODevice",  @"Fatal error: Invalid sample or spike resolution.", 
					@"OK", nil, nil);
		exit(0);
	}
	
	// Make the instruction sequence, allocating memory first if needed

	if (instructionBufferLength < numInstr) {
		if (pInstructions != nil) {
			DisposePtr((char *)pInstructions);
		}
		pInstructions = (int *)NewPtr(numInstr * sizeof(int));
		if (pInstructions == nil) {
			NSRunAlertPanel(@"LLITC18IODevice",  @"Fatal error: Could not alloc pInstructions memory.", 
						@"OK", nil, nil);
			exit(0);
		}
		if (pSamples != nil) {
			DisposePtr((char *)pSamples);
		}
		pSamples = (short *)NewPtr(numInstr * sizeof(short));
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
		if ((itc = NewPtr(ITC18_GetStructureSize())) == nil) {
			NSRunAlertPanel(@"LLITC18IODevice",  @"Failed to allocate pLocal memory.", @"OK", nil, nil);
			exit(0);
		}
	}
	else {
        ITC18_Close(itc);
	}

// Now the ITC is closed, and we have a valid pointer

	if (ITC18_Open(itc, deviceNum) != noErr) {			// no ITC, return
		DisposePtr(itc);
		itc = nil;
		devicePresent = NO;
        [deviceLock unlock];
		return devicePresent;
	}

// the ITC has opened, now initialize it

	if (ITC18_Initialize(itc, ITC18_STANDARD) != noErr) { 
		DisposePtr(itc);
		if (devicePresent) {
			NSRunAlertPanel(@"LLITC18IODevice",  @"An ITC18 Laboratory Interface card was found, but the\
						remote device did not initialize correctly.", @"OK", nil, nil);
		}
		devicePresent = NO;
        [deviceLock unlock];
		return devicePresent;
	}
	devicePresent = YES;
    [deviceLock unlock];
	return devicePresent;
}

// Read data from the ITC, appending values to the samples and timestamps buffers

- (void)readData;
{
	short index, bitIndex, sampleChannel;
	unsigned short whichBit;
	BOOL bitOn;
	int available;

    [deviceLock lock];

// When a sequence is started, the first three entries in the FIFO 
// are garbage.  They should be thrown out.  

	if (justStartedITC18) {
		ITC18_GetFIFOReadAvailable(itc, &available);
		if (available < kGarbageLength + 1) {
            [deviceLock unlock];
			return;
		}
		ITC18_ReadFIFO(itc, kGarbageLength, pSamples);
		justStartedITC18 = NO;
	}

// If no real data are ready, there is nothing to do.
		
	ITC18_GetFIFOReadAvailable(itc, &available);
	if (available < numInstr + 1) {		
        [deviceLock unlock];
		return;
	}

// Keep unloading complete cycles of A/D values while any are available

	ITC18_GetFIFOReadAvailable(itc, &available);
	while (available > numInstr) {						// must have 1 more than a cycle, so ITC doesn't go empty
		ITC18_ReadFIFO(itc, numInstr, pSamples);						// read all the data
		for (index = sampleChannel = 0; index < numInstr; index++) {	// for every instruction

// If this is a digital input word, process as a timestamp

			if ((index % instrPerDigitalInput) == 0) {					// digital input instruction
				digitalInputBits = pSamples[index];						// save the digital input word
				for (bitIndex = 0; bitIndex < kLLITC18DigitalBits; bitIndex++) { // check every bit
					whichBit = (0x1 << bitIndex);						// get the bit pattern for one bit
					if (whichBit & timestampChannels) {					// enabled bit?
						bitOn = (whichBit & pSamples[index]); 			// bit on?
						if (timestampActiveBits & whichBit) {			// was active
							if (!bitOn) {								//  but now inactive
								timestampActiveBits &= ~whichBit;		//  so clear flag
							}
						}
						else if (bitOn) {								// active now but was not before
							timestampActiveBits |= whichBit;			// flag channel as active
							values.timestampCount[bitIndex]++;			// increment timestamp count
							[timestampLock lock];						// add to timestamp buffer
							[timestampData[bitIndex] appendBytes:&timestampTime length:sizeof(long)];
							[timestampLock unlock];
						}
					}
				}

// If this is the end of a digital cycle, advance the time base for digial input

				if (((index / instrPerDigitalInput) % kOverSample) == (kOverSample - 1)) {
					timestampTime++;
				}
			}

// If this is an A/D sample, save it (only kLLITC18ADChannels of AD samples in each set of pSamples)

			else if (sampleChannel < kLLITC18ADChannels) {
				[sampleLock lock];										// add to AD sample buffer
				[sampleData[sampleChannel] appendBytes:&pSamples[index] length:sizeof(short)];
				[sampleLock unlock];									// add to AD sample buffer
				sampleChannel++;
			}
		}
		values.samples++; 
		ITC18_GetFIFOReadAvailable(itc, &available);					// update the available count
	}
    [deviceLock unlock];
}

- (void)setDataEnabled:(NSNumber *)state;
{
    int available;
	
	if (itc == nil) {
		return;
	}
	if ([state boolValue] && !dataEnabled && instructionsLoaded) {
        [deviceLock lock];
		timestampOverflow = NO;
		timestampTime = 0;
        timestampActiveBits = 0x0;
        justStartedITC18 = YES;
        [monitor initValues:&values];
        values.samplePeriodMS = [[samplePeriodMS objectAtIndex:0] floatValue];
        values.instructionPeriodMS = [[samplePeriodMS objectAtIndex:0] floatValue] / numInstr;
        ITC18_InitializeAcquisition(itc);
        ITC18_SetSamplingInterval(itc, ITCTicksPerInstruction, false);
        sequenceStartTimeS = [LLSystemUtil getTimeS];
        ITC18_Start(itc, NO, NO, NO, NO);		// no trigger, no output, no stopOnOverflow, (reserved)
		dataEnabled = YES;
        [deviceLock unlock];
	}
	else if (![state boolValue] && dataEnabled) {
        values.cumulativeTimeMS = ([LLSystemUtil getTimeS] - sequenceStartTimeS) * 1000.0;
        [deviceLock lock];
        ITC18_Stop(itc);										// stop the ITC18
		[deviceLock unlock];
       
// Check whether the number of samples collected is what is predicted based on the elapsed time.
// This is a check for drift between the computer clock and the ITC-18 clock.  The first step
// is to drain any complete sample sets from the FIFO.  Then we see how many instructions
// remain in the FIFO (as an incomplete sample set).

		[self readData];										// drain FIFO
        ITC18_GetFIFOReadAvailable(itc, &available);
        values.sequences = 1;
        values.instructions = values.samples * numInstr + available; 
		if (values.instructions == 0) {
			NSLog(@" ");
			NSLog(@"WARNING: LLITC18: values.instructions == 0");
			NSLog(@"sequenceStartTimeS: %f", sequenceStartTimeS);
			NSLog(@"time now: %f", [LLSystemUtil getTimeS]);
			NSLog(@"timestampTime: %d", timestampTime);
			NSLog(@"justStartedITC18: %d", justStartedITC18);
			NSLog(@"dataEnabled: %d", dataEnabled);
			NSLog(@"values.cumulativeTimeMS: %f", values.cumulativeTimeMS);
			NSLog(@"values.samples: %d", values.samples);
			NSLog(@"values.samplePeriodMS: %f", values.samplePeriodMS);
			NSLog(@"values.instructions: %d", values.instructions);
			NSLog(@"values.instructionPeriodMS: %f", values.instructionPeriodMS);
			NSLog(@"values.sequences: %d", values.sequences);
			NSLog(@" ");
		}
		else {
			[monitor sequenceValues:values];
		}
		dataEnabled = NO;
	}
}

- (NSData **)sampleData;
{
	long channel;

	if (itc == nil) {
		return nil;
	}
	[self readData];								// read data from ITC18
	[sampleLock lock];								// check whether there are samples to return
	for (channel = 0; channel < kLLITC18ADChannels; channel++) {
		if ([sampleData[channel] length] > 0) {
			sampleResults[channel] = [NSData dataWithData:sampleData[channel]];
			[sampleData[channel] setLength:0];
		}
		else {
			sampleResults[channel] = nil;
		}
	}
	[sampleLock unlock];
	return sampleResults;								// return samples
}

- (void)setSamplePeriodMS:(float)newPeriodMS channel:(long)channel;
{
	[super setSamplePeriodMS:newPeriodMS channel:channel];
	[self loadInstructionSequence];
}

- (void)setTimestampTicksPerMS:(long)newTicksPerMS channel:(long)channel;
{
	[super setTimestampTicksPerMS:newTicksPerMS channel:channel];
	[self loadInstructionSequence];
}

- (NSData **)timestampData;
{
	long channel;
	
	if (itc == nil) {
		return nil;
	}
	[self readData];									// read data from ITC18
	[timestampLock lock];								// check whether there are timestamps to return
	for (channel = 0; channel < kLLITC18DigitalBits; channel++) {
		if ([timestampData[channel] length] > 0) {
			timestampResults[channel] = [NSData dataWithData:timestampData[channel]];
			[timestampData[channel] setLength:0];
		}
		else {
			timestampResults[channel] = nil;
		}
	}
	[timestampLock unlock];
	return timestampResults;								// return samples
}

@end