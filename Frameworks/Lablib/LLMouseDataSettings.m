//
//  LLMouseDataSettings.m
//  Lablib
//
//  Created by John Maunsell on Wed Jun 04 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLMouseDataSettings.h"
#import "LLMouseDataDevice.h"
#import "LLDataDeviceController.h"

@implementation LLMouseDataSettings

- (IBAction)changeButtonBits:(id)sender {

	unsigned short bits;
	
	bits = [self getBitPatternFromMatrix:buttonBits];
	[defaults setInteger:bits forKey:LLMouseButtonBitsKey];
	[self setMatrixStates:buttonBits bitPattern:bits];
}

- (IBAction)changeMouseGain:(id)sender;
{
	[defaults setFloat:[sender floatValue] forKey:LLMouseGainKey];
}

- (IBAction)changeMouseXBits:(id)sender {

	short bits;
	
	bits = [self getBitPatternFromMatrix:mouseXBits];
	[defaults setInteger:bits forKey:LLMouseXBitsKey];
	[self setMatrixStates:mouseXBits bitPattern:bits];
	[self enableMatrix:mouseYBits bitPattern:~bits];
}

- (IBAction)changeMouseYBits:(id)sender {

	short bits; 
	
	bits = [self getBitPatternFromMatrix:mouseYBits];
	[defaults setInteger:bits forKey:LLMouseYBitsKey];
	[self setMatrixStates:mouseYBits bitPattern:bits];
	[self enableMatrix:mouseXBits bitPattern:~bits];
}

- (void)enableMatrix:(NSMatrix *)matrix bitPattern:(short)bits {

	long index;
	
	for (index = 0; index < kLLMouseADChannels; index++) {
		[[matrix cellAtRow:index column:0] setEnabled:((bits & (0x1 << index)) > 0)];
	}
}

// Return a short with a bit pattern corresponding the selected buttons in a 16 button matrix.
// Tags in the matrix must correspond to bit numbers

- (short)getBitPatternFromMatrix:(NSMatrix *)matrix {

	short	bitPattern;
	long index; 
	NSArray *selectedCells;
	
	selectedCells = [matrix selectedCells];
	for (index = bitPattern = 0; index < [selectedCells count]; index++) {
		bitPattern |= (0x1 << [[selectedCells objectAtIndex:index] tag]);
	}
	return bitPattern;
}

- (id)init {

    if ((self =  [super initWithWindowNibName:@"LLMouseDataSettings"])) {
        [self setWindowFrameAutosaveName:@"LLMouseDataSettings"];
		[self window];					// Force window to load
		defaults = [NSUserDefaults standardUserDefaults];
	}   
    return self;
}

- (IBAction)ok:(id)sender {

	[NSApp stopModal];
}

- (void)runPanel {

	short buttonBitPattern;
	long index;
		
	buttonBitPattern = [defaults integerForKey:LLMouseButtonBitsKey];
	for (index = 0; index < kLLMouseADChannels; index++) {
		[[buttonBits cellAtRow:index column:0] setState:(buttonBitPattern & (0x1 << index))];
	}
	[self validateChannels];
    [mouseGainField setFloatValue:[defaults integerForKey:LLMouseGainKey]];

	[NSApp runModalForWindow:[self window]];
    [[self window] orderOut:self];
}

- (void)setMatrixStates:(NSMatrix *)matrix bitPattern:(short)bits {

	long index;
	
	for (index = 0; index < kLLMouseADChannels; index++) {
		[[matrix cellAtRow:index column:0] setState:((bits & (0x1 << index)) > 0) ? NSOnState : NSOffState];
	}
}

- (void)validateChannels {

	unsigned short mouseXPattern, mouseYPattern;

// Make sure that at least one channel is selected for X and Y, and that the same channel
// is not selected for both.  If any illegal situation exist, force the patterns to default values.

	mouseXPattern = [defaults integerForKey:LLMouseXBitsKey];
	mouseYPattern = [defaults integerForKey:LLMouseYBitsKey];
	if (mouseXPattern == 0xffff || mouseYPattern == 0xffff || mouseXPattern == 0 ||
						mouseYPattern == 0 || (mouseXPattern & mouseYPattern) != 0) {
		mouseXPattern = 0x0001;
		mouseYPattern = 0x0002;
		[defaults setInteger:mouseXPattern 
				forKey:LLMouseXBitsKey];
		[defaults setInteger:mouseYPattern 
				forKey:LLMouseYBitsKey];
	}
	[self setMatrixStates:mouseXBits bitPattern:mouseXPattern];
	[self enableMatrix:mouseYBits bitPattern:~mouseXPattern];
	[self setMatrixStates:mouseYBits bitPattern:mouseYPattern];
	[self enableMatrix:mouseXBits bitPattern:~mouseYPattern];
}

@end
