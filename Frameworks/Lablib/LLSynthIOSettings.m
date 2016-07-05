//
//  LLSynthSourceSettings.m
//  Lablib
//
//  Created by John Maunsell on Wed Jun 04 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLSynthIOSettings.h"
#import "LLSynthIODevice.h"

@implementation LLSynthIOSettings

- (IBAction)changeDefaults:(id)sender {

	[defaults setFloat:kLLSynthEyeBreakDefault forKey:LLSynthEyeBreakKey];
	[defaults setFloat:kLLSynthEyeIgnoreDefault forKey:LLSynthEyeIgnoreKey];
	[defaults setFloat:kLLSynthEyeIntervalDefault forKey:LLSynthEyeIntervalKey];
	[defaults setFloat:kLLSynthEyeNoiseDefault forKey:LLSynthEyeNoiseKey];
	[defaults setInteger:kLLSynthEyeXDefault forKey:LLSynthEyeXKey];
	[defaults setInteger:kLLSynthEyeYDefault forKey:LLSynthEyeYKey];
	[defaults setFloat:kLLDefaultM11 forKey:LLSynthLM11Key];
	[defaults setFloat:kLLDefaultM12 forKey:LLSynthLM12Key];
	[defaults setFloat:kLLDefaultM21 forKey:LLSynthLM21Key];
	[defaults setFloat:kLLDefaultM22 forKey:LLSynthLM22Key];
	[defaults setFloat:kLLDefaultTX forKey:LLSynthLTXKey];
	[defaults setFloat:kLLDefaultTY forKey:LLSynthLTYKey];
	[defaults setFloat:kLLDefaultM11 forKey:LLSynthRM11Key];
	[defaults setFloat:kLLDefaultM12 forKey:LLSynthRM12Key];
	[defaults setFloat:kLLDefaultM21 forKey:LLSynthRM21Key];
	[defaults setFloat:kLLDefaultM22 forKey:LLSynthRM22Key];
	[defaults setFloat:kLLDefaultTX forKey:LLSynthRTXKey];
	[defaults setFloat:kLLDefaultTY forKey:LLSynthRTYKey];

	[defaults setInteger:kLLSynthLeverBitDefault forKey:LLSynthLeverBitKey];
	[defaults setFloat:kLLSynthLeverDownDefault forKey:LLSynthLeverDownKey];
	[defaults setFloat:kLLSynthLeverIgnoreDefault forKey:LLSynthLeverIgnoreKey];
	[defaults setInteger:kLLSynthLeverLatencyDefault forKey:LLSynthLeverLatencyKey];
	[defaults setFloat:kLLSynthLeverUpDefault forKey:LLSynthLeverUpKey];

	[defaults setInteger:kLLSynthSpikesDefault forKey:LLSynthSpikesKey];
	[defaults setInteger:kLLSynthSpikesRandomDefault forKey:LLSynthSpikesRandomKey];

	[defaults setBool:kLLSynthVBLDefault forKey:LLSynthVBLKey];
	[defaults setFloat:kLLSynthVBLPeriodDefault forKey:LLSynthVBLRateKey];
	[self loadValues];
}

- (IBAction)changeEyeBreak:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthEyeBreakKey];
}

- (IBAction)changeEyeIgnore:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthEyeIgnoreKey];
}

- (IBAction)changeEyeInterval:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthEyeIntervalKey];
}

- (IBAction)changeEyeNoise:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthEyeNoiseKey];
}

- (IBAction)changeEyeX:(id)sender {

	[defaults setInteger:[[sender selectedItem] tag] forKey:LLSynthEyeXKey];
}

- (IBAction)changeEyeY:(id)sender {

	[defaults setInteger:[[sender selectedItem] tag] forKey:LLSynthEyeYKey];
}

- (IBAction)changeLeverBit:(id)sender {

	[defaults setInteger:[[sender selectedItem] tag] forKey:LLSynthLeverBitKey];
}

- (IBAction)changeLeverDown:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthLeverDownKey];
}

- (IBAction)changeLeverIgnore:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthLeverIgnoreKey];
}

- (IBAction)changeLeverLatency:(id)sender {

	[defaults setInteger:[sender intValue] forKey:LLSynthLeverLatencyKey];
}

- (IBAction)changeLeverUp:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthLeverUpKey];
}

- (IBAction)changeM11:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthM11Key];
}

- (IBAction)changeM12:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthM12Key];
}

- (IBAction)changeM21:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthM21Key];
}

- (IBAction)changeM22:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthM22Key];
}

- (IBAction)changeSpikes:(id)sender {

	unsigned short bitPattern;
	long index;
	NSArray *selectedCells;
	
	selectedCells = [spikeButtonBits selectedCells];
	for (index = bitPattern = 0; index < [selectedCells count]; index++) {
		bitPattern |= (0x1 << [[selectedCells objectAtIndex:index] tag]);
	}
	[defaults setInteger:bitPattern forKey:LLSynthSpikesKey];
	for (index = 0; index < kDigitalBits; index++) {
		if (!(bitPattern & (0x1 << index))) {
			[[spikeButtonBits cellAtRow:index column:0] setState:NSOffState];
		}
	}
}

- (IBAction)changeSpikesRandom:(id)sender {

	[defaults setInteger:[sender selectedRow] forKey:LLSynthSpikesRandomKey];
}

- (IBAction)changeVBL:(id)sender {

	[defaults setBool:[[sender selectedItem] tag] forKey:LLSynthVBLKey];
}

- (IBAction)changeTX:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthTXKey];
}

- (IBAction)changeTY:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthTYKey];
}

- (IBAction)changeVBLPeriod:(id)sender {

	[defaults setFloat:[sender floatValue] forKey:LLSynthVBLRateKey];
}

- (id)init {

    if ((self =  [super initWithWindowNibName:@"LLSynthIOSettings"])) {
        [self setWindowFrameAutosaveName:@"LLSynthIOSettings"];
		[self window];					// Force window to load
		defaults = [NSUserDefaults standardUserDefaults];
	}   
    return self;
}

- (void)loadValues {

	long index;
	unsigned short bits;
	
	[eyeBreakField setFloatValue:[defaults floatForKey:LLSynthEyeBreakKey]];
	[eyeIgnoreField setFloatValue:[defaults floatForKey:LLSynthEyeIgnoreKey]];
	[eyeIntervalField setFloatValue:[defaults floatForKey:LLSynthEyeIntervalKey]];
	[eyeNoiseField setFloatValue:[defaults floatForKey:LLSynthEyeNoiseKey]];
	[eyeXButton selectItemAtIndex:[eyeXButton 
		indexOfItemWithTag:[defaults integerForKey:LLSynthEyeXKey]]];
	[eyeYButton selectItemAtIndex:[eyeYButton 
		indexOfItemWithTag:[defaults integerForKey:LLSynthEyeYKey]]];
	[m11Field setFloatValue:[defaults floatForKey:LLSynthM11Key]];
	[m12Field setFloatValue:[defaults floatForKey:LLSynthM12Key]];
	[m21Field setFloatValue:[defaults floatForKey:LLSynthM21Key]];
	[m22Field setFloatValue:[defaults floatForKey:LLSynthM22Key]];
	[tXField setFloatValue:[defaults floatForKey:LLSynthTXKey]];
	[tYField setFloatValue:[defaults floatForKey:LLSynthTYKey]];

	[leverBitButton selectItemAtIndex:[leverBitButton 
		indexOfItemWithTag:[defaults integerForKey:LLSynthLeverBitKey]]];
	[leverSpontDownField setFloatValue:[defaults floatForKey:LLSynthLeverDownKey]];
	[leverIgnoreField setFloatValue:[defaults floatForKey:LLSynthLeverIgnoreKey]];
	[leverLatencyField setIntValue:[defaults integerForKey:LLSynthLeverLatencyKey]];
	[leverSpontUpField setFloatValue:[defaults floatForKey:LLSynthLeverUpKey]];

	[spikesRandom setState:1 atRow:[defaults floatForKey:LLSynthSpikesRandomKey] column:0];
	bits = [defaults integerForKey:LLSynthSpikesKey];
	for (index = 0; index < kDigitalBits; index++) {
		[[spikeButtonBits cellAtRow:index column:0] 
						setState:((bits & (0x1 << index)) > 0) ? NSOnState : NSOffState];
	}

	[VBLButton selectItemAtIndex:[VBLButton 
		indexOfItemWithTag:[defaults integerForKey:LLSynthVBLKey]]];
	[VBLPeriodField setIntValue:[defaults integerForKey:LLSynthVBLRateKey]];
}

- (IBAction)ok:(id)sender {

	[NSApp stopModal];
}

- (void)runPanel {

	[self loadValues];
	[NSApp runModalForWindow:[self window]];
    [[self window] orderOut:self];
}

@end
