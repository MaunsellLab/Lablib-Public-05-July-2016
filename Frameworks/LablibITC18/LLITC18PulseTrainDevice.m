//
//  LLITC18PulseTrainDevice.m 
//  Lablib
//
//  Created by John Maunsell on Aug 29 2008
//  Copyright (c) 2008. All rights reserved. 
//

#import "LLITC18PulseTrainDevice.h"					
#import <ITC/Itcmm.h>
#import <ITC/ITC18.h>
#import <unistd.h>

#define kDriftTimeLimitMS	0.010
#define kDriftFractionLimit	0.001
#define kGarbageLength		3					// Invalid entries at the start of sequence
#define	kITC18TicksPerMS	800L				// Time base for ITC18
#define kITC18TickTimeUS	1.25
#define kMaxDAChannels		8
#define kOverSample			4

static short ADInstructions[] = {ITC18_INPUT_AD0, ITC18_INPUT_AD1, ITC18_INPUT_AD2,  ITC18_INPUT_AD3};
static short DAInstructions[] = {ITC18_OUTPUT_DA0, ITC18_OUTPUT_DA1, ITC18_OUTPUT_DA2,  ITC18_OUTPUT_DA3};

@implementation LLITC18PulseTrainDevice

// Close the ITC18.  

- (void)close {

	if (itcExists) {
		[deviceLock lock];
		ITC18_Close(itc);
		DisposePtr(itc);
		itc = nil;
		[deviceLock unlock];
	}
}

//- (BOOL)dataEnabled {
//	
//	return dataEnabled;
//}

- (void)dealloc;
{
	long index;

	[self close];
	for (index = 0; index < channels; index++) {
		[inputSamples[index] release];
	}
	[deviceLock release];
	[super dealloc];
}

- (void)digitalOutputBits:(unsigned long)bits;
{
	if (itcExists) {
		digitalOutputWord = bits;
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
	}
}

- (void)digitalOutputBitsOff:(unsigned short)bits {

	if (itcExists) {
		digitalOutputWord &= ~bits;
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
	}
}

- (void)digitalOutputBitsOn:(unsigned short)bits {

	if (itcExists) {
		digitalOutputWord |= bits;
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
	}
}

//- (unsigned short)digitalInputValues {
//
//	return digitalInputWord;
//}

// Get the number of entries ready to be read from the FIFO.  We assume that the device has been locked before
// this method is called

- (int)getAvailable;
{
	int available, overflow;
	
	ITC18_GetFIFOReadAvailableOverflow(itc, &available, &overflow);
	if (overflow != 0) {
		NSRunAlertPanel(@"LLITC18PulseTrainDevice",  @"Fatal error: FIFO overflow", @"OK", nil, nil);
		exit(0);
	}
	return available;
}

- (BOOL)hasITC18 {

	return itcExists;
}

- (void)doInitializationWithDevice:(long)numDevice {

	long index; 
	int ranges[ITC18_AD_CHANNELS];

	itc = nil;
	deviceLock = [[NSLock alloc] init];
	if ([self open:numDevice]) {
		for (index = 0; index < ITC18_AD_CHANNELS; index++) {	// Set AD voltage range
			ranges[index] = ITC18_AD_RANGE_10V;
		}
		[deviceLock lock];
		ITC18_SetRange(itc, ranges);
		ITC18_SetDigitalInputMode(itc, YES, NO);				// latch and do not invert
		FIFOSize = ITC18_GetFIFOSize(itc);
		[deviceLock unlock];
	}
}

- (id)init {

	if ((self = [super init]) != nil) {
		[self doInitializationWithDevice:0];
	}
	return self;
}

// Initialization tests for the existence of the ITC, and initializes it if it is there.
// The ITC initialization sets thd AD voltage, and also set the digital input to latch.
// ITC-18 latching is not the same thing as edge triggering.  A short pulse will produce a positive 
// value at the next read, but a steady level can also produce a series of positive values.

- (id)initWithDevice:(long)numDevice {

	if ((self = [super init]) != nil) {
		[self doInitializationWithDevice:numDevice];
	}
	return self;
}

// Open and initialize the ITC18

- (BOOL)open:(long)deviceNum;
{
	long code;
	long interfaceCodes[] = {0x0, USB18_CL};

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

	for (code = 0, itcExists = NO; code < sizeof(interfaceCodes) / sizeof(long); code++) {
		NSLog(@"LLITC18DataDevice: attempting to initialize device %d using code %d",
					deviceNum, deviceNum | interfaceCodes[code]);
		if (ITC18_Open(itc, deviceNum | interfaceCodes[code]) != noErr) {
			continue;									// failed, try another code
		}

	// the ITC has opened, now initialize it

		if (ITC18_Initialize(itc, ITC18_STANDARD) != noErr) {
			ITC18_Close(itc);							// failed, close to try again
		}
		else {
			itcExists = YES;						// successful initialization
			break;
		}
	}
	if (itcExists) {
		NSLog(@"LLITC18PulseTrainDevice: succeeded initialize device %d using code %d",
					deviceNum, deviceNum | interfaceCodes[code]);
		ITC18_SetDigitalInputMode(itc, YES, NO);				// latch and do not invert
		ITC18_SetExternalTriggerMode(itc, NO, NO);				// no external trigger
	}
	else {
		DisposePtr(itc);
		itc = nil;
	}
	[deviceLock unlock];
	return itcExists;
}

	
- (BOOL)makeInstructionsFromTrainData:(PulseTrainData *)pTrain channels:(long)activeChannels;
{
	short values[kMaxChannels + 1], gateAndPulseBits, gateBits, *sPtr;
	long index, DASampleSetsInTrain, DASampleSetsPerPhase, sampleSetIndex, ticksPerInstruction;
	long gatePorchUS, sampleSetsInPorch, porchBufferLength;
	long pulseCount, DASamplesPerPulse, durationUS, instructionsPerSampleSet, valueIndex;
	int writeAvailable, result;
	float instructionPeriodUS, pulsePeriodUS, rangeFraction[kMaxChannels];
	NSMutableData *trainValues, *pulseValues, *porchValues;
	int ITCInstructions[kMaxChannels + 1];

	if (!itcExists) { 
		return NO; 
	}
	
// We take common values from the first entry, on the assumption that others have been checked and are the same
	
	channels = MIN(activeChannels, ITC18_NUMBEROFDACOUTPUTS);
	instructionsPerSampleSet = channels + 1;
	gatePorchUS = (pTrain->doGate) ? pTrain->gatePorchMS * 1000.0 : 0;
	durationUS = pTrain->durationMS * 1000.0;
	
// First determine the DASample period.  We require the entire stimulus to fit within the ITC-18 FIFO.
// We divide down to allow for enough DA (channels) and Digital (1) samples, and a factor of safety (2x)
    
	ticksPerInstruction = ITC18_MINIMUM_TICKS;
	while ((durationUS + 2 * gatePorchUS) / (kITC18TickTimeUS * ticksPerInstruction) > 
											FIFOSize / (instructionsPerSampleSet * 2)) {
		ticksPerInstruction++;
	}
	if (ticksPerInstruction > ITC18_MAXIMUM_TICKS) {
		return NO;
	}
	
// Precompute values
	
	instructionPeriodUS = ticksPerInstruction * kITC18TickTimeUS;
	DASampleSetPeriodUS = instructionPeriodUS * instructionsPerSampleSet;
	DASampleSetsPerPhase = round(pTrain->pulseWidthUS / DASampleSetPeriodUS);
	sampleSetsInPorch = gatePorchUS / DASampleSetPeriodUS;		// DA samples in the gate porch
	DASampleSetsInTrain = durationUS / DASampleSetPeriodUS;		// DA samples in entire train
	bufferLength = MAX(DASampleSetsInTrain * instructionsPerSampleSet, instructionsPerSampleSet);
	pulsePeriodUS = (pTrain->frequencyHZ > 0) ? 1.0 / pTrain->frequencyHZ * 1000000.0 : 0;
	gateBits = ((pTrain->doGate) ? (0x1 << pTrain->gateBit) : 0);
	gateAndPulseBits = gateBits | ((pTrain->doPulseMarkers) ? (0x1 << pTrain->pulseMarkerBit) : 0);
	
// Create and load an array with output values that make up one pulse (DA and digital)
	
	DASamplesPerPulse = DASampleSetsPerPhase * (pTrain->pulseBiphasic) ? 2 : 1;
	if (DASamplesPerPulse > 0) {
		for (index = 0; index < channels; index++) {
			rangeFraction[index] = (pTrain[index].amplitude / pTrain[index].fullRangeV) /
				((pTrain[index].pulseType == kCurrentPulses) ? pTrain[index].UAPerV : 1);
		}
		pulseValues = [[NSMutableData alloc] initWithLength:DASamplesPerPulse * instructionsPerSampleSet * sizeof(short)];
		for (index = 0; index < channels; index++) {
			values[index] = rangeFraction[index] * 0x7fff;		// amplitude might be positive or negative
		}
		values[index] = gateAndPulseBits;						// digital output word
		for (sampleSetIndex = 0; sampleSetIndex < DASampleSetsPerPhase; sampleSetIndex++) {
			[pulseValues replaceBytesInRange:NSMakeRange(sampleSetIndex * sizeof(short) * instructionsPerSampleSet, 
						sizeof(short) * instructionsPerSampleSet) withBytes:&values];
		}
		if (pTrain->pulseBiphasic) {
			for (index = 0; index < channels; index++) {
				values[index] = -rangeFraction[index] * 0x7fff;		// amplitude might be positive or negative
			}
			values[index] = gateAndPulseBits;						// digital output word
			for (sampleSetIndex = 0; sampleSetIndex < DASampleSetsPerPhase; sampleSetIndex++) {
				[pulseValues replaceBytesInRange:
				 NSMakeRange((DASampleSetsPerPhase + sampleSetIndex) * sizeof(short) * instructionsPerSampleSet, 
							 sizeof(short) * instructionsPerSampleSet) withBytes:&values];
			}
		}
	}
	
// Create an array with the entire output sequence.  It is created zeroed.  If there is a gating signal,
// we add that to the digital output values.  bufferLength is always at least as long as instructionsPerSampleSet.
	
	trainValues = [[NSMutableData alloc] initWithLength:bufferLength * sizeof(short)];
	if (gateBits > 0) {
		sPtr = [trainValues mutableBytes];
		for (index = 0; index < DASampleSetsInTrain; index++) {
			sPtr += channels;							// skip over analog values
			*(sPtr)++ = gateBits;						// set the gate bits
		}
	}
	
// Modify the output sequence to include the pulses.  If the stimulation frequency is zero
// (pulsePeriodUS set to 0), we load no pulses.  If the duration is shorter than one pulse, nothing
// is loaded.  If the pulseWidth is zero, nothing is loaded.
	
	if ((pulsePeriodUS > 0) && (DASampleSetsPerPhase > 0)) {
		for (pulseCount = 0; ; pulseCount++) {
			sampleSetIndex = pulseCount * pulsePeriodUS / DASampleSetPeriodUS;
			valueIndex = sampleSetIndex * instructionsPerSampleSet;
			if ((valueIndex + DASamplesPerPulse * ((pTrain->pulseBiphasic) ? 2 : 1) + 1) >= bufferLength) {
				break;
			}
			[trainValues replaceBytesInRange:NSMakeRange(valueIndex * sizeof(short), 
						[pulseValues length]) withBytes:[pulseValues bytes]];
		}
	}
	
// If there the gate has a front and back porch, add the porches to the instructions
	
	if (sampleSetsInPorch > 0) {
		porchBufferLength = sampleSetsInPorch * instructionsPerSampleSet;
		porchValues = [[NSMutableData alloc] initWithLength:(porchBufferLength * sizeof(short))];
		sPtr = [porchValues mutableBytes];
		for (index = 0; index < sampleSetsInPorch; index++) {
			sPtr += channels;							// skip over analog values
			*(sPtr)++ = gateBits;						// set the gate bits
		}
		[trainValues appendData:porchValues];	 		// stim train, back porch
		[porchValues appendData:trainValues];			// front porch, stim train, back porch
		[trainValues release];							// release unneeded data
		trainValues = porchValues;						// make trainValues point to the whole set
		bufferLength += 2 * porchBufferLength;			// tally the buffer length with both porches
	}
	
// Make the last digital output word in the buffer close the gate (0x00)
	
	[trainValues resetBytesInRange:NSMakeRange((bufferLength - 1) * sizeof(short), sizeof(short))];

// Set up the ITC for the stimulus train.  Do everything except the start
	
	for (index = 0; index < channels; index++) {
		ITCInstructions[index] = 
			ADInstructions[pTrain[index].DAChannel] | DAInstructions[pTrain[index].DAChannel] | 
						ITC18_INPUT_UPDATE | ITC18_OUTPUT_UPDATE;
	} 
	ITCInstructions[index] = ITC18_OUTPUT_DIGITAL1 | ITC18_INPUT_SKIP | ITC18_OUTPUT_UPDATE;
	[deviceLock lock];
	ITC18_SetSequence(itc, channels + 1, ITCInstructions); 
	ITC18_StopAndInitialize(itc, YES, YES);
    ITC18_GetFIFOWriteAvailable(itc, &writeAvailable);
	if (writeAvailable < DASampleSetsInTrain) {
		NSRunAlertPanel(@"LLITC18PulseTrainDevice",  @"An ITC18 Laboratory Interface card was found, but the\
						write buffer was full.", @"OK", nil, nil);
		[trainValues release];
		return NO;
	}
    result = ITC18_WriteFIFO(itc, bufferLength, (short *)[trainValues bytes]);
	[trainValues release];
    if (result != noErr) { 
        NSLog(@"Error ITC18_WriteFIFO, result: %d", result);
        return NO;
    }
	ITC18_SetSamplingInterval(itc, ticksPerInstruction, NO);
	samplesReady = NO;
	[deviceLock unlock];
	return YES;
}

- (void)readData;
{
	short index, *samples, *pSamples, *channelSamples[ITC18_NUMBEROFDACOUTPUTS];
	long sets, set;
	int available;
	NSAutoreleasePool *threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread

	sets = bufferLength / (channels + 1);										// number of sample sets in stim
	samples = malloc(sizeof(short) * bufferLength);
	for (index = 0; index < channels; index++) {
		channelSamples[index] = malloc(sizeof(short) * sets);
	}

// When a sequence is started, the first three entries in the FIFO are garbage.  They should be thrown out.  
	
	[deviceLock lock];			// Wait here for the lock, then check time again
	while ((available = [self getAvailable]) < kGarbageLength + 1) {
		usleep(1000);
	}
	ITC18_ReadFIFO(itc, kGarbageLength, samples);
	
// Wait for the stimulus to be over.
	
	while ((available = [self getAvailable]) < bufferLength) {
		usleep(10000);
	}

// When all the samples are available, read them and unpack them
	
	ITC18_ReadFIFO(itc, bufferLength, samples);							// read all available sets
///	for (set = 0; set < 100; set++) {
//		NSLog(@"%d value %d", set, samples[set]);
//	}
	for (set = 0; set < sets; set++) {									// process each set
		pSamples = &samples[(channels + 1) * set];						// point to start of a set
		for (index = 0; index < channels; index++) {					// for every channel
			channelSamples[index][set] = *pSamples++;
		}
	}
//	for (set = 250; set < 300; set++) {
//		NSLog(@"Channel 0 %d value %d", set, channelSamples[0][set]);
//	}
//	for (set = 0; set < 100; set++) {
//		NSLog(@"Channel 1 %d value %d", set, channelSamples[1][set]);
//	}
	for (index = 0; index < channels; index++) {
		[inputSamples[index] release];
		inputSamples[index] = [[NSData dataWithBytes:channelSamples[index] length:(sets * sizeof(short))] retain];
	}
//	NSLog(@"Channel 0:\n%@", inputSamples[0]);
	samplesReady = YES;
	[deviceLock unlock];
    [threadPool release];
}

- (NSData **)sampleData;
{
	if (!itcExists) {								// return nil data when no device is present
		return inputSamples;
	}
	if (!samplesReady) {
		return nil;
	}
	else {
		samplesReady = NO;
		return inputSamples;
	}
}

- (float)samplePeriodUS;
{
	return DASampleSetPeriodUS;
}

// Report whether it is safe to call sampleData

- (BOOL)samplesReady;
{
	return (samplesReady || !itcExists);
}
/* 
 Get new stimulation parameter data and load the instruction sequence in the ITC-18.  The array argument may 
 contain parameter descriptions for up to 8 different channels.  In the current configuration, all channels
 have synchronous pulses (all biphasic or all monophasic, all synchronous, same frequency).  Only the number of
 channels and their amplitudes can vary.

 We create a buffer
 in which alternate words are DA values and digital output words (to gate the train and mark the pulses).  
 We load the entire stimulus into the buffer, so that no servicing is needed.
 */

- (BOOL)setTrainArray:(NSArray *)array;
{
	BOOL doPulseMarkers, doGate, pulseBiphasic;
	long index, DAchannels, pulseType, durationMS, gateBit, pulseMarkerBit, pulseWidthUS;
	float frequencyHZ, fullRangeV, UAPerV;
	PulseTrainData trainData[kMaxDAChannels];
	NSValue *value;
	
	DAchannels = [array count];  
	if (!itcExists || (DAchannels == 0)) {
		return YES;
	}
	
// Check that the entries are within limits, then unload the data
	
	if (DAchannels > ITC18_NUMBEROFDACOUTPUTS) {
		NSRunAlertPanel(@"LLITC18PulseTrainDevice",  @"Too many channels requested.  Ignoring request.", @"OK", nil, nil);
		return NO;
	}
	for (index = 0; index < DAchannels; index++) {
		value = [array objectAtIndex:index];
		[value getValue:&trainData[index]];
		if (index == 0) {
			doPulseMarkers = trainData[index].doPulseMarkers;
			doGate = trainData[index].doGate;
			pulseBiphasic = trainData[index].pulseBiphasic;
			pulseType = trainData[index].pulseType;
			durationMS = trainData[index].durationMS;
			gateBit = trainData[index].gateBit;
			pulseMarkerBit = trainData[index].pulseMarkerBit; 
			pulseWidthUS = trainData[index].pulseWidthUS;
			frequencyHZ = trainData[index].frequencyHZ;
			fullRangeV = trainData[index].fullRangeV;
			UAPerV = trainData[index].UAPerV;		
		}
		else if (doPulseMarkers != trainData[index].doPulseMarkers|| doGate != trainData[index].doGate ||
			pulseBiphasic != trainData[index].pulseBiphasic || pulseType != trainData[index].pulseType ||
			durationMS != trainData[index].durationMS || gateBit != trainData[index].gateBit ||
			pulseMarkerBit != trainData[index].pulseMarkerBit ||  pulseWidthUS != trainData[index].pulseWidthUS ||
			frequencyHZ != trainData[index].frequencyHZ || fullRangeV != trainData[index].fullRangeV ||
				 UAPerV != trainData[index].UAPerV) {
			NSRunAlertPanel(@"LLITC18PulseTrainDevice",  @"Incompatible values requested on different DA channels.", 
							@"OK", nil, nil);
			return NO;
		}			
	} 
	return [self makeInstructionsFromTrainData:trainData channels:DAchannels];
}

/* 
Get new stimulation parameter and load the instruction sequence in the ITC-18.  We create a buffer
in which alternate words are DA values and digital output words (to gate the train and mark the pulses).  
We load the entire stimulus into the buffer, so that no servicing is needed.
*/

- (BOOL)setTrainParameters:(PulseTrainData *)pTrain;
{
	return [self makeInstructionsFromTrainData:pTrain channels:1];
}

- (void)stimulate;
{
	if (!itcExists) {
		return;
	}
	[deviceLock lock];
	ITC18_Start(itc, NO, YES, NO, NO);				// Start with no external trigger, output enabled
	[deviceLock unlock];
	[NSThread detachNewThreadSelector:@selector(readData) toTarget:self withObject:nil];
}

@end