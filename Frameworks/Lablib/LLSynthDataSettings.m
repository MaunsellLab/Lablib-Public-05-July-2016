//
//  LLSynthDataSettings.m
//  Lablib
//
//  Created by John Maunsell on Monday, September 26, 2005.
//  Copyright (c) 2005. All rights reserved.
//

#import "LLSynthDataSettings.h"
#import "LLSynthDataDevice.h"

@implementation LLSynthDataSettings

- (IBAction)changeSpikes:(id)sender {

	unsigned short bitPattern;
	long index;
	NSArray *selectedCells;
	
	selectedCells = [spikeButtonBits selectedCells];
	for (index = bitPattern = 0; index < [selectedCells count]; index++) {
		bitPattern |= (0x1 << [[selectedCells objectAtIndex:index] tag]);
	}
	[defaults setInteger:bitPattern forKey:LLSynthSpikesKey];
	for (index = 0; index < kLLSynthDigitalBits; index++) {
		if (!(bitPattern & (0x1 << index))) {
			[[spikeButtonBits cellAtRow:index column:0] setState:NSOffState];
		}
	}
}

- (id)init;
{
    if ((self =  [super initWithWindowNibName:@"LLSynthDataSettings"])) {
        [self setWindowFrameAutosaveName:@"LLSynthDataSettings"];
		[self window];					// Force window to load
		defaults = [NSUserDefaults standardUserDefaults];
	}   
    return self;
}

- (void)loadValues {

	long index;
	unsigned short bits;
	
	bits = [defaults integerForKey:LLSynthSpikesKey];
	for (index = 0; index < kLLSynthDigitalBits; index++) {
		[[spikeButtonBits cellAtRow:index column:0] 
						setState:((bits & (0x1 << index)) > 0) ? NSOnState : NSOffState];
	}
}

- (IBAction)ok:(id)sender {

	[NSApp stopModal];
}

- (void)runPanel;
{
	[self loadValues];
	[NSApp runModalForWindow:[self window]];
    [[self window] orderOut:self];
}

@end
