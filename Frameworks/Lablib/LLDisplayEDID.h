//
//  LLDisplayEDID.h
//  Lablib
//
//  Support for parsing Extended Display Information Data (VESA starndard)
//  Created by John Maunsell on 1/16/05.
//  Copyright 2005. All rights reserved.
//

#define kMonitorNameLength		13

@interface LLDisplayEDID : NSObject {

	BOOL	DPMSActiveOff;
	BOOL	DPMSStandby;
	BOOL	DPMSSuspend;
	long	dataRevision;
	long	dataVersion;
	long	GFTSupport;
	long	hActive;
	long	hBlank;
	float	hFreqHz;
	long	hSizeCM;
	long	hSyncMax;
	long	hSyncMin;
	long	hSyncOffset;
	BOOL	hSyncPositive;
	long	hSyncWidth;
	long	hTotal;
	BOOL	interlaced;
	char	monitorAltName[100];
	char	monitorName[kMonitorNameLength];
	long	pixelClockMHz;
	long	pixelClockMaxMHz;
	BOOL	syncSeparated;
	long	vActive;
	BOOL	valid;
	BOOL	validLimits;
	long	vBlank;
	char	vendorSign[4];
	float	vFreqHz;
	long	vSizeCM;
	long	vSyncMax;
	long	vSyncMin;
	long	vSyncOffset;
	BOOL	vSyncPositive;
	long	vSyncWidth;
	long	vTotal;
	long	yearMade;
}

- (long)EDIDBlockType:(unsigned char *)block;
- (float)hFreqHz;
- (id)initWithDisplayID:(CGDirectDisplayID)displayID;
- (void)readHeaderInfo:(unsigned char *)pEDID;
- (void)readMonitorLimits:(unsigned char *)pEDID;
- (void)readMonitorName:(unsigned char *)pEDID;
- (void)readMonitorTiming:(unsigned char *)pEDID;
- (BOOL)valid;
- (float)vFreqHz;

@end
