//
//  PreferenceController.m
//  Data Inspector
//
//  Created by John Maunsell on Sun Jun 16 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import "PreferenceController.h"

NSString *DIDataFormatKey = @"Data Format";
NSString *DIShowAddressKey = @"Event Address";
NSString *DIShowTimeKey = @"Event Time";
NSString *DIShowTimeOfDayKey = @"Event Time Of Day";
NSString *DIShowDataKey = @"Event Data";

@implementation PreferenceController

- (id)init 
{
    if ((self =  [super initWithWindowNibName:@"Preferences"])) {
        [self setWindowFrameAutosaveName:@"PrefWindow"];
    }    
    return self;
}

- (void)windowDidLoad 
{
    NSUserDefaults *defaults;
    
    defaults = [NSUserDefaults standardUserDefaults];
    [addressCheckBox setState:[defaults boolForKey:DIShowAddressKey]];
    [timeCheckBox setState:[defaults boolForKey:DIShowTimeKey]];
    [dataCheckBox setState:[defaults boolForKey:DIShowDataKey]];
    [formatMatrix setState:YES atRow:[defaults integerForKey:DIDataFormatKey] column:0];
}

- (IBAction)changeFormat:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:[sender selectedRow] forKey:DIDataFormatKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Display Format Changed" object:nil];
}

- (IBAction)changeShowAddress:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:DIShowAddressKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Display Format Changed" object:nil];
}

- (IBAction)changeShowTime:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:DIShowTimeKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Display Format Changed" object:nil];
}

- (IBAction)changeShowTimeOfDay:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:DIShowTimeOfDayKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Display Format Changed" object:nil];
}

- (IBAction)changeShowData:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:[sender state] forKey:DIShowDataKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Display Format Changed" object:nil];
}

@end
