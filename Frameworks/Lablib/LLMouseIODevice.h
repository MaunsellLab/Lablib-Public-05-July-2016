//
//  LLMouseIODevice.h
//  Lablib
//
//  Created by John Maunsell on Thu Jun 05 2003.
//  Copyright (c) 2003. All rights reserved.
//

#import "LLIODevice.h"
#import "LLMouseIOSettings.h"

extern NSString *LLMouseButtonBitsKey;
extern NSString *LLMouseGainKey;
extern NSString *LLMouseXBitsKey;
extern NSString *LLMouseYBitsKey;

@interface LLMouseIODevice : NSObject <LLIODevice> {

@protected
	long				channel;
    BOOL 				dataEnabled;
	LLMouseIOSettings	*mouseSettings;
    double 				nextSampleTimeS;
    double 				nextSpikeTimeS;
	NSPoint				origin;
    double 				samplePeriodMS;
	long				time;
	BOOL 				timestampActive;
    double				timestampRefS;
	unsigned short		timestampBits;
    double				timestampTickPerMS;
}

- (void)setOrigin:(NSPoint)point;

@end
