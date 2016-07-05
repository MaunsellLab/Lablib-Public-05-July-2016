//
//  LLControlPanel.m
//  Lablib
//
//  Created by John Maunsell on 12/27/04.
//  Copyright 2011. All rights reserved.
//

#import "LLControlPanel.h"
#import "LLStandardDataEvents.h"

#define kTextDeltaPix	30

NSString *LLTaskModeButtonKey = @"LLTaskModeButton";
NSString *LLJuiceButtonKey = @"LLJuiceButton";
NSString *LLResetButtonKey = @"LLResetButton";

NSImage *playButton;
NSImage *stopButton;
NSImage *stoppingButton;

@implementation LLControlPanel

- (void)displayFileName:(NSString *)fileName;
{
	if ([fileName length] > 0) {
		[self displayText:[NSString stringWithFormat:@"Saving Data to %@", fileName]];
	}
	else {
		[self displayText:@""];
	}
}

- (void)displayText:(NSString *)text;
{
	NSRect frameRect = [[self window] frame];
	
	if ([text length] == 0 && (NSHeight(frameRect) != originalHeightPix)) {
		frameRect = NSInsetRect(frameRect, 0, kTextDeltaPix);
		frameRect = NSOffsetRect(frameRect, 0, kTextDeltaPix);
		[[self window] setFrame:frameRect display:YES animate:YES];
	}
	else if ([text length] > 0) {
		if (NSHeight(frameRect) == originalHeightPix) {
			frameRect = NSInsetRect(frameRect, 0, -kTextDeltaPix);
			frameRect = NSOffsetRect(frameRect, 0, -kTextDeltaPix);
			[[self window] setFrame:frameRect display:YES animate:YES];
		}
		[fileNameDisplay setStringValue:text];
	}
}


- (IBAction)doTaskMode:(id)sender;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:LLTaskModeButtonKey
		object:self];
}

- (IBAction)doJuice:(id)sender;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:LLJuiceButtonKey
		object:self];
}

- (IBAction)doReset:(id)sender;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:LLResetButtonKey
		object:self];
}

- (id)init;
{
	NSString *imagePath;
	
    if ((self = [super initWithWindowNibName:@"LLControlPanel"]) != nil) {
        [self window];							// Force the window to load now
		originalHeightPix = [[self window] frame].size.height;
		if (playButton == nil) {
			imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"PlayButton" ofType:@"tif"];
			playButton = [[NSImage alloc] initWithContentsOfFile:imagePath];
		}
		if (stopButton == nil) {
			imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"StopButton" ofType:@"tif"];
			stopButton = [[NSImage alloc] initWithContentsOfFile:imagePath];
		}
		if (stoppingButton == nil) {
			imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"StoppingButton" ofType:@"tif"];
			stoppingButton = [[NSImage alloc] initWithContentsOfFile:imagePath];
		}
		[[self window] setDelegate:self];
	}
	return self;
}

- (void)setResetButtonEnabled:(long)state;
{
	[resetButton setEnabled:state];
}

- (void)setTaskMode:(long)newMode;
{
	taskMode = newMode;
	switch (taskMode) {
    case kTaskRunning:
		[taskModeButton setTitle:@"Stop"];
		[taskModeButton setToolTip:@"Stop"];
		[taskModeButton setImage:stopButton];
        break;
    case kTaskStopping:
		[taskModeButton setTitle:@"Stop"];
		[taskModeButton setToolTip:@"Stop Now"];
		[taskModeButton setImage:stoppingButton];
        break;
    case kTaskIdle:
		[taskModeButton setTitle:@"Run"];
		[taskModeButton setToolTip:@"Run"];
		[taskModeButton setImage:playButton];
        break;
    default:
        break;
    }
}

- (long)taskMode;
{
	return taskMode;
}

@end
