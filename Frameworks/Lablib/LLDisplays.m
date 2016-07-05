//
//  LLDisplays.m
//  Experiment
//
//  Created by John Maunsell on Thu Feb 13 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLDisplays.h"
#import "LLDisplayPhysical.h" 
#import <IOKit/graphics/IOGraphicsLib.h>

NSString *LLPixelBitsKey = @"LL Pixel Bits";
NSString *LLWidthPixKey = @"LL Width Pix";
NSString *LLHeightPixKey = @"LL Height Pix";
NSString *LLFrameRateKey = @"LL Frame Rate Hz";

//void readEDID(CGDirectDisplayID displayID);

@implementation LLDisplays

+ (NSString *)displayNameUsingID:(CGDirectDisplayID)displayID;
{
//	NSDictionary *displayDictionary, *productNamesDictionary;
//	io_service_t service;
//	NSString *displayName = nil;
//
//	service = CGDisplayIOServicePort(displayID);
//	displayDictionary = (NSDictionary *)IODisplayCreateInfoDictionary(service, kIODisplayOnlyPreferredName);
//	if (displayDictionary != nil) {
//		productNamesDictionary = [displayDictionary valueForKey:@kDisplayProductName];
//		if (productNamesDictionary != nil) {
//			displayName = [[productNamesDictionary allValues] objectAtIndex:0];
//		}
//	}
//	return (displayName != nil) ? displayName : @"Unknown Display";
    return @"Unknown Display Name";
}

+ (NSString *)displayNameUsingIndex:(long)displayIndex;
{
	CGDirectDisplayID IDs[kMaxDisplay];
	CGDisplayCount displayCount;
	
	CGGetActiveDisplayList(kMaxDisplay, IDs, &displayCount);
	return [LLDisplays displayNameUsingID:IDs[displayIndex]];
}

struct screenMode {
    size_t width;
    size_t height;
    size_t bitsPerPixel;
};

- (CGDisplayModeRef)bestMatchForMode:(DisplayParam *)pDP forDisplayID:(CGDirectDisplayID)displayID;
{    
    long index;
    CGDisplayModeRef mode = NULL;
    float bestDifference = FLT_MAX;
    NSAlert *theAlert;
    
// Get a copy of the current display mode
    
	CGDisplayModeRef displayMode = CGDisplayCopyDisplayMode(displayID);
    
// Loop through all display modes to determine the closest match.
// CGDisplayBestModeForParameters is deprecated on 10.6 so we will emulate it's behavior
// Try to find a mode with the requested depth and equal or greater dimensions first.
// If no match is found, try to find a mode with greater depth and same or greater dimensions.
// If still no match is found, just use the current mode.

    CFArrayRef allModes = CGDisplayCopyAllDisplayModes(displayID, NULL);
    for (index = 0; index < CFArrayGetCount(allModes); index++)	{
		mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, index);
		if ([self bitsPerPixelForMode:mode] != pDP->pixelBits) {            // must match pixel depth
			continue;
        }
		if ((CGDisplayModeGetWidth(mode) == pDP->widthPix) && (CGDisplayModeGetHeight(mode) == pDP->heightPix)) {
            if (CGDisplayModeGetRefreshRate(mode) == pDP->frameRateHz) {
                displayMode = mode;
                break;
            }
            else {
                if (fabs(CGDisplayModeGetRefreshRate(mode) - pDP->frameRateHz) < bestDifference) {
                    bestDifference = fabs(CGDisplayModeGetRefreshRate(mode) - pDP->frameRateHz);
                    displayMode = mode;
                }
            }
		}
	}
    if (displayMode == NULL) {
        theAlert = [[NSAlert alloc] init];
        [theAlert setMessageText:@"LLDisplays"];
        [theAlert setInformativeText:[NSString stringWithFormat:
            @"Could not match requested display mode: %ld bpp (%ld x %ld).",
            pDP->pixelBits, pDP->widthPix, pDP->heightPix]];
        [theAlert runModal];
        [theAlert release];
		exit(0);
    }
    return displayMode;
}

// CGDisplayModeCopyPixelEncoding was deprecated in 10.11,with not alternative listed for finding the pixel depth
// for displays.  I found the following methods to pull up a dictionary that contains display parameters.  This
// is currently undocumented by Apple.  JHRM 151125

- (size_t)bitsPerPixelForMode:(CGDisplayModeRef)mode;
{    
    return [self getValue:(CFDictionaryRef)*((int64_t *)mode + 2) forKey:kCGDisplayBitsPerPixel];
    
//    CFNumberRef num;
//    int bpp = -1;
//    CFDictionaryRef dict = (CFDictionaryRef)*((int64_t *)mode + 2);
//    
//    if (CFGetTypeID(dict) == CFDictionaryGetTypeID()
//        && CFDictionaryGetValueIfPresent(dict, kCGDisplayBitsPerPixel, (const void**)&num)) {
//        CFNumberGetValue(num, kCFNumberSInt32Type, (void*)&bpp);
//    }
//    CFRelease(mode);
//    return bpp;
    
//	CFStringRef pixEnc = CGDisplayModeCopyPixelEncoding(mode);
//	if (CFStringCompare(pixEnc, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
//		depth = 32;
//    }
//	else if(CFStringCompare(pixEnc, CFSTR(IO16BitDirectPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
//		depth = 16;
//    }
//	else if(CFStringCompare(pixEnc, CFSTR(IO8BitIndexedPixels), kCFCompareCaseInsensitive) == kCFCompareEqualTo) {
//		depth = 8;
//    }
//	return depth;
}

- (void)computeKdlConstants:(long)displayIndex {

	ColorPatches calibratedColor;
	
	calibratedColor = computeKdlColors(displayParam[displayIndex].CIEx, displayParam[displayIndex].CIEy);
	kdlConstants[displayIndex].rtc = (calibratedColor.equalEnergy.red - calibratedColor.cardinalYellow.red) /
										calibratedColor.equalEnergy.red;
	kdlConstants[displayIndex].gcb = (calibratedColor.equalEnergy.green - calibratedColor.cardinalGreen.green) /
										calibratedColor.equalEnergy.green;
	kdlConstants[displayIndex].gtc = (calibratedColor.equalEnergy.green - calibratedColor.cardinalYellow.green) /
										calibratedColor.equalEnergy.green;
	kdlConstants[displayIndex].bcb = (calibratedColor.equalEnergy.blue - calibratedColor.cardinalGreen.blue) /
										calibratedColor.equalEnergy.blue;
}

- (void)dealloc {

	[displayPhysical release];
	[super dealloc];
}

// Report the displayBounds as reported by Core Graphics.  The origin is taken as the upper left corner

- (NSRect)displayBounds:(long)displayIndex {

    CGRect rect;
    
    if (displayIndex >= numDisplays) {
        return NSMakeRect(0, 0, 0, 0);
    }
    rect = CGDisplayBounds(displayIDs[displayIndex]);
    return NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

// CGDisplayBounds returns a CGRect in which the origin is taken to be the upper left corner,
// relative to the upperleft corner of the main screen.  We convert this into the position
// of the lower left corner, relative to the lower left corner of the main screen.

- (NSRect)displayBoundsLLOrigin:(long)displayIndex;
{
    CGRect rect;
    
    if (displayIndex >= numDisplays) {
        return NSMakeRect(0, 0, 0, 0);
    }
    rect = CGDisplayBounds(displayIDs[displayIndex]);
	rect.origin.y = [[NSScreen mainScreen] frame].size.height - rect.origin.y - rect.size.height;
    return NSMakeRect(rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

// Update the display parameters

- (DisplayParam)displayParameters:(long)displayIndex;
{
	return displayParam[displayIndex];
}

- (NSSize)displaySizeDeg:(long)displayIndex {
	
	return NSMakeSize(atan2(displayParam[displayIndex].widthMM / 2.0, 
				displayParam[displayIndex].distanceMM) * kDegPerRadian * 2.0,
				atan2(displayParam[displayIndex].heightMM / 2.0, 
				displayParam[displayIndex].distanceMM) * kDegPerRadian * 2.0);
}

- (double)distanceMM:(long)displayIndex {

	return displayParam[displayIndex].distanceMM;
}

- (void)doSettingsPanel:(long)displayIndex {

	[displayPhysical doSettingsPanel:displayIndex];
	[self updatePhysicalParam:[displayPhysical displayParameters:displayIndex] displayIndex:displayIndex];
}

- (void)dumpCurrentDisplayMode:(CGDisplayCount)displayIndex {

    if (displayIndex < numDisplays) {
		[self dumpDisplayModeValues:CGDisplayCopyDisplayMode(displayIDs[displayIndex])];
    }
}

- (void)dumpDisplayModes:(CGDisplayCount)displayIndex;
{
    long index;
    CFArrayRef display_modes;
    CFIndex modes;
    
    if (displayIndex < numDisplays) {
		display_modes = CGDisplayCopyAllDisplayModes(displayIDs[displayIndex], NULL);
		modes = CFArrayGetCount(display_modes);
		for (index = 0; index < modes; index++) {
			[self dumpDisplayModeValues:(CGDisplayModeRef)CFArrayGetValueAtIndex(display_modes, index)];
		}
    }
}

- (void) dumpDisplayModeValues:(CGDisplayModeRef)mode;
{
    NSLog(@" ----- Display Mode Info for %d -----\n", CGDisplayModeGetIODisplayModeID(mode));
    NSLog(@" Bounds = %ld x %ld\n", CGDisplayModeGetWidth(mode), CGDisplayModeGetHeight(mode));
    NSLog(@" bpp = %ld, hz = %.1f\n", [self bitsPerPixelForMode:mode], CGDisplayModeGetRefreshRate(mode));
}

- (float)frameRateHz:(long)displayIndex;
{
	return displayParam[displayIndex].frameRateHz;
}

- (long)getValue:(CFDictionaryRef)dictionary forKey:(CFStringRef)key {

    int value = -1;
    CFNumberRef num;

    if (CFGetTypeID(dictionary) == CFDictionaryGetTypeID()
                        && CFDictionaryGetValueIfPresent(dictionary, key, (const void**)&num)) {
        CFNumberGetValue(num, kCFNumberSInt32Type, (void*)&value);
    }
    return value;
    
//    long value;
//    CFNumberRef number_value = (CFNumberRef)CFDictionaryGetValue(dictionary, key);
//
//    if (!number_value) {
//        return -1;
//    }
//    if (!CFNumberGetValue(number_value, kCFNumberLongType, &value)) {
//        return -1;
//    }
//    return value;
}

- (double)heightMM:(long)displayIndex {

	return displayParam[displayIndex].heightMM;
}
	
- (long)heightPix:(long)displayIndex {

	return displayParam[displayIndex].heightPix;
}

- (void)hideCursor:(long)displayIndex {
	
	CGDisplayHideCursor(displayIDs[displayIndex]);
}

- (float)highestSpatialFreqCPD:(long)displayIndex;
{
	return (displayParam[displayIndex].widthPix / [self displaySizeDeg:displayIndex].width / 2.0);
}

- (id)init {

	long index;
	
    if ((self = [super init]) != nil) {
		displayPhysical = [[LLDisplayPhysical alloc] init];
		CGGetActiveDisplayList(kMaxDisplay, displayIDs, &numDisplays);
		for (index = 0; index < numDisplays; index++) {
//			EDID[index] = [[LLDisplayEDID alloc] initWithDisplayID:displayIDs[index]];
			[self loadDisplayParameters:index];
		}
	}
    return self;
}

// Load the DisplayParam structure for a display, and precompute the values that will be needed
// for providing calibrated color values

- (void)loadDisplayParameters:(long)displayIndex;
{	
//	io_connect_t displayPort;
//	CFDictionaryRef displayModeDict;
//	CFDictionaryRef displayDict;
	CGDirectDisplayID displayID = displayIDs[displayIndex];
    CGDisplayModeRef displayMode;
	DisplayParam *pDP = &displayParam[displayIndex];
	
// Some display parameters are values that the controller determines, such
// as frame rate and pixel width.  These are read from the hardware.

//    displayModeDict = CGDisplayCurrentMode(displayID);
    displayMode = CGDisplayCopyDisplayMode(displayID);
    pDP->widthPix = CGDisplayModeGetWidth(displayMode);
    pDP->heightPix = CGDisplayModeGetHeight(displayMode);
    pDP->frameRateHz = CGDisplayModeGetRefreshRate(displayMode);
    pDP->pixelBits = [self bitsPerPixelForMode:displayMode];
	if (pDP->frameRateHz <= 0.0) {
		pDP->frameRateHz = 60.0;
		NSLog(@"Device for displayIndex %ld not reporting frame rate. Assuming 60 Hz", displayIndex);
	}
	NSLog(@"Device %ld frameRate %f", displayIndex, pDP->frameRateHz);
    
/*     pDP->pixelBits = [self getValue:displayModeDict forKey:kCGDisplayBitsPerPixel];
     pDP->frameRateHz = [self getValue:displayModeDict forKey:kCGDisplayRefreshRate];
     displayPort = CGDisplayIOServicePort(displayID);
	if (displayPort != MACH_PORT_NULL) {
		displayDict = IODisplayCreateInfoDictionary(displayPort, 0);
		if (displayDict != NULL) {
//			pDP->widthPix = [self getValue:displayModeDict forKey:kCGDisplayWidth];
//			pDP->heightPix = [self getValue:displayModeDict forKey:kCGDisplayHeight];
			CFRelease(displayDict);
		}
	} */
    
    
	[self updatePhysicalParam:[displayPhysical displayParameters:displayIndex] displayIndex:displayIndex];
}

- (float)lowestSpatialFreqCPD:(long)displayIndex;
{
	return (1.0 / [self displaySizeDeg:displayIndex].width);
}

- (short)numDisplays {

    return numDisplays;
}

- (long)pixelBits:(long)displayIndex {

	return displayParam[displayIndex].pixelBits;
}

- (u_int32_t)openGLDisplayID:(CGDisplayCount)displayIndex {

    if (displayIndex >= numDisplays) {
        return 0;
    }
    return CGDisplayIDToOpenGLDisplayMask(displayIDs[displayIndex]);
}

// Return RGB for a kdlTheta and kdlPhi

- (RGBDouble)RGB:(long)displayIndex kdlTheta:(double)kdlTheta kdlPhi:(double)kdlPhi;
{
    double lum, cb, tc;
    RGBDouble rgb;

    lum = sin(kRadiansPerDeg * kdlTheta);
    cb = tc = cos(kRadiansPerDeg * kdlTheta);
    cb *= cos(kRadiansPerDeg * kdlPhi);
    tc *= sin(kRadiansPerDeg * kdlPhi);
    rgb.red = (lum + cb + kdlConstants[displayIndex].rtc * tc) / sqrt(2.0);
    rgb.green = (lum + cb * kdlConstants[displayIndex].gcb + tc * 
						kdlConstants[displayIndex].gtc) / sqrt(2.0);
    rgb.blue = (lum + cb * kdlConstants[displayIndex].bcb + tc) / sqrt(2.0);
    return rgb;
}

-(RGBDouble)luminanceToRGB:(long)displayIndex {

    return [self RGB:displayIndex kdlTheta:90.0 kdlPhi:0.0];
}

- (BOOL)setDisplayMode:(long)displayIndex size:(CGSize)size bitDepth:(size_t)pixelBits frameRate:(CGRefreshRate)hz;
{				
    CGError status;
    CGDisplayModeRef modeRef;
    DisplayParam dp;

    if (displayIndex >= numDisplays) {
        return NO;
    }
    dp.widthPix = size.width;
    dp.heightPix = size.height;
    dp.frameRateHz = hz;
    dp.pixelBits = pixelBits;
    modeRef = [self bestMatchForMode:&dp forDisplayID:displayIDs[displayIndex]];
    status = CGDisplaySetDisplayMode(displayIDs[displayIndex], modeRef, NULL);
	[self loadDisplayParameters:displayIndex];
    return (status == CGDisplayNoErr);
}

- (void)showCursor:(long)displayIndex {
	
	CGDisplayShowCursor(displayIDs[displayIndex]);
}

// Show the dialog for changing display settings. 

- (void)showDisplayParametersPanel:(long)displayIndex {

	[self doSettingsPanel:displayIndex];
}

- (double)widthMM:(long)displayIndex {

	return displayParam[displayIndex].widthMM;
}

- (long)widthPix:(long)displayIndex;
{
	return displayParam[displayIndex].widthPix;
}

- (void)updatePhysicalParam:(DisplayPhysicalParam *)pDP displayIndex:(long)displayIndex {

	displayParam[displayIndex].CIEx = pDP->CIEx;
	displayParam[displayIndex].CIEy = pDP->CIEy;
	displayParam[displayIndex].distanceMM = pDP->distanceMM;
	displayParam[displayIndex].widthMM = pDP->widthMM;
	displayParam[displayIndex].heightMM = pDP->heightMM;	

	[self computeKdlConstants:displayIndex];		// update the kdl constants for the new entries
}

@end