//
//  PreferenceController.h
//  Data Inspector
//
//  Created by John Maunsell on Sun Jun 16 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import <AppKit/AppKit.h>

extern NSString *DIDataFormatKey;
extern NSString *DIShowAddressKey;
extern NSString *DIShowTimeKey;
extern NSString *DIShowTimeOfDayKey;
extern NSString *DIShowDataKey;

@interface PreferenceController : NSWindowController {

    IBOutlet NSButton *addressCheckBox;
    IBOutlet NSButton *dataCheckBox;
    IBOutlet NSMatrix *formatMatrix;
    IBOutlet NSButton *timeCheckBox;
    IBOutlet NSButton *timeOfDayCheckBox;
}

- (IBAction)changeFormat:(id)sender;
- (IBAction)changeShowAddress:(id)sender;
- (IBAction)changeShowTime:(id)sender;
- (IBAction)changeShowTimeOfDay:(id)sender;
- (IBAction)changeShowData:(id)sender;

@end
