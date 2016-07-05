//
//  LLDisplayPhysical.m
//  Lablib
//
//  Created by John Maunsell on Tue Jul 15 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLDisplayPhysical.h"
#import "LLDisplayUtilities.h"
#import "LLDisplays.h"

#define kMMPerInch		25.40

NSString *LLDistanceMMKey = @"LL Distance MM";
NSString *LLRedCIExKey = @"LL RedCIEx";
NSString *LLRedCIEyKey = @"LL RedCIEy";
NSString *LLGreenCIExKey = @"LL GreenCIEx";
NSString *LLGreenCIEyKey = @"LL GreenCIEy";
NSString *LLBlueCIExKey = @"LL BlueCIEx";
NSString *LLBlueCIEyKey = @"LL BlueCIEy";
NSString *LLHeightMMKey = @"LL Height MM";
NSString *LLWidthMMKey = @"LL Width MM";
		
@implementation LLDisplayPhysical

- (IBAction)changeDistance:(id)sender {

	currentParam.distanceMM = [distanceField floatValue] * kMMPerInch;
}

- (IBAction)changeHeightInch:(id)sender {

	currentParam.heightMM = [heightInchField floatValue] * kMMPerInch;
//	currentParam.vPixPerMM = currentParam.heightPix / currentParam.heightMM;	
}

- (IBAction)changeWidthInch:(id)sender {

	currentParam.widthMM = [widthInchField floatValue] * kMMPerInch;
//	currentParam.hPixPerMM = currentParam.widthPix / currentParam.widthMM;
}

- (IBAction)changeRedX:(id)sender {
	currentParam.CIEx.red = [redXField floatValue];
	[self showColors];
}

- (IBAction)changeRedY:(id)sender {
	currentParam.CIEy.red = [redYField floatValue];
	[self showColors];
}

- (IBAction)changeGreenX:(id)sender {
	currentParam.CIEx.green = [greenXField floatValue];
	[self showColors];
}

- (IBAction)changeGreenY:(id)sender {
	currentParam.CIEy.green = [greenYField floatValue];
	[self showColors];
}

- (IBAction)changeBlueX:(id)sender {
	currentParam.CIEx.blue = [blueXField floatValue];
	[self showColors];
}

- (IBAction)changeBlueY:(id)sender {
	currentParam.CIEy.blue = [blueYField floatValue];
	[self showColors];
}

// Return settings for the physical state of a display

- (DisplayPhysicalParam *)displayParameters:(long)displayIndex;
{
	NSString *displayDescription;
    NSAlert *theAlert;

// readParameters will do all the work if there are defaults to be found.  If there are
// no defaults established, then we need to 1) write default values to the disk, and 2)
// run the settings dialog so that the user is aware that there were no defaults and has
// a chance to modify them.

	if (![self readParameters:displayIndex] && !initialized[displayIndex]) {
		displayDescription = (displayIndex == 0) ? @"Main Display" :
				[NSString stringWithFormat:@"Display %ld", displayIndex];
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDisplayPhysical"];
        [theAlert setInformativeText:[NSString stringWithFormat:
                @"No display calibration information found for \"%@\" (%@).  \
                You may provide calibration information in the dialog that will appear next.",
                [LLDisplays displayNameUsingIndex:displayIndex], displayDescription]];
        [theAlert runModal];
//		NSRunAlertPanel(@"LLDisplayPhysical", @"No display calibration information found for \"%@\" (%@).  \
//You may provide calibration information in the dialog that will appear next.", @"OK", nil, nil, 
//				[LLDisplays displayNameUsingIndex:displayIndex], displayDescription);
        [theAlert release];

		displayParam[displayIndex].distanceMM = 500;
		displayParam[displayIndex].heightMM = 300;
		displayParam[displayIndex].widthMM = 400;
		displayParam[displayIndex].CIEx.red = 0.617;
		displayParam[displayIndex].CIEx.green = 0.299;
		displayParam[displayIndex].CIEx.blue = 0.151;
		displayParam[displayIndex].CIEy.red = 0.340;
		displayParam[displayIndex].CIEy.green = 0.601;
		displayParam[displayIndex].CIEy.blue = 0.082;
		initialized[displayIndex] = YES;
		[self doSettingsPanel:displayIndex];				// run settings dialog
	}
	initialized[displayIndex] = YES;
	return &displayParam[displayIndex];
}

- (void)doSettingsPanel:(long)displayIndex {

    NSAlert *theAlert;
	NSString *domainName = [NSString stringWithFormat:@"%@%ld", kLLScreenDomainName, displayIndex];

	currentParam = displayParam[displayIndex];
	if (!initialized[displayIndex]) {
		[self displayParameters:displayIndex];
	}
	if (!permissionChecked) {
		[self writeDomain:domainName key:LLDistanceMMKey doublePtr:&currentParam.distanceMM];
		if (!CFPreferencesAppSynchronize((CFStringRef)domainName)) {
            theAlert = [[NSAlert alloc] init];
            [theAlert setMessageText:@"LLDisplayPhysical"];
            [theAlert setInformativeText:@"You do not have permission to write calibration \
                        values on this machine.  Your values will last only while this program runs."];
            [theAlert runModal];
            [theAlert release];
           
//			NSRunAlertPanel(@"LLDisplayPhysical", @"You do not have permission to write calibration \
//values on this machine.  Your values will last only while this program runs.", @"OK", nil, nil);
		}
		permissionChecked = YES;
	}
	[distanceField setFloatValue:currentParam.distanceMM / kMMPerInch];
	[redXField setFloatValue:currentParam.CIEx.red];
	[redYField setFloatValue:currentParam.CIEy.red];
	[greenXField setFloatValue:currentParam.CIEx.green];
	[greenYField setFloatValue:currentParam.CIEy.green];
	[blueXField setFloatValue:currentParam.CIEx.blue];
	[blueYField setFloatValue:currentParam.CIEy.blue];
	[heightInchField setFloatValue:currentParam.heightMM / kMMPerInch];
	[widthInchField setFloatValue:currentParam.widthMM / kMMPerInch];
	[self showColors];
	
	[[self window] setTitle:[LLDisplays displayNameUsingIndex:displayIndex]];
	[NSApp runModalForWindow:[self window]];
    [[self window] orderOut:self];

	displayParam[displayIndex] = currentParam;
	
	[self writeParameters:displayIndex];		// Try to write the new values
}

- (id)init {

    if ((self = [super initWithWindowNibName:@"LLDisplaySettings"])) {
        [self setWindowFrameAutosaveName:@"LLDisplaySettings"];
		[self window];					// Force window to load
	}   
    return self;
}

- (IBAction)ok:(id)sender {
        
	[NSApp stopModal];
}

- (RGBDouble)maxColor:(RGBDouble)inColor {

	RGBDouble tempColor, luminanceWeight;
	double max, gamma;
	 
// The following are typical luminance ratio and gamma values for flat-screen displays.
// The will very from monitor to monitor but are only used to roughly display the cardinal colors
//in the Display Settings Panel

	luminanceWeight.red = 5.9;
	luminanceWeight.green = 6.9;
	luminanceWeight.blue = 1.0;
	gamma = 1.8;							// typical gamma

	tempColor = inColor;
	tempColor.red /= luminanceWeight.red;
	tempColor.green /= luminanceWeight.green;
	tempColor.blue /= luminanceWeight.blue;
	max = MAX(tempColor.red, MAX(tempColor.green, tempColor.blue));
	tempColor.red = pow(tempColor.red / max, 1.0 / gamma);
	tempColor.green = pow(tempColor.green / max, 1.0 / gamma);
	tempColor.blue = pow(tempColor.blue / max, 1.0 / gamma);
	return tempColor;
}

- (BOOL)readDomain:(NSString *)domainName key:(NSString *)keyName doublePtr:(double *)pValue {
	
	CFNumberRef sysDictRef = CFPreferencesCopyValue((CFStringRef)keyName, (CFStringRef)domainName, 
									kCFPreferencesCurrentUser, kCFPreferencesCurrentApplication);
	if (sysDictRef == nil) {
		return NO;
	}
	CFNumberGetValue(sysDictRef, kCFNumberDoubleType, pValue);
	CFRelease(sysDictRef);
	return YES;
}

/*
 
 Read the physical parameters from a system wide property list. In earlier versions we used to save these values in
 /Library/Preferences by specifying kCFPreferenceAnyUser.  At some point Apple stopped allowing preferences that serve
 all users.  The functionality went away, but the description in the documentation did not.  They simply added a 
 statement that preferences were either for the current app or all (of the current user's) apps.  This meant that our
 values simply stopped working.  In the current version, the screen parameters are saved in each user's preferences. 
 We could set them for all applicaitions on the current host, but that just makes them harder to find (they are in
 ~/Library/Preferences/ByHost).
*/

- (BOOL)readParameters:(long)index {

	NSString *domainName;
	DisplayPhysicalParam *pDP = &displayParam[index];
		
	domainName = [NSString stringWithFormat:@"%@%ld", kLLScreenDomainName, index];
	
	if (![self readDomain:domainName key:LLDistanceMMKey doublePtr:&pDP->distanceMM]) {
		return NO;
	}
	[self readDomain:domainName key:LLHeightMMKey doublePtr:&pDP->heightMM];
	[self readDomain:domainName key:LLWidthMMKey doublePtr:&pDP->widthMM];
	[self readDomain:domainName key:LLRedCIExKey doublePtr:&pDP->CIEx.red];
	[self readDomain:domainName key:LLRedCIEyKey doublePtr:&pDP->CIEy.red];
	[self readDomain:domainName key:LLGreenCIExKey doublePtr:&pDP->CIEx.green];
	[self readDomain:domainName key:LLGreenCIEyKey doublePtr:&pDP->CIEy.green];
	[self readDomain:domainName key:LLBlueCIExKey doublePtr:&pDP->CIEx.blue];
	[self readDomain:domainName key:LLBlueCIEyKey doublePtr:&pDP->CIEy.blue];
	return YES;
}

- (void)showColors;
{
	ColorPatches	colorWells;
	
	colorWells = computeKdlColors(currentParam.CIEx, currentParam.CIEy);
	colorWells.cardinalGreen = [self maxColor:colorWells.cardinalGreen];
	colorWells.cardinalYellow = [self maxColor:colorWells.cardinalYellow];
	colorWells.equalEnergy = [self maxColor:colorWells.equalEnergy];
	[cardinalGreenPatch setColor:[NSColor colorWithCalibratedRed:colorWells.cardinalGreen.red 
		green:colorWells.cardinalGreen.green blue:colorWells.cardinalGreen.blue alpha:1.0]];
	[cardinalYellowPatch setColor:[NSColor colorWithCalibratedRed:colorWells.cardinalYellow.red 
		green:colorWells.cardinalYellow.green blue:colorWells.cardinalYellow.blue alpha:1.0]];
	[equalEnergyPatch setColor:[NSColor colorWithCalibratedRed:colorWells.equalEnergy.red 
		green:colorWells.equalEnergy.green blue:colorWells.equalEnergy.blue alpha:1.0]];
}

- (void)writeDomain:(NSString *)domainName key:(NSString *)keyName doublePtr:(double *)pValue;
{
	CFPreferencesSetValue((CFStringRef)keyName, CFNumberCreate(NULL, kCFNumberDoubleType, pValue),
		(CFStringRef)domainName, kCFPreferencesCurrentUser, kCFPreferencesCurrentApplication);
}

- (void)writeParameters:(long)index {

	DisplayPhysicalParam *pDP = &displayParam[index];
	NSString *domainName = [NSString stringWithFormat:@"%@%ld", kLLScreenDomainName, index];

	[self writeDomain:domainName key:LLDistanceMMKey doublePtr:&pDP->distanceMM];
	[self writeDomain:domainName key:LLHeightMMKey doublePtr:&pDP->heightMM];
	[self writeDomain:domainName key:LLWidthMMKey doublePtr:&pDP->widthMM];
	[self writeDomain:domainName key:LLRedCIExKey doublePtr:&pDP->CIEx.red];
	[self writeDomain:domainName key:LLRedCIEyKey doublePtr:&pDP->CIEy.red];
	[self writeDomain:domainName key:LLGreenCIExKey doublePtr:&pDP->CIEx.green];
	[self writeDomain:domainName key:LLGreenCIEyKey doublePtr:&pDP->CIEy.green];
	[self writeDomain:domainName key:LLBlueCIExKey doublePtr:&pDP->CIEx.blue];
	[self writeDomain:domainName key:LLBlueCIEyKey doublePtr:&pDP->CIEy.blue];
	CFPreferencesAppSynchronize((CFStringRef)domainName);
}

@end
        


