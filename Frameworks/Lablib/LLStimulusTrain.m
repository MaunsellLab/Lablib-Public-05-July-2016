//
//  LLStimulusTrain.m
//  
//  This object supports the generation of microstimulation trains using the ITC-18.  
//  It only supports bi-phasic pulses, but allows adjustment of pulse width, pulse frequency,
//  and train duration.  It takes parameters to produce a properly calibrated DA sequence,
//  which is accessed using the method (NSData *)train.
//
//  Created by John Maunsell on Thu Jun 03 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLStimulusTrain.h"

NSString *LLSTAmplitudeKey = @"Stim Train Amplitude";
NSString *LLSTDurationKey = @"Stim Train Duration";
NSString *LLSTFrequencyKey = @"Stim Train Frequency";
NSString *LLSTPulseWidthKey = @"Stim Train Pulse Duration";
NSString *LLSTVoltageRangeKey = @"Stim Train Voltage Range";
NSString *LLSTDAChannelKey = @"Stim Train DA Channel";
NSString *LLSTMarkPulseBitKey = @"Stim Train Mark Pulse Channel";
NSString *LLSTMarkerPulsesKey = @"Stim Train Marker Pulses";
NSString *LLSTGateKey = @"Stim Train Gate";
NSString *LLSTGateBitKey = @"Stim Train Gate Channel";
NSString *LLSTUAPerVKey = @"Stim Train uA Per V";

@implementation LLStimulusTrain

- (IBAction)changeAmplitude:(id)sender {

    [[NSUserDefaults standardUserDefaults] setFloat:[sender floatValue] forKey:LLSTAmplitudeKey];
} 

- (IBAction)changeDAChannel:(id)sender {

    [[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:LLSTDAChannelKey];
} 

- (IBAction)changeDoGate:(id)sender {

    [[NSUserDefaults standardUserDefaults] setBool:[sender intValue] forKey:LLSTGateKey];
} 

- (IBAction)changeDoMarkers:(id)sender {

    [[NSUserDefaults standardUserDefaults] setBool:[sender intValue] forKey:LLSTMarkerPulsesKey];
} 

- (IBAction)changeDuration:(id)sender {

    [[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:LLSTDurationKey];
} 

- (IBAction)changeFrequency:(id)sender {

    [[NSUserDefaults standardUserDefaults] setFloat:[sender floatValue] forKey:LLSTFrequencyKey];
} 

- (IBAction)changeGateBit:(id)sender {

    [[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:LLSTGateBitKey];
} 

- (IBAction)changeMarkerBit:(id)sender {

    [[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:LLSTMarkPulseBitKey];
} 

- (IBAction)changePulseWidth:(id)sender {

    [[NSUserDefaults standardUserDefaults] setInteger:[sender intValue] forKey:LLSTPulseWidthKey];
} 

- (IBAction)changeUAPerV:(id)sender {

    [[NSUserDefaults standardUserDefaults] setFloat:[sender floatValue] forKey:LLSTUAPerVKey];
} 

- (id)init {

    NSMutableDictionary *defaultSettings;

    if ((self = [super initWithWindowNibName:@"LLStimulusTrain"])) {
	
		defaultSettings = [NSMutableDictionary dictionary];
		[defaultSettings setObject:[NSNumber numberWithFloat:1.0] forKey:LLSTAmplitudeKey];
		[defaultSettings setObject:[NSNumber numberWithInt:250] forKey:LLSTDurationKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:200.0] forKey:LLSTFrequencyKey];
		[defaultSettings setObject:[NSNumber numberWithInt:200] forKey:LLSTPulseWidthKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:10.0] forKey:LLSTVoltageRangeKey];
		[defaultSettings setObject:[NSNumber numberWithInt:0] forKey:LLSTDAChannelKey];
		[defaultSettings setObject:[NSNumber numberWithInt:0] forKey:LLSTMarkPulseBitKey];
		[defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:LLSTMarkerPulsesKey];
		[defaultSettings setObject:[NSNumber numberWithInt:1] forKey:LLSTGateBitKey];
		[defaultSettings setObject:[NSNumber numberWithBool:YES] forKey:LLSTGateKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:1.0] forKey:LLSTUAPerVKey];
		[defaultSettings setObject:[NSNumber numberWithFloat:10.24] forKey:LLSTVoltageRangeKey];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultSettings];
	}
	return self;
}

- (StimTrainData *)trainData {

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	stimTrain.amplitudeUA = [defaults floatForKey:LLSTAmplitudeKey];
	stimTrain.DAChannel = [defaults integerForKey:LLSTDAChannelKey];
	stimTrain.doPulseMarkers = [defaults integerForKey:LLSTMarkerPulsesKey];
	stimTrain.doGate = [defaults integerForKey:LLSTGateKey];
	stimTrain.durationMS = [defaults integerForKey:LLSTDurationKey];
	stimTrain.frequencyHZ = [defaults floatForKey:LLSTFrequencyKey]; 
	stimTrain.gateBit = [defaults integerForKey:LLSTGateBitKey];
	stimTrain.pulseMarkerBit = [defaults integerForKey:LLSTMarkPulseBitKey];
	stimTrain.pulseWidthUS = [defaults integerForKey:LLSTPulseWidthKey]; 
	stimTrain.fullRangeV = [defaults floatForKey:LLSTVoltageRangeKey]; 
	stimTrain.UAPerV = [defaults floatForKey:LLSTUAPerVKey];
	
	return &stimTrain;
}

- (void)loadDialogEntries {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [amplitudeField setFloatValue:[defaults floatForKey:LLSTAmplitudeKey]];
    [DAChannelField setIntValue:[defaults integerForKey:LLSTDAChannelKey]];
    [durationField setIntValue:[defaults integerForKey:LLSTDurationKey]];
    [frequencyField setFloatValue:[defaults floatForKey:LLSTFrequencyKey]];
    [gateCheckBox setIntValue:[defaults integerForKey:LLSTGateKey]];
    [gateBitField setIntValue:[defaults integerForKey:LLSTGateBitKey]];
    [markerBitField setIntValue:[defaults integerForKey:LLSTMarkPulseBitKey]];
    [pulsesCheckBox setIntValue:[defaults integerForKey:LLSTMarkerPulsesKey]];
    [pulseWidthField setIntValue:[defaults integerForKey:LLSTPulseWidthKey]];
    [uAPerVField setFloatValue:[defaults floatForKey:LLSTUAPerVKey]];
}

- (void)windowDidLoad {

	[self loadDialogEntries];
}


@end
