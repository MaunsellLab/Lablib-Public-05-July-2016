//
//  LLSynthDataSettings.h
//  Lablib
//
//  Created by John Maunsell on Monday, September 26, 2005.
//  Copyright (c) 2005. All rights reserved.
//

@interface LLSynthDataSettings : NSWindowController {

	NSUserDefaults			*defaults;
	
	IBOutlet NSMatrix		*spikeButtonBits;
}

- (IBAction)changeSpikes:(id)sender;
- (IBAction)ok:(id)sender;

- (void)loadValues;
- (void)runPanel;

@end
