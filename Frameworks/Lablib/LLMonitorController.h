//
//  LLMonitorController.h
//  Lablib
//
//  Created by John Maunsell on Sat Jun 14 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLMonitor.h"

@interface LLMonitorController : NSWindowController {

@protected
	BOOL					frozen;
	NSMutableArray			*monitors;
	
    IBOutlet NSButton	 	*configureButton;
    IBOutlet NSButton	 	*freezeButton;
	IBOutlet NSPopUpButton	*monitorMenu;
    IBOutlet NSButton	 	*refreshButton;
    IBOutlet NSTextField	*headerField;
    IBOutlet NSTextView		*text;
}

- (void)addMonitor:(id <LLMonitor>)monitor;
- (IBAction)changeMonitor:(id)sender;
- (IBAction)configureMonitor:(id)sender;
- (IBAction)freeze:(id)sender;
- (IBAction)refresh:(id)sender;
- (void)removeMonitorWithID:(NSString *)IDString;

@end
