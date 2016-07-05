//
//  LLMouseDataSettings.h
//  Lablib
//
//  Created by John Maunsell on Wed Jun 04 2003.
//  Copyright (c) 2005. All rights reserved.
//

@interface LLMouseDataSettings : NSWindowController {

	NSUserDefaults			*defaults;
	
	IBOutlet NSMatrix		*buttonBits;
    IBOutlet NSTextField	*mouseGainField;
	IBOutlet NSMatrix		*mouseXBits;
	IBOutlet NSMatrix		*mouseYBits;
}

- (IBAction)changeButtonBits:(id)sender;
- (IBAction)changeMouseGain:(id)sender;
- (IBAction)changeMouseXBits:(id)sender;
- (IBAction)changeMouseYBits:(id)sender;
- (IBAction)ok:(id)sender;

- (void)enableMatrix:(NSMatrix *)matrix bitPattern:(short)bits;
- (short)getBitPatternFromMatrix:(NSMatrix *)matrix;
- (void)runPanel;
- (void)setMatrixStates:(NSMatrix *)matrix bitPattern:(short)bits;
- (void)validateChannels;

@end
