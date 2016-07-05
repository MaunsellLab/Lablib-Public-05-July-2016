//
//  LLDisplayEDID.m
//  Lablib
//
//  Created by John Maunsell on 1/16/05.
//  Copyright 2005. All rights reserved.
//

#import "LLDisplayEDID.h"
#import <ApplicationServices/ApplicationServices.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/graphics/IOGraphicsLib.h>

#define kEDIDLength							0x80

#define kEDIDHeader							0x00
#define kEDIDHeaderEnd						0x07
#define kEDIDManufacturer					0x08
#define kEDIDModelID						0x0a
#define kEDIDYearMade						0x11
#define kEDIDStructVersion					0x12
#define kEDIDStructRevision					0x13
#define kEDIDHSizeCM						0x15
#define kEDIDVSizeCM						0x16
#define kDPMSFlags							0x18
#define kEDIDDetailedTimingDescriptions		0x36

#define kNumDetailedTimingDescriptions		4
#define kDetailedTimingDescriptionSize		18

#define kDescriptorData						5
#define kMonitorLimits						0xfd
#define kMonitorName						0xfc

#define kVerticalMin						5
#define kVerticalMax						6
#define kHorizontalMin						7
#define kHorizontalMax						8
#define kPixelClockMax						9
#define kGTFSupport							10

#define kDPMSActiveOff						(1 << 5)
#define kDPMSSuspend						(1 << 6)
#define kDPMSStandby						(1 << 7)

#define kTimingFlags						17
#define kInterlacedFlag						0x80
#define kSyncTypeFlag						0x18

#define kSyncSeparated						0x18
#define kHSyncPositive						0x04
#define kVSyncPositive						0x02

#define kEDIDUnknownDescriptor				-1
#define kEDIDDetailedTimingBlock			-2

/*
	timing[1-8]: 3 integers
		supported standard timing
		horizontal resolution
		vertical resolution
		(vertical) refresh rate
		0 0 0 if not used.

	timings: bitmask
		supported established timings
		0x000001 720x400@70Hz (VGA 640x400, IBM)
		0x000002 720x400@88Hz (XGA2)
		0x000004 640x480@60Hz (VGA)
		0x000008 640x480@67Hz (Mac II, Apple)
		0x000010 640x480@72Hz (VESA)
		0x000020 640x480@75Hz (VESA)
		0x000040 800x600@56Hz (VESA)
		0x000080 800x600@60Hz (VESA)
		0x000100 800x600@72Hz (VESA)
		0x000200 800x600@75Hz (VESA)
		0x000400 832x624@75Hz (Mac II)
		0x000800 1024x768@87Hz interlaced (8514A)
		0x001000 1024x768@60Hz (VESA)
		0x002000 1024x768@70Hz (VESA)
		0x004000 1024x768@75Hz (VESA)
		0x008000 1280x1024@75Hz (VESA)
		0x010000 - 0x800000 Manufacturer reserved
		0x800000 1152x870 @ 75 Hz (Mac II, Apple)?
*/		

@implementation LLDisplayEDID

- (NSString *)description;
{
	NSString *string;
	
	string = [NSString stringWithFormat:@"\nEDID Version %ld revision %ld", dataVersion, dataRevision];
	string = [string stringByAppendingFormat:@"\n   Identifier \"%s\" VendorName \"%s\" Manufactured %ld", 
				monitorName, vendorSign, yearMade];
	string = [string stringByAppendingFormat:@"\n   Size: %ld x %ld cm", hSizeCM, vSizeCM];
	string = [string stringByAppendingFormat:@"\n   Mode: %ld x %ld pixels", hActive, vActive];
	string = [string stringByAppendingFormat:@"\n   vFreq %3.3f Hz, hFreq %6.3f kHz", vFreqHz, hFreqHz];
	string = [string stringByAppendingFormat:@"\n   Pixel clock %f MHz", (double)pixelClockMHz / 1000000.0];
	string = [string stringByAppendingFormat:@"\n   HTimings %lu %lu %lu %lu", hActive, hActive + hSyncOffset,
			hActive + hSyncOffset + hSyncWidth, hTotal];
	string = [string stringByAppendingFormat:@"\n   VTimings %lu %lu %lu %lu", vActive, vActive + vSyncOffset,
			vActive + vSyncOffset + vSyncWidth, vTotal];
	if (validLimits) {
		string = [string stringByAppendingFormat:@"\n   Horizontal Sync: %lu-%lu", hSyncMin, hSyncMax];
		string = [string stringByAppendingFormat:@"\n   Vertical Refresh: %lu-%lu", vSyncMin, vSyncMax];
		string = [string stringByAppendingFormat:@"\n   Max pixel clock %lu MHz", (long)pixelClockMaxMHz * 10];
		string = [string stringByAppendingFormat:@"\n   GFT Support %ld", GFTSupport];
	}
	string = [string stringByAppendingFormat:@"\n   Power Management: active off: %s  suspend: %s  standby: %s",
			(DPMSActiveOff) ? "yes" : "no", (DPMSSuspend) ? "yes" : "no", (DPMSStandby) ? "yes" : "no"];
	string = [string stringByAppendingFormat:@"\n   Flags: \"%s\" \"%sHSync\" \"%sVSync\"\n", 
					interlaced ? "Interlaced": "Noninterlaced",
					hSyncPositive ? "+": "-",  vSyncPositive ? "+": "-"];
	return string;
}

- (long)EDIDBlockType:(unsigned char *)block;
{
	const unsigned char EDIDV1DescriptorFlag[] = {0x00, 0x00};

	if (!strncmp((const char *)EDIDV1DescriptorFlag, (const char *)block, sizeof(EDIDV1DescriptorFlag))) {
		if (block[2] != 0) {
			return kEDIDUnknownDescriptor;
		}
		else {
			return block[3];
		}
    } 
	else {
      return kEDIDDetailedTimingBlock;
    }
}

- (float)hFreqHz;
{
	return hFreqHz;
}

- (id)initWithDisplayID:(CGDirectDisplayID)displayID;
{
	const unsigned char EDIDV1Header[] = {0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00};

	unsigned char index, checksum, EDID[kEDIDLength];
	CFRange allrange = {0, kEDIDLength};
	io_connect_t displayPort = 0;
	CFDictionaryRef displayDict = nil;
	CFDataRef EDIDValue = nil;
	
	if ((self = [super init]) == nil) {
		return self;
	}

// Read the EDID and do the checksum

    displayPort = CGDisplayIOServicePort(displayID);
	if (displayPort == 0) {
		return self;
	}
	displayDict =  IODisplayCreateInfoDictionary(displayPort, 0);       
	if (displayDict == nil) {
		return self;
	}
	EDIDValue = CFDictionaryGetValue(displayDict, CFSTR(kIODisplayEDIDKey));
    //   CFRelease(displayDict);
	if (EDIDValue == nil) {		// this will fail on e.g., powerbook s-video output 
		return self;
	}
	CFDataGetBytes(EDIDValue, allrange, EDID);
	for (index = checksum = 0; index < kEDIDLength; index++) {
		checksum += EDID[index];
	}
	if (checksum != 0) {
		NSLog(@"LLDisplayEDID: EDID Checksum failed");
		return self;
	}
	if (strncmp((const char *)(EDID + kEDIDHeader), (const char *)EDIDV1Header, kEDIDHeaderEnd + 1)) {
		NSLog(@"LLDisplayEDID: EDID does not match Version 1 header");
		return self;
	}
	[self readHeaderInfo:EDID];				// Get the monitor name
	[self readMonitorName:EDID];			// Get the monitor name
	[self readMonitorLimits:EDID];			// Get the monitor limits
	[self readMonitorTiming:EDID];			// Parse the timing mode blocks
	valid = YES;

	return self;
}

- (void)readHeaderInfo:(unsigned char *)EDID;
{
	unsigned char DPMSFlags;
	long h;

	dataVersion = (long)EDID[kEDIDStructVersion];
	if (dataVersion != 1) {
		NSLog(@"LLDisplayEDID: Communicating with monitor that does not use Version 1 EDID (Version %ld)", dataVersion);
	}
	dataRevision = (long)EDID[kEDIDStructRevision];

// The manufacturer's 3 character name code is encoded in two bytes

	h = (((long)*(EDID + kEDIDManufacturer)) << 8) | *(EDID + kEDIDManufacturer + 1);
	vendorSign[0] = ((h >> 10) & 0x1f) + 'A' - 1;
	vendorSign[1] = ((h >> 5) & 0x1f) + 'A' - 1;
	vendorSign[2] = (h & 0x1f) + 'A' - 1;
	vendorSign[3] = 0;
	yearMade = EDID[kEDIDYearMade] + 1990;

// Read the monitor size

	hSizeCM = EDID[kEDIDHSizeCM];
	vSizeCM = EDID[kEDIDVSizeCM];

// Parse the Display Power Management Signalling flags

	DPMSFlags = EDID[kDPMSFlags];
	DPMSActiveOff = (DPMSFlags & kDPMSActiveOff);
	DPMSStandby = (DPMSFlags & kDPMSStandby);
	DPMSSuspend = (DPMSFlags & kDPMSSuspend);

}

- (void)readMonitorLimits:(unsigned char *)pEDID;
{
	unsigned char index, *block;

	block = pEDID + kEDIDDetailedTimingDescriptions;
	for (index = 0; index < kNumDetailedTimingDescriptions; index++) {
		if ([self EDIDBlockType:block] == kMonitorLimits) {
			hSyncMin = block[kHorizontalMin];
			hSyncMax = block[kHorizontalMax];
			vSyncMin = block[kVerticalMin];
			vSyncMax = block[kVerticalMax];
			pixelClockMaxMHz = (block[kPixelClockMax] == 0xff) ? 0 : block[kPixelClockMax] * 10;
			GFTSupport = block[kGTFSupport];
			validLimits = YES;
			break;
		}
		block += kDetailedTimingDescriptionSize;
	}
}

- (void)readMonitorName:(unsigned char *)pEDID;
{
	unsigned char i, index, *block, *ptr;
	
	block = pEDID + kEDIDDetailedTimingDescriptions;
	for (index = 0; index < kNumDetailedTimingDescriptions; index++) {
		if ([self EDIDBlockType:block] == kMonitorName) {
			ptr = block + kDescriptorData;
			for (i = 0; i < kMonitorNameLength; i++) {
				if (*ptr == 0xa) {
					monitorName[i] = 0;
					break;
				}
				monitorName[i] = *ptr++;
			}
			break;				// Stop after first block with name
		}
		block += kDetailedTimingDescriptionSize;
	}
	if (monitorName[0] == 0) {
		if (strlen(vendorSign) + 10 > sizeof(monitorAltName)) {
			vendorSign[3] = 0;
		}
		sprintf(monitorName, "%s:%02x%02x", vendorSign, pEDID[kEDIDModelID], pEDID[kEDIDModelID + 1]);
	}
}

- (void)readMonitorTiming:(unsigned char *)pEDID;
{
	unsigned char index, *block;

	block = pEDID + kEDIDDetailedTimingDescriptions;
	for (index = 0; index < kNumDetailedTimingDescriptions; index++) {
		if ([self EDIDBlockType:block] == kEDIDDetailedTimingBlock) {
			hActive = (((long)(block[4] & 0xf0)) << 4) | block[2];
			hBlank = (((long)(block[4] & 0x0f)) << 8) | block[3];
			hTotal = hActive + hBlank;
			vActive = (((long)(block[7] & 0xf0)) << 4) | block[5];
			vBlank = (((long)(block[7] & 0x0f)) << 8) | block[6];
			vTotal = vActive + vBlank;
			
			hSyncOffset = ((long)((block[11] & 0xc0) >> 2)) | block[8];
			hSyncWidth = (long)(block[11] & 0x30) | block[9];
			vSyncOffset = ((long)((block[11] & 0x0c)) << 2) | ((block[10] & 0xf0) >> 4);
			vSyncWidth = ((long)((block[11] & 0x03) << 4)) | (block[10] & 0x0f);
			
			pixelClockMHz = (((long)block[1] << 8) + block[0]) * 10000;
			vFreqHz = (double)pixelClockMHz / ((double)vTotal * (double)hTotal);
			hFreqHz = (double)pixelClockMHz / (double)(hTotal * 1000);
			interlaced = block[kTimingFlags] & kInterlacedFlag;
			syncSeparated = ((block[kTimingFlags] & kSyncTypeFlag) == kSyncSeparated);
			hSyncPositive = (block[kTimingFlags] & kHSyncPositive);
			vSyncPositive = (block[kTimingFlags] & kVSyncPositive);
			break;
		}
		block += kDetailedTimingDescriptionSize;
	}
}

- (BOOL)valid;
{
	return valid;
}

- (float)vFreqHz;
{
	return vFreqHz;
}

@end


