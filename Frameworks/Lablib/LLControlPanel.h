//
//  LLControlPanel.h
//  Lablib
//
//  Created by John Maunsell on 12/27/04.
//  Copyright 2004. All rights reserved.
//

extern NSString *LLTaskModeButtonKey;
extern NSString *LLJuiceButtonKey;
extern NSString *LLResetButtonKey;

@interface LLControlPanel : NSWindowController <NSWindowDelegate> {

	IBOutlet NSTextField	*fileNameDisplay;
	long					originalHeightPix;
	IBOutlet NSButton		*resetButton;
	long					taskMode;
	IBOutlet NSButton		*taskModeButton;
}

- (void)displayFileName:(NSString *)fileName;
- (void)displayText:(NSString *)text;
- (void)setResetButtonEnabled:(long)state;
- (void)setTaskMode:(long)mode;
- (long)taskMode;

- (IBAction)doTaskMode:(id)sender;
- (IBAction)doJuice:(id)sender;
- (IBAction)doReset:(id)sender;

@end
