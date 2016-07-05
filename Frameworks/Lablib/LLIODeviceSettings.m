//
//  LLIODeviceSettings.m
//  Lablib
//
//  Created by John Maunsell on Wed Jun 04 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLIODeviceSettings.h"
#import "LLMouseIODevice.h"
#import "LLSynthIODevice.h"

@implementation LLIODeviceSettings

- (IBAction)configure:(id)sender { 

    [[self window] orderOut:self];

	[sourceController configureSourceWithIndex:[sourceMenu indexOfSelectedItem]];

    [self showWindow:[self window]];
	[[self window] invalidateShadow];
	[[self window] display];
}

- (id)initWithController:(LLIODeviceController *)controller {

    if ((self =  [super initWithWindowNibName:@"LLIODeviceSettings"])) {
        [self setWindowFrameAutosaveName:@"LLIODeviceSettings"];
		[self window];					// Force window to load
		[sourceMenu removeAllItems];
		sourceController = controller;
	}   
    return self;
}

- (void)insertMenuItem:(NSString *)title atIndex:(long)index {

	[sourceMenu insertItemWithTitle:title atIndex:index];
}

- (IBAction)ok:(id)sender {

	[NSApp stopModal];
}

- (long)selectSource:(long)currentSourceIndex {
	
	[sourceMenu selectItemAtIndex:currentSourceIndex];	
	[self updateConfigureButton:self];
	[NSApp runModalForWindow:[self window]];
	
    [[self window] orderOut:self];
	return [sourceMenu indexOfSelectedItem];
}

- (IBAction)updateConfigureButton:(id)sender {

	if ([sourceController canConfigureSourceWithIndex:[sourceMenu indexOfSelectedItem]]) {
		[configureButton setEnabled:YES];
	}
	else {
		[configureButton setEnabled:NO];
	}
}

@end
