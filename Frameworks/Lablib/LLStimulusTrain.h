//
//  LLStimulusTrain.h
//  Experiment
//
//  Created by John Maunsell on Thu Jun 03 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "LLStimTrainDevice.h"

extern NSString *LLSTAmplitudeKey;
extern NSString *LLSTDuractionKey;
extern NSString *LLSTFrequencyKey;
extern NSString *LLSTPulseWidthKey;
extern NSString *LLSTVoltageRangeKey;
extern NSString *LLSTDAChannelKey;
extern NSString *LLSTMarkPulseBitKey;
extern NSString *LLSTMarkerPulsesKey;
extern NSString *LLSTUAPerVKey;

@interface LLStimulusTrain : NSWindowController {

	StimTrainData			stimTrain;

    IBOutlet NSTextField	*amplitudeField;
    IBOutlet NSTextField	*DAChannelField;
    IBOutlet NSTextField	*durationField;
    IBOutlet NSTextField	*frequencyField;
    IBOutlet NSTextField	*gateBitField;
    IBOutlet NSButton		*gateCheckBox;
    IBOutlet NSTextField	*markerBitField;
    IBOutlet NSButton		*pulsesCheckBox;
    IBOutlet NSTextField	*pulseWidthField;
    IBOutlet NSTextField	*uAPerVField;
}

- (IBAction)changeAmplitude:(id)sender;
- (IBAction)changeDAChannel:(id)sender;
- (IBAction)changeDoGate:(id)sender;
- (IBAction)changeDoMarkers:(id)sender;
- (IBAction)changeDuration:(id)sender;
- (IBAction)changeFrequency:(id)sender;
- (IBAction)changeGateBit:(id)sender;
- (IBAction)changeMarkerBit:(id)sender;
- (IBAction)changePulseWidth:(id)sender;
- (IBAction)changeUAPerV:(id)sender;

- (StimTrainData *)trainData;

@end
