//
//  LLDisplays.h
//
//  Created by John Maunsell on Thu Feb 13 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLDisplayPhysical.h"
#import "LLDisplayUtilities.h"
//#import "LLDisplayEDID.h"

#define kPI          		(atan(1) * 4)
#define k2PI         		(atan(1) * 4 * 2)
#define kRadiansPerDeg      (kPI / 180.0)
#define kDegPerRadian		(180.0 / kPI)

typedef struct {
	float rtc;
	float gcb;
	float gtc;
	float bcb;
} kdlTransform;

typedef struct {
	double      frameRateHz;		// the following entries are read from the device
	long        pixelBits;	
	long        widthPix;
	long        heightPix;
	RGBDouble   CIEx;				// the following entries are read from system-wide settings
	RGBDouble   CIEy;
	double      distanceMM;
	double      widthMM;
	double      heightMM;
} DisplayParam;

typedef struct {
	long    widthPix;
	long    heightPix;
	long    pixelBits;
	float   frameRateHz;
} DisplayModeParam;

@interface LLDisplays : NSObject { 
 
@protected
	LLDisplayPhysical		*displayPhysical;
	DisplayParam			displayParam[kMaxDisplay];
	CGDirectDisplayID 		displayIDs[kMaxDisplay];
//	LLDisplayEDID			*EDID[kMaxDisplay];
	kdlTransform			kdlConstants[kMaxDisplay];
	CGDisplayCount 			numDisplays;
}

+ (NSString *)displayNameUsingID:(CGDirectDisplayID)displayID;
+ (NSString *)displayNameUsingIndex:(long)displayIndex;

- (size_t)bitsPerPixelForMode:(CGDisplayModeRef)mode;
- (CGDisplayModeRef)bestMatchForMode:(DisplayParam *)pDP forDisplayID:(CGDirectDisplayID)displayID;
//- (BOOL)captureDisplay:(long)displayIndex;
- (NSRect)displayBounds:(long)mainDisplayIndex;
- (NSRect)displayBoundsLLOrigin:(long)displayIndex;
- (DisplayParam)displayParameters:(long)displayIndex;
- (NSSize)displaySizeDeg:(long)displayIndex;
- (double)distanceMM:(long)displayIndex;
- (void)doSettingsPanel:(long)displayIndex;
- (void)dumpCurrentDisplayMode:(CGDisplayCount)displayIndex;
- (void)dumpDisplayModes:(CGDisplayCount)displayIndex;
- (void) dumpDisplayModeValues:(CGDisplayModeRef)mode;
- (float)frameRateHz:(long)displayIndex;
- (void)hideCursor:(long)displayIndex;
- (u_int32_t)openGLDisplayID:(CGDisplayCount)displayIndex;
- (long)getValue:(CFDictionaryRef)values forKey:(CFStringRef)key;
- (double)heightMM:(long)displayIndex;
- (long)heightPix:(long)displayIndex;
- (float)highestSpatialFreqCPD:(long)displayIndex;
- (void)loadDisplayParameters:(long)displayIndex;
- (float)lowestSpatialFreqCPD:(long)displayIndex;
- (RGBDouble)luminanceToRGB:(long)displayIndex;
- (short)numDisplays;
- (long)pixelBits:(long)displayIndex;
//- (BOOL)releaseDisplay:(CGDisplayCount)displayIndex;
- (RGBDouble)RGB:(long)displayIndex kdlTheta:(double)kdlTheta kdlPhi:(double)kdlPhi;
- (BOOL)setDisplayMode:(long)displayIndex size:(CGSize)size bitDepth:(size_t)pixelDepthBits 
                frameRate:(CGRefreshRate)hz;
- (void)showCursor:(long)displayIndex;
- (void)showDisplayParametersPanel:(long)index;
- (long)widthPix:(long)displayIndex;
- (double)widthMM:(long)displayIndex;
- (void)updatePhysicalParam:(DisplayPhysicalParam *)pDP displayIndex:(long)displayIndex;

@end

