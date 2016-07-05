//
//  LLMouseDataDevice.h
//  Lablib
//
//  Created by John Maunsell on Thu Jun 05 2003.
//  Copyright (c) 2005. All rights reserved.
//

#import "LLDataDevice.h"

#define kLLMouseADChannels				8
#define kLLMouseDigitalBits				16
#define kLLMouseSamplePeriodMS			5
//#define kLLMouseTimestampTickPerMS		1
#define kLLMouseTimestampPeriodMS		1

extern NSString *LLMouseButtonBitsKey;
extern NSString *LLMouseGainKey;
extern NSString *LLMouseXBitsKey;
extern NSString *LLMouseYBitsKey;

@interface LLMouseDataDevice : LLDataDevice {

	BOOL				buttonWasDown;
	double 				nextSampleTimeS;
	BOOL				mouseDown;
	NSPoint				origin;
	NSMutableData		*sampleData[kLLMouseADChannels];
    double				timestampRefS;
	NSMutableData		*timestampData[kLLMouseDigitalBits];
}

- (void)setMouseState:(long)state;
- (void)setOrigin:(NSPoint)point;

@end