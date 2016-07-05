//
//  LLPulseTraim.m
//  
//  This object supports the generation of microstimulation trains using the ITC-18.  
//  This is an extension of LLStimTrain, which was made to allow for optical stimulation
//
//  Created by John Maunsell on August 28, 2008
//  Copyright (c) 2008. All rights reserved.
//

#import "LLPulseTrain.h"

NSString *LLPTPulseTypeKey = @"LLPTPulseType";
NSString *LLPTAmplitudeKey = @"LLPTAmplitude";
NSString *LLPTDurationMSKey = @"LLPTDurationMS";
NSString *LLPTFrequencyHzKey = @"LLPTFrequencyHz";
NSString *LLPTPulseBiphasicKey = @"LLPTPulseBiphasic";
NSString *LLPTPulseWidthUSKey = @"LLPTPulseWidthUS";
NSString *LLPTVoltageRangeKey = @"LLPTVoltageRange";
NSString *LLPTDAChannelKey = @"LLPTDAChannel";
NSString *LLPTMarkPulseBitKey = @"LLPTMarkPulseBit";
NSString *LLPTMarkerPulsesKey = @"LLPTMarkerPulses";
NSString *LLPTGateKey = @"LLPTGate";
NSString *LLPTGateBitKey = @"LLPTGateBit";
NSString *LLPTUAPerVKey = @"LLPTUAPerV";

@implementation LLPulseTrain 

- (id)init
{
	NSString *defaultsPath;
    NSDictionary *defaultsDict;
	
	if ((self = [super initWithWindowNibName:@"LLPulseTrain"])) {
		defaultsPath = [[NSBundle bundleForClass:[LLPulseTrain class]] 
						pathForResource:@"LLPulseTrain" ofType:@"plist"];
		defaultsDict = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
    }
    return self;
}

- (PulseTrainData *)trainData {

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	pulseTrain.amplitude = [defaults floatForKey:LLPTAmplitudeKey];
	pulseTrain.DAChannel = [defaults integerForKey:LLPTDAChannelKey];
	pulseTrain.doPulseMarkers = [defaults integerForKey:LLPTMarkerPulsesKey];
	pulseTrain.doGate = [defaults integerForKey:LLPTGateKey];
	pulseTrain.durationMS = [defaults integerForKey:LLPTDurationMSKey];
	pulseTrain.frequencyHZ = [defaults floatForKey:LLPTFrequencyHzKey]; 
	pulseTrain.gateBit = [defaults integerForKey:LLPTGateBitKey];
	pulseTrain.pulseMarkerBit = [defaults integerForKey:LLPTMarkPulseBitKey];
	pulseTrain.pulseBiphasic = [defaults integerForKey:LLPTPulseBiphasicKey];
	pulseTrain.pulseType = [defaults integerForKey:LLPTPulseTypeKey];
	pulseTrain.pulseWidthUS = [defaults integerForKey:LLPTPulseWidthUSKey]; 
	pulseTrain.fullRangeV = [defaults floatForKey:LLPTVoltageRangeKey]; 
	pulseTrain.UAPerV = [defaults floatForKey:LLPTUAPerVKey];
	
	return &pulseTrain;
}

@end
