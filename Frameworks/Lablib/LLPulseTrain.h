//
//  LLPulseTrain.h
//  Lablib
//
//  Created by John Maunsell on Thu Jun 03 2004.
//  Copyright (c) 2008. All rights reserved.
//

#import "LLPulseTrainDevice.h"

extern NSString *LLPTPulseTypeKey;
extern NSString *LLPTAmplitudeKey;
extern NSString *LLPTDurationMSKey;
extern NSString *LLPTFrequencyHzKey;
extern NSString *LLPTPulseBiphasicKey;
extern NSString *LLPTPulseTypeKey;
extern NSString *LLPTPulseWidthUSKey;
extern NSString *LLPTVoltageRangeKey;
extern NSString *LLPTDAChannelKey;
extern NSString *LLPTMarkPulseBitKey;
extern NSString *LLPTMarkerPulsesKey;
extern NSString *LLPTUAPerVKey;

@interface LLPulseTrain : NSWindowController {

	PulseTrainData	pulseTrain;

}

- (PulseTrainData *)trainData;

@end
