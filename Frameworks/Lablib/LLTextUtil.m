//
//  LLTextUtil.m
//  Lablib
//
//  Created by John Maunsell on Sun Jun 20 2004.
//  Copyright (c) 2004. All rights reserved.
//

#import "math.h"
#import "LLTextUtil.h"

@implementation LLTextUtil

+ (NSString *)capitalize:(NSString *)string prefix:(NSString *)prefix;
{
	return [NSString stringWithFormat:@"%@%@%@", prefix,
			[[string substringWithRange:NSMakeRange(0, 1)] uppercaseString],
			[string substringFromIndex:1]];
}

+ (int)precisionForValue:(float)value significantDigits:(long)digits {

	long log10Rounded;
	
	if (value == 0) {
		return digits - 1;
	}
	log10Rounded = log10(fabs(value));
	if (abs(value < 1.0)) {
		log10Rounded--;
	}
	return MAX(0, digits - log10Rounded - 1);
}

+ (NSString *)stripPrefixAndDecapitalize:(NSString *)string prefix:(NSString *)prefix;
{
	return [NSString stringWithFormat:@"%@%@", 
			[[string substringWithRange:NSMakeRange([prefix length], 1)] lowercaseString],
			[string substringFromIndex:([prefix length] + 1)]];
}

@end
