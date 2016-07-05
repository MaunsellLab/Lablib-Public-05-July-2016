//
//  LLITC18DataDevice.m 
//  Lablib
//
//  Created by John Maunsell on Mon Jun 09 2003.
//  Copyright (c) 2006. All rights reserved. 
//

/*
This LLDataDevice allows for different rates of sampling on different AD and timestamp channels.  The approach used
is to sample every channel at a rate fast enough to satisfy the fastest sampling rate, and to throw out samples that
are not needed.  One sample of every channel is sometimes called a chunk. This approach causes a bit of jitter.  For 
example, if the fastest sampling is once per 2 ms and a second channel needs samples every 3 ms, the second channel 
will get the following samples taken at the following times (ms): 0, 4, 6, 10, 12, 16, 18, etc.  Obviously this is 
imperfect, but hardware limitations force the ITC18 to sample at some fixed interval, and no interval can satisfy 
all sampling rate perfectly.

There are limits on how fast channels can be sampled.  The ITC runs at 800 ticks per ms (kITC18TicksPerMS), but can
sample no faster than once per 4 ticks (ITC18_MINIMUM_TICKS), or 200 kHz.  If only one AD channel is sampled, this rate
can be achieved, but the 200 kHz will be divided between the channels when more than one is sampled (e.g., 2 channels
at 100 kHz, 4 channels at 50 kHz, etc).  Digital sampling puts special demands on sampling. We need to oversample so
that we can see an on level and an off level associated with each digital pulse (spike).  While a factor of 2 might 
seem adequate, it is not because we use digital latching. We must latch because spikes are generally marked with 
short pulses, and we would be unlikely to catch these pulses.  To detect a low level when latching is enabled,
we must have 2 digital samples while the level is low.  If we allow for a worst case of a 50% duty cycle on the spike 
signal, then we need 4 samples per spike period.  Thus the maximum effective digitial sampling rate is 50 kHz
(200 kHz / 4).

The fastest sampling rate will be determined by the number of AD channels being sampled and whether or not digital
inputs are being sampled. If no digital input is being sampled, the maximum rates are:

Number of AD channels:				1		2		4		8
Maximum rate (kHz):					200		100		50		25

If digital inputs are being sampled, and the digital sampling rate is < 1/4 the highest AD sampling rate, the 
following limits apply:

Number of AD channels:				1		2		4		8
Maximum rate (kHz):					100		66.6	40		22.2

If digital inputs are being sampled, and the digitial sampling rate is > 1/4 the highest AD sampling rate (or 
there is no AD sampling rate), the following limits apply:

Number of AD channels:		0		1		2		4		8
Maximum rate (kHz):			50		25		25		25		16.6

The rate of digital sampling relative to the maximum AD sampling matters because it affects how the way that sampling
is sequenced.  If the digital sampling rate is less than 1/4 the maximum AD sampling rate, sampling is done at
the maximum AD rate, in the following sequence:

	Digital, first active AD, second active AD, ... last active AD.
							
Because the sampling rate is more than 4 times the requested digital sampling rate, this approach will satisfy the 
digital oversampling requirement.  If the digital sampling rate is >=  to 1/4 the maximum AD sampling rate, then 
sampling occurs as follows:

	Digital, AD samples, Digital, AD samples, Digital, AD samples, Digital, AD samples
							
In this sequence, the four "AD samples" will include one sample of each of the active channels, plus enough
padding to keep the number of ticks between the digital samples constant.  For example:

	Digital, AD0, AD4, Digital, AD5, AD6, Digital, AD7, ADSkip, Digital, ADSkip, ADSkip
	
or
	Digital, AD1, Digital, AD2, Digital, ADSkip, Digital, ADSkip
	
Because the maximum sampling rate changes when the number of active channels changes, whenever channels are enabled
all requested sampling rates are checked and lowered if necessary
*/

#import "LLITC18DataDevice.h" 
#import <Lablib/LLSystemUtil.h>
#import <Lablib/LLPluginController.h>
#import <ITC/Itcmm.h>
#import <ITC/ITC18.h>

#define kUseLLDataDevices							// needed for versioning

extern size_t malloc_size(void *ptr);

#define kIsDigitalInput(i)			((instructions[i] & ITC18_INPUT_DIGITAL) && (instructions[i] != ITC18_INPUT_SKIP))
#define kDigitalOverSample			4
#define kDriftTimeLimitMS			0.010
#define kDriftFractionLimit			0.001
#define kGarbageLength				3
#define	kReadDataIntervalS			(USB18 ? 0.005 : 0.000)

#define chunksAtOneTickPerInstructHz	(kLLITC18TicksPerMS * 1000.0 / numInstructions)
#define maxSampleRateHz					(chunksAtOneTickPerInstructHz / ITC18_MINIMUM_TICKS)
#define minSampleRateHz					(chunksAtOneTickPerInstructHz / ITC18_MAXIMUM_TICKS)

NSString *LLITC18InvertBit00Key = @"LLITC18InvertBit00";
NSString *LLITC18InvertBit15Key = @"LLITC18InvertBit15";

enum {kSampleTable = 0, kTimestampTable};

static long	ITCCount = 0;

@implementation LLITC18DataDevice


// I'm not sure we need to load the ITC framework. It should be picked up automatically. JHRM 120804

//+ (void)initialize;
//{
//	NSString *ITCFrameworkPath, *myBundlePath;
//	NSBundle *ITCFramework;
//
//	myBundlePath = [[NSBundle bundleForClass:[self class]] bundlePath];
//	if (![[myBundlePath pathExtension] isEqualToString:@"plugin"]) {
//		return;
//	}
//	ITCFrameworkPath = [myBundlePath stringByAppendingPathComponent:@"Contents/Frameworks/ITC.framework"];
//	ITCFramework = [NSBundle bundleWithPath:ITCFrameworkPath];
//	if ([ITCFramework load]) {
//		NSLog(@"ITC framework loaded");
//	}
//	else
//	{
//		NSLog(@"Error, ITC framework failed to load\nAborting.");
//		exit(1);
//	}
//}

+ (NSInteger)version;
{
	return kLLPluginVersion;
}

- (void)allocateSampleBuffer:(short **)ppBuffer size:(long)sizeInShorts;
{
	if (*ppBuffer == nil) {
		*ppBuffer = malloc(sizeof(short) * sizeInShorts);
	}
	else {
		*ppBuffer = reallocf(*ppBuffer, sizeof(short) * sizeInShorts);
	}
	if (*ppBuffer == nil) {
        [LLSystemUtil runAlertPanelWithMessageText:@"LLITC18IODevice"
                                   informativeText:@"Fatal error: Could not allocate sample memory."];
//		NSRunAlertPanel(@"LLITC18IODevice",  @"Fatal error: Could not allocate sample memory.",
//					@"OK", nil, nil);
		exit(0);
	}
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

- (void)configure;
{
	[self setDataEnabled:[NSNumber numberWithBool:NO]];
	[NSApp runModalForWindow:settingsWindow];
    [settingsWindow orderOut:self];
	[self loadInstructions];
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
    [topLevelObjects release];
	[super dealloc];
}

- (void)digitalOutputBits:(unsigned long)bits;
{
	short invertBit00, invertBit15;

	if (itc != nil) {
		invertBit00 = [[NSUserDefaults standardUserDefaults] integerForKey:LLITC18InvertBit00Key];
		invertBit15 = [[NSUserDefaults standardUserDefaults] integerForKey:LLITC18InvertBit15Key];
		digitalOutputWord = bits;
		if (invertBit00) {
			digitalOutputWord ^= 0x0001;
		}
		if (invertBit15) {
			digitalOutputWord ^=  0x8000;
		}
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)digitalOutputBitsOff:(unsigned long)bits;
{
	short invertBit00, invertBit15;

	if (itc != nil) {
		invertBit00 = [[NSUserDefaults standardUserDefaults] integerForKey:LLITC18InvertBit00Key];
		invertBit15 = [[NSUserDefaults standardUserDefaults] integerForKey:LLITC18InvertBit15Key];
		digitalOutputWord &= ~bits;
		if (invertBit00 && (bits & 0x0001)) {
			digitalOutputWord ^= 0x0001;
		}
		if (invertBit15 && (bits & 0x8000)) {
			digitalOutputWord ^= 0x8000;
		}
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)digitalOutputBitsOn:(unsigned long)bits;
{
	short invertBit00, invertBit15;

	if (itc != nil) {
		invertBit00 = [[NSUserDefaults standardUserDefaults] integerForKey:LLITC18InvertBit00Key];
		invertBit15 = [[NSUserDefaults standardUserDefaults] integerForKey:LLITC18InvertBit15Key];
		digitalOutputWord |= bits;
		if (invertBit00 && (bits & 0x0001)) {
			digitalOutputWord ^= 0x0001;
		}
		if (invertBit15 && (bits & 0x8000)) {
			digitalOutputWord ^= 0x8000;
		}
		[deviceLock lock];
		ITC18_WriteAuxiliaryDigitalOutput(itc, digitalOutputWord);
		[deviceLock unlock];
	}
}

- (void)disableSampleChannels:(NSNumber *)bitPattern;
{
	[super disableSampleChannels:bitPattern];
	[self loadInstructions];
}

// Initialization tests for the existence of the ITC, and initializes it if it is there.
// The ITC initialization sets thd AD voltage, and also set the digital input to latch.
// ITC-18 latching is not the same thing as edge triggering.  A short pulse will produce a positive 
// value at the next read, but a steady level can also produce a series of positive values.

- (void)doInitializationWithDevice:(long)requestedNum;
{
	long index; 
	int ranges[ITC18_AD_CHANNELS];
	long channel;
	float period;
	NSUserDefaults *defaults;
	NSString *defaultsPath;
    NSDictionary *defaultsDict;
	NSString *sampleKey = @"LLITC18SamplePeriodMS";
	NSString *timestampKey = @"LLITC18TimestampPeriodMS";
	NSString *keySuffix;

	deviceNum = (requestedNum >= 0) ? requestedNum : ITCCount;
	NSLog(@"attempting to initialize ITC18 device %ld", deviceNum);

// Register default sampling values

	defaultsPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"LLITC18DataDevice" ofType:@"plist"];
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
		keySuffix = [NSString stringWithFormat:@"%1ld", channel];
		period = [defaults floatForKey:[sampleKey stringByAppendingString:keySuffix]];
		[samplePeriodMS addObject:[NSNumber numberWithFloat:period]];
	}
	for (channel = 0; channel < kLLITC18DigitalBits; channel++)  {
		keySuffix = [NSString stringWithFormat:@"%02ld", channel];
		period = [defaults floatForKey:[timestampKey stringByAppendingString:keySuffix]];
		[timestampPeriodMS addObject:[NSNumber numberWithFloat:period]];
	}

	itc = nil;
	sampleLock = [[NSLock alloc] init];
	timestampLock = [[NSLock alloc] init];
	deviceLock = [[NSLock alloc] init];
	monitor = [[LLITCMonitor alloc] initWithID:[self name] description:@"Instrutech ITC-18 Lab I/O"];
	[self allocateSampleBuffer:&samples size:kMinSampleBuffer];
	if ([self openITC18:deviceNum]) {
		for (index = 0; index < ITC18_AD_CHANNELS; index++) {	// Set AD voltage range
			ranges[index] = ITC18_AD_RANGE_10V;
		}
		ITC18_SetRange(itc, ranges);
		ITC18_SetDigitalInputMode(itc, YES, NO);				// latch and do not invert
		[self loadInstructions];
		[self digitalOutputBits:0xffff];
	}
    [[NSBundle bundleForClass:[self class]] loadNibNamed:@"LLITC18DataSettings" owner:self
                                         topLevelObjects:&topLevelObjects];
    [topLevelObjects retain];
}

- (void)enableSampleChannels:(NSNumber *)bitPattern;
{
	[super enableSampleChannels:bitPattern];
	[self loadInstructions];
}

- (void)enableTimestampChannels:(NSNumber *)bitPattern;
{
	[super enableTimestampChannels:bitPattern];
	[self loadInstructions];
}

- (int)getAvailable;
{
	int available, overflow;
	
	ITC18_GetFIFOReadAvailableOverflow(itc, &available, &overflow);
	if (overflow != 0) {
        [LLSystemUtil runAlertPanelWithMessageText:@"LLITC18IODevice"
                                   informativeText:@"Fatal error: FIFO overflow"];
//		NSRunAlertPanel(@"LLITC18DataDevice",  @"Fatal error: FIFO overflow", @"OK", nil, nil);
		exit(0);
	}
	return available;
}

// Initialization tests for the existence of the ITC, and initializes it if it is there.
// The ITC initialization sets thd AD voltage, and also set the digital input to latch.
// ITC-18 latching is not the same thing as edge triggering.  A short pulse will produce a positive 
// value at the next read, but a steady level can also produce a series of positive values.

- (id)init;
{
	if ((self = [super init]) != nil) {
		[self doInitializationWithDevice:ITCCount++];
	}
	return self;
}

// Do the initialize with a particular ITC-18 device, rather than the default

- (id)initWithDevice:(long)requestedNum;
{
	if ((self = [super init]) != nil) {
		deviceNum = requestedNum;
		[self doInitializationWithDevice:deviceNum];
	}
	return self;
}

- (Ptr)itc;
{
	return itc;
}

/*
 Construct and load the ITC18 instruction set, setting the associated variables.  There are three different
 situations that generate different instructions sets: no digital sampling, digital sampling at less than 
 1/4 the fastest AD sampling, and digital sampling equal or greater than the fastest AD sampling rate
*/

- (void)loadInstructions;
{
	long channel, c, d;
	long enabledADChannels, maxADRateHz, maxDigitalRateHz, ADPerDigital;
	float channelPeriodMS;
	int ADCommands[] = {ITC18_INPUT_AD0, ITC18_INPUT_AD1, ITC18_INPUT_AD2, ITC18_INPUT_AD3,
						ITC18_INPUT_AD4, ITC18_INPUT_AD5, ITC18_INPUT_AD6, ITC18_INPUT_AD7};

// If no channels are enabled load do-nothing instructions
	
	if (sampleChannels == 0 && timestampChannels == 0) {
		for (c = 0; c < kLLITC18ADChannels; c++) {
			instructions[c] = ITC18_INPUT_SKIP;
		}
		numInstructions = kLLITC18ADChannels;
		if (itc != nil) {
			ITC18_SetSequence(itc, numInstructions, instructions);
		}
		return;
	}
	
// Find the fastest AD and digital sampling rates

	maxADRateHz = maxDigitalRateHz = enabledADChannels = 0;
	if (sampleChannels > 0) {
		for (channel = 0; channel < kLLITC18ADChannels; channel++) {
			if (sampleChannels & (0x01 << channel)) {
				enabledADChannels++;
				channelPeriodMS = [[samplePeriodMS objectAtIndex:channel] floatValue];
				maxADRateHz = MAX(round(1000.0 / channelPeriodMS), maxADRateHz);
			}
		}
	}
	if (timestampChannels > 0) {
		for (channel = 0; channel < kLLITC18DigitalBits; channel++) {
			if (timestampChannels & (0x01 << channel)) {
//				channelTicksPerMS = [[timestampTicksPerMS objectAtIndex:channel] longValue];
				channelPeriodMS = [[timestampPeriodMS objectAtIndex:channel] floatValue];
				timestampTickS[channel] = 0.001 * channelPeriodMS;
				maxDigitalRateHz = MAX(1000.0 / channelPeriodMS, maxDigitalRateHz);
			}
		}
	}

// NB: No new values are read into the ITC until a command with the ITC18_INPUT_UPDATE bit
// set is read.  This applies to the digital input lines as well as the AD lines.  For this
// reason, every digital input command must have the update bit set.   FURTHERMORE, it is
// essential that none of the AD read commands does an update unless no digital sampling is
// occuring.  If it does, it will cause the digital values to be updated, clearing any latched bits. 
//  When the next digital read command goes, its update will cause the a new digital word to be read, 
// so that any previously latched values that were updated by the Analog read command would be lost.

	
// If digital sampling is not rate determining, then we simply make a chunk of data that includes 
// one sample for each active channel

	numInstructions = 0; 

	if (maxDigitalRateHz * kDigitalOverSample < maxADRateHz) {
		if (maxDigitalRateHz > 0) {
			instructions[numInstructions++] = ITC18_INPUT_DIGITAL;
		}
		for (channel = 0; channel < kLLITC18ADChannels; channel++) {
			if (sampleChannels & (0x01 << channel)) {
				instructions[numInstructions++] = ADCommands[channel];
			}
		}
		instructions[0] |= ITC18_INPUT_UPDATE | ITC18_OUTPUT_TRIGGER;
	}
	
// If digital sampling is rate determining, then we make a chuck that includes enough digital samples
// to achieve the required oversampling, with the active AD channels embedded between the digital samples

	else {
		ADPerDigital = (enabledADChannels + 3) / kDigitalOverSample;
		channel = 0;
		for (d = 0; d < kDigitalOverSample; d++) {
			instructions[numInstructions++] = ITC18_INPUT_DIGITAL | ITC18_INPUT_UPDATE | ITC18_OUTPUT_TRIGGER;
			for (c = 0; c < ADPerDigital; c++) {
				while (channel < kLLITC18ADChannels && (!(sampleChannels & (0x01 << channel)))) {
					channel++;
				}
				instructions[numInstructions++] = (channel < kLLITC18ADChannels) ? ADCommands[channel] : ITC18_INPUT_SKIP;
				channel++;
			} 
		}
	}
	if (itc != nil) {
		ITC18_SetSequence(itc, numInstructions, instructions);
	}
	ITCTicksPerInstruction = chunksAtOneTickPerInstructHz / MAX(maxDigitalRateHz, maxADRateHz);
	ITCSamplePeriodS = (numInstructions * ITCTicksPerInstruction) / (kLLITC18TicksPerMS * 1000.0);

// When we change the instructions, we change the maximum sampling rate.  Make sure that all the sampling
// rates are attainable

	for (channel = 0; channel <  kLLITC18ADChannels; channel++) {
		if (![self setSamplePeriodMS:[[samplePeriodMS objectAtIndex:channel] floatValue] channel:channel]) {
			[self setSamplePeriodMS:(1000.0 / maxSampleRateHz) channel:channel];
		}
	}
	for (channel = 0; channel <  kLLITC18DigitalBits; channel++) {
		if (![self setTimestampPeriodMS:[[timestampPeriodMS objectAtIndex:channel] floatValue] channel:channel]) {
			[self setTimestampPeriodMS:(1000.0 / maxSampleRateHz) channel:channel];
		}
	}
}

- (id <LLMonitor>)monitor;
{
	return monitor;
}

- (NSString *)name;
{
	return ((deviceNum == 0) ? @"ITC-18" : [NSString stringWithFormat:@"ITC-18 %ld", deviceNum]);
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
{
    if ([tableView tag] == kSampleTable) {	
		return kLLITC18ADChannels;
    }
	else if ([tableView tag] == kTimestampTable) {
		return kLLITC18DigitalBits;
	}
	else {
        return 0;
    }
}

- (IBAction)ok:(id)sender;
{
	[NSApp stopModal];
}

// Open and initialize the ITC18

- (BOOL)openITC18:(long)devNum;
{
	long code;
	long interfaceCodes[] = {0x0, USB18_CL};

    [deviceLock lock];
	if (itc == nil) {						// currently opened?
		if ((itc = malloc(ITC18_GetStructureSize())) == nil) {
			[deviceLock unlock];
            [LLSystemUtil runAlertPanelWithMessageText:@"LLITC18IODevice"
                                       informativeText:@"Failed to allocate pLocal memory."];
//			NSRunAlertPanel(@"LLITC18IODevice",
//            @"Failed to allocate pLocal memory.", @"OK", nil, nil);
			exit(0);
		}
	}
	else {
        ITC18_Close(itc);
	}

// Now the ITC is closed, and we have a valid pointer

	for (code = 0, devicePresent = NO; code < sizeof(interfaceCodes) / sizeof(long); code++) {
		NSLog(@"LLITC18DataDevice: attempting to initialize device %ld using code %ld",
					devNum, devNum | interfaceCodes[code]);
		if (ITC18_Open(itc, devNum | interfaceCodes[code]) != noErr) {
			continue;									// failed, try another code
		}

	// the ITC has opened, now initialize it

		if (ITC18_Initialize(itc, ITC18_STANDARD) != noErr) {
			ITC18_Close(itc);							// failed, close to try again
		}
		else {
			USB18 = interfaceCodes[code] == USB18_CL;
			devicePresent = YES;						// successful initialization
			break;
		}
	}
	if (!devicePresent) {
		free(itc);
		itc = nil;
	}
	else {
		NSLog(@"LLITC18DataDevice: succeeded initialize device %ld using code %ld",
					devNum, devNum | interfaceCodes[code]);
	}
    [deviceLock unlock];
	return devicePresent;
}

// Read data from the ITC, appending values to the samples and timestamps buffers

- (void)readData;
{
	short index, bitIndex, sampleChannel, *pSamples;
	unsigned short whichBit, timestamp;
	long sets, set;
	BOOL bitOn;
	int available;

// Don't attempt to read if we just read a little while ago

	if (lastReadDataTimeS + kReadDataIntervalS > [LLSystemUtil getTimeS]) {
		return;
	}
	
    if (![deviceLock tryLock]) {
		[deviceLock lock];			// Wait here for the lock, then check time again
		if (lastReadDataTimeS + kReadDataIntervalS > [LLSystemUtil getTimeS]) {
			[deviceLock unlock];
			return;
		}
	}

// When a sequence is started, the first three entries in the FIFO are garbage.  They should be thrown out.  

	if (justStartedITC18) {
		available = [self getAvailable];
		if (available < kGarbageLength + 1) {
			lastReadDataTimeS = [LLSystemUtil getTimeS];
            [deviceLock unlock];
			return;
		}
		ITC18_ReadFIFO(itc, kGarbageLength, samples);
		justStartedITC18 = NO;
	}

// Unloading complete cycles of samples.  We gather all complete sets in one call to
// ITC18_ReadFIFO, and we don't check again when we are done.  This is prevent overloading
// the USB with frequent calls, which can happen if the sample sets are small and coming
// in at a fast rate.  We need to leave it so that they can be read in large sets. 

	available = [self getAvailable];
	if (available > numInstructions) {									// >, so ITC doesn't go empty
		sets = available / numInstructions;								// number of complete sets available
		if (numInstructions * sets * sizeof(short) > malloc_size(samples)) {
			[self allocateSampleBuffer:&samples size:numInstructions * sets];
		}
		ITC18_ReadFIFO(itc, numInstructions * sets, samples);			// read all available sets
		for (set = 0; set < sets; set++) {								// process each set
			pSamples = &samples[numInstructions * set];					// point to start of set
			for (index = sampleChannel = 0; index < numInstructions; index++) {	// for every instruction

	// If this is a digital input word, process as a timestamp

				if (kIsDigitalInput(index)) {								// digital input instruction
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
								timestamp = round(sampleTimeS / timestampTickS[bitIndex]);
								[timestampData[bitIndex] appendBytes:&timestamp length:sizeof(unsigned short)];
								[timestampLock unlock];
							}
						}
					}
				}

	// It's AD or a skipped sample.  If this is an A/D sample, save it (if it is enabled)

				else {
					while (sampleChannel < kLLITC18ADChannels && !(sampleChannels & (0x1 << sampleChannel))) {
						sampleChannel++;
					}
					if (sampleChannel < kLLITC18ADChannels && sampleTimeS >= nextSampleTimeS[sampleChannel]) {
						[sampleLock lock];										// add to AD sample buffer
						[sampleData[sampleChannel] appendBytes:&pSamples[index] length:sizeof(short)];
						nextSampleTimeS[sampleChannel] += [[samplePeriodMS objectAtIndex:sampleChannel] floatValue] / 1000.0;
						[sampleLock unlock];									// add to AD sample buffer
					}
					sampleChannel++;
				}
			}
			sampleTimeS += ITCSamplePeriodS;
			values.samples++; 
		}
	}
	lastReadDataTimeS = [LLSystemUtil getTimeS];
    [deviceLock unlock];
}

- (void)setDataEnabled:(NSNumber *)state;
{
    int available;
	long channel;
	double channelPeriodMS;
	long maxSamplingRateHz;
	
	if (itc == nil) {
		return;
	}
	if ([state boolValue] && !dataEnabled) {
        [deviceLock lock];
	
// Scan through the sample and timestamp sampling settings, finding the fastest enabled rate.
// The rate here is the requested sampling rate.  It does not take into account the need to
// oversample digital inputs because that is built into the instruction sequence

		for (channel = maxSamplingRateHz = 0; channel < kLLITC18ADChannels; channel++) {
			if (sampleChannels & (0x01 << channel)) {
				channelPeriodMS = [[samplePeriodMS objectAtIndex:channel] floatValue];
				nextSampleTimeS[channel] = channelPeriodMS / 1000.0;
				maxSamplingRateHz = MAX(1000.0 / channelPeriodMS, maxSamplingRateHz);
			}
		}
		for (channel = 0; channel < kLLITC18DigitalBits; channel++) {
			if (timestampChannels & (0x01 << channel)) {
				channelPeriodMS = [[timestampPeriodMS objectAtIndex:channel] floatValue];
				timestampTickS[channel] = 0.001 * channelPeriodMS;
				maxSamplingRateHz = MAX(1000.0 / channelPeriodMS, maxSamplingRateHz);
			}
		}
		if (maxSamplingRateHz != 0) {							// no channels enabled
			sampleTimeS = ITCSamplePeriodS;							// one period complete on first sample
			timestampActiveBits = 0x0;
			justStartedITC18 = YES;
			[monitor initValues:&values];
			values.samplePeriodMS = ITCSamplePeriodS * 1000.0;
			values.instructionPeriodMS = ITCSamplePeriodS / numInstructions * 1000.0;
			ITC18_SetSamplingInterval(itc, ITCTicksPerInstruction, false);
			ITC18_StopAndInitialize(itc, YES, YES);
			monitorStartTimeS = [LLSystemUtil getTimeS];
			ITC18_Start(itc, NO, NO, NO, NO);		// no trigger, no output, no stopOnOverflow, (reserved)
			dataEnabled = YES;
			lastReadDataTimeS = 0;
		}
        [deviceLock unlock];
	}
	else if (![state boolValue] && dataEnabled) {
        [deviceLock lock];
        ITC18_Stop(itc);										// stop the ITC18
		[deviceLock unlock];
        values.cumulativeTimeMS = ([LLSystemUtil getTimeS] - monitorStartTimeS) * 1000.0;
       
// Check whether the number of samples collected is what is predicted based on the elapsed time.
// This is a check for drift between the computer clock and the ITC-18 clock.  The first step
// is to drain any complete sample sets from the FIFO.  Then we see how many instructions
// remain in the FIFO (as an incomplete sample set).

		lastReadDataTimeS = 0;									// permit a FIFO read
		[self readData];										// drain FIFO
        [deviceLock lock];
		available = [self getAvailable];
		[deviceLock unlock];
        values.sequences = 1;
        values.instructions = values.samples * numInstructions + available; 
		if (values.instructions == 0) {
			NSLog(@" ");
			NSLog(@"WARNING: LLITC18: values.instructions == 0");
			NSLog(@"sequenceStartTimeS: %f", monitorStartTimeS);
			NSLog(@"time now: %f", [LLSystemUtil getTimeS]);
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

// Overload the methods for changing sampling rates to make sure that the value is allowed by 
// the limits on the sampling rate

- (BOOL)setSamplePeriodMS:(float)newPeriodMS channel:(long)channel;
{
	float newRateHz = 1000.0 / newPeriodMS;
	
	if (newRateHz >= minSampleRateHz && newRateHz <= maxSampleRateHz) {
		return [super setSamplePeriodMS:newPeriodMS channel:channel];
	}
	else {
		return NO;
	}
}

- (BOOL)setTimestampTicksPerMS:(long)newTicksPerMS channel:(long)channel;
{
	float newRateHz = newTicksPerMS * 1000;

	if (newRateHz >= minSampleRateHz && newRateHz <= maxSampleRateHz) {
		return [super setTimestampTicksPerMS:newTicksPerMS channel:channel];
	}
	else {
		return NO;
	}
}

// Always try to creaete a second ITC18 data device

- (BOOL)shouldCreateAnotherDevice;
{
    return (ITCCount == 1);
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
	unsigned long rows, enabledBits;
	NSArray *valueArray;
	
    if ([tableView tag] == kSampleTable) {
		rows = kLLITC18ADChannels;
		valueArray = samplePeriodMS;
		enabledBits = sampleChannels;
	}
	else if ([tableView tag] == kTimestampTable) {
		rows = kLLITC18DigitalBits;
		valueArray = timestampPeriodMS;
		enabledBits = timestampChannels;
	}
	else {
		return nil;
	}
	NSParameterAssert(row >= 0 && row < rows);
	if ([[tableColumn identifier] isEqual:@"enabled"]) {
		return [NSNumber numberWithBool:((enabledBits & (0x1 << row)) > 0)];
	}
	if ([[tableColumn identifier] isEqual:@"channel"]) {
		return [NSNumber numberWithInt:row];
	}
	if ([[tableColumn identifier] isEqual:@"periodMS"]) {
		return [valueArray objectAtIndex:row];
	}
	if ([[tableColumn identifier] isEqual:@"timestampPeriodMS"]) {
		return [valueArray objectAtIndex:row];
	}
	return @"???";
}

// This method is called when the user has put a new entry in the sample or timestamp tables in the
// settings dialog.  

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject 
					forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
{ 
	unsigned long rows, *pBits;
	
    if ([aTableView tag] == kSampleTable) {
		rows = kLLITC18ADChannels;
		pBits = &sampleChannels;
	}
	else if ([aTableView tag] == kTimestampTable) {
		rows = kLLITC18DigitalBits;
		pBits = &timestampChannels;
	}
	else {
		return;
	}
	NSParameterAssert(rowIndex >= 0 && rowIndex < rows);
	if ([[aTableColumn identifier] isEqual:@"enabled"]) {
		if ([anObject boolValue]) {
			*pBits |= (0x01 << rowIndex);
		}
		else {
			*pBits &= ~(0x01 << rowIndex);
		}
	}
	else if ([[aTableColumn identifier] isEqual:@"periodMS"]) {
		[self setSamplePeriodMS:[anObject floatValue] channel:rowIndex];
	}
	else if ([[aTableColumn identifier] isEqual:@"timestampPeriodMS"]) {
		[self setTimestampPeriodMS:[anObject floatValue] channel:rowIndex];
	}
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