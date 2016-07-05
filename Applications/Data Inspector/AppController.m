//
//  AppController.m
//  Document Viewer
//
//  Created by John Maunsell on Sun Jun 16 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import "AppController.h"
#import "PreferenceController.h"

@implementation AppController

+ (void)initialize
{
    NSMutableDictionary *defaultValues;
        
    defaultValues = [NSMutableDictionary dictionary];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:DIShowAddressKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:DIShowTimeOfDayKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:DIShowTimeKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:DIShowDataKey];
    [defaultValues setObject:[NSNumber numberWithInt:0] forKey:DIDataFormatKey];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

// Stop the application from opening an empty window

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (IBAction)showPreferencePanel:(id)sender
{
    if (preferenceController == nil) {
        preferenceController = [[PreferenceController alloc] init];
    }
    [preferenceController showWindow:self];
}

- (void)dealloc
{
    [preferenceController release];
    [super dealloc];
}
@end
