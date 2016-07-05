//
//  LLIODeviceSettings.h
//  Lablib
//
//  Created by John Maunsell on Wed Jun 04 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLIODeviceController.h"

@interface LLIODeviceSettings : NSWindowController {

@protected
	LLIODeviceController	*sourceController;
	IBOutlet NSButton		*configureButton;
	IBOutlet NSPopUpButton	*sourceMenu;
}

- (IBAction)configure:(id)sender;
- (id)initWithController:(LLIODeviceController *)sourceController;
- (void)insertMenuItem:(NSString *)title atIndex:(long)index;
- (IBAction)ok:(id)sender;
- (long)selectSource:(long)currentSourceIndex;
- (IBAction)updateConfigureButton:(id)sender;

@end
