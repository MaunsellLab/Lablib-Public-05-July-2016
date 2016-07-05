/*
 *  Knot.h
 *  Knot
 *
 *  Created by John Maunsell on Sat Feb 01 2003.
 *  Copyright (c) 2003-2007. All rights reserved.
 *
 */

// We need the following definition, even if the non-ITC18 version is being built

//#define kITC18DAVoltageRangeV  10.24

enum {kLeverChannel = 0, kVBLChannel, kFirstSpikeChannel};

#define		kSpikeChannels			2						// One channels spikes, one channel stim pulses
#define		kSamplePeriodMS			5
#define		kTimestampTickMS		1