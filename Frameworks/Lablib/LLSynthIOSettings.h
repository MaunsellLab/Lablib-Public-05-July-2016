//
//  LLIODeviceSettings.h
//  Lablib
//
//  Created by John Maunsell on Wed Jun 04 2003.
//  Copyright (c) 2003. All rights reserved.
//

@interface LLSynthIOSettings : NSWindowController {

@protected

	NSUserDefaults			*defaults;
	
	IBOutlet NSTextField	*eyeBreakField;
	IBOutlet NSTextField	*eyeIgnoreField;
	IBOutlet NSTextField	*eyeIntervalField;
	IBOutlet NSTextField	*eyeNoiseField;
	IBOutlet NSPopUpButton	*eyeXButton;
	IBOutlet NSPopUpButton	*eyeYButton;
	IBOutlet NSTextField	*m11Field;
	IBOutlet NSTextField	*m12Field;
	IBOutlet NSTextField	*m21Field;
	IBOutlet NSTextField	*m22Field;
	IBOutlet NSTextField	*tXField;
	IBOutlet NSTextField	*tYField;
	
	IBOutlet NSTextField	*leverIgnoreField;
	IBOutlet NSTextField	*leverLatencyField;
	IBOutlet NSPopUpButton	*leverBitButton;
	IBOutlet NSTextField	*leverSpontDownField;
	IBOutlet NSTextField	*leverSpontUpField;

	IBOutlet NSMatrix		*spikeButtonBits;
	IBOutlet NSMatrix		*spikesRandom;
	
    IBOutlet NSPopUpButton	*VBLButton;
    IBOutlet NSTextField	*VBLPeriodField;
}

- (IBAction)changeDefaults:(id)sender;
- (IBAction)changeEyeBreak:(id)sender;
- (IBAction)changeEyeIgnore:(id)sender;
- (IBAction)changeEyeInterval:(id)sender;
- (IBAction)changeEyeNoise:(id)sender;
- (IBAction)changeEyeX:(id)sender;
- (IBAction)changeEyeY:(id)sender;
- (IBAction)changeLeverBit:(id)sender;
- (IBAction)changeLeverDown:(id)sender;
- (IBAction)changeLeverIgnore:(id)sender;
- (IBAction)changeLeverLatency:(id)sender;
- (IBAction)changeLeverUp:(id)sender;
- (IBAction)changeM11:(id)sender;
- (IBAction)changeM12:(id)sender;
- (IBAction)changeM21:(id)sender;
- (IBAction)changeM22:(id)sender;
- (IBAction)changeSpikes:(id)sender;
- (IBAction)changeSpikesRandom:(id)sender;
- (IBAction)changeTX:(id)sender;
- (IBAction)changeTY:(id)sender;
- (IBAction)changeVBL:(id)sender;
- (IBAction)changeVBLPeriod:(id)sender;
- (IBAction)ok:(id)sender;

- (void)loadValues;
- (void)runPanel;

@end
