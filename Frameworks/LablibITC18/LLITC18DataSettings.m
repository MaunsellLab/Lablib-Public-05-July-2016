//
//  LLMouseDataSettings.m
//  Lablib
//
//  Created by John Maunsell on Wed Jun 04 2003.
//  Copyright (c) 2005. All rights reserved.
//
// Because this NSWindowController's window is run as a modal dialog, it will always 
// be presented centered on the screen ([NSWindow center]).  There is no point in using
// frameAutosave functions because their values will be ignored

#import "LLITC18DataSettings.h"

@implementation LLITC18DataSettings

- (id)init {

    if ((self =  [super initWithWindowNibName:@"LLITC18DataSettingsSingle"])) {
		[self window];
	}   
    return self;
}

- (IBAction)ok:(id)sender {

	[NSApp stopModal];
}

- (void)runPanel;
{
	[NSApp runModalForWindow:[self window]];
    [[self window] orderOut:self];
}

@end
