//
//  LLStandardFileNames.h
//  Lablib
//
//  Created by John Maunsell on Sun Jun 01 2003.
//  Copyright (c) 2003. All rights reserved.
//

extern NSString	*LLLastFileNameKey;
extern NSString	*LLDataFileExtention;

@interface LLStandardFileNames : NSObject {

}

+ (NSArray *)allowedFileTypes;
+ (BOOL)alphaIncrement:(const char *)cString characters:(long)length;
+ (NSString *)defaultDirPath;
+ (NSString *)defaultFileExtension;
+ (NSString *)defaultFileName;
+ (BOOL)findOrCreateDirectory:(NSString *)path;
+ (BOOL)numIncrement:(const char *)cString characters:(long)length;
+ (BOOL)standardNameFormat:(NSString *)fileName;

@end
