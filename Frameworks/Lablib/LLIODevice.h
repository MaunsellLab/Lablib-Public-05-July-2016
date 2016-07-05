/*
 *  LLIODevice.h
 *  Lablib
 *  
 *  Protocol specifying required methods for a data input object
 *
 *  Created by John Maunsell on Fri Apr 18 2003.
 *  Copyright (c) 2003. All rights reserved.
 *
 */

#import "LLStandardDataEvents.h"

#define	kADChannels		8
#define	kDigitalBits	16

@protocol LLIODevice

- (BOOL)ADData:(short *)pArray;
- (BOOL)canConfigure;
- (void)configure;
- (BOOL)dataEnabled;
- (void)disableTimestampBits:(NSNumber *)bits;
- (unsigned short)digitalInputValues;
- (void)digitalOutputBitsOff:(unsigned short)bits;
- (void)digitalOutputBitsOn:(unsigned short)bits;
- (void)enableTimestampBits:(NSNumber *)bits;
- (NSString *)name;
- (long)samplePeriodMS;
- (BOOL)setDataEnabled:(BOOL)state;
- (void)setSamplePeriodMS:(double)samplePeriodMS;
- (void)setTimestampTickPerMS:(double)timestampTicksPerMS;
- (BOOL)timestampData:(TimestampData *)pData;
- (long)timestampTickPerMS;

@end