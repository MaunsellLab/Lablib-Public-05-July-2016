//
//  LLTextUtil.h
//  Lablib
//
//  Created by John Maunsell on Sun Jun 20 2004.
//  Copyright (c) 2004 . All rights reserved.
//

@interface LLTextUtil : NSObject {

}

+ (NSString *)capitalize:(NSString *)string prefix:(NSString *)prefix;
+ (int)precisionForValue:(float)value significantDigits:(long)digits;
+ (NSString *)stripPrefixAndDecapitalize:(NSString *)string prefix:(NSString *)prefix;

@end
