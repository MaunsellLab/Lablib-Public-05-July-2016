//
//  LLParameterController.h
//  Lablib
//
//  Created by John Maunsell on Sun Aug 01 2004.
//  Copyright (c) 2004. All rights reserved.
//

enum {kBoolean, kChar, kSignedChar, kUnsignedChar, kShort, kUnsignedShort, kInt, kUnsignedInt,
		kLong, kUnsignedLong, kFloat, kDouble, kLongDouble, kLongLong, kUnsignedLongLong, kPtr};

// #pragma warning off /??? Need to figure out how to turn off warning about long double size

typedef union {
	Boolean				boolParam;
	char				charParam;
	signed char			signedCharParam;
	unsigned char		unsignedCharParam;
	short				shortParam;
	unsigned short		unsignedShortParam;
	int					intParam;
	unsigned int		unsignedIntParam;
	long				longParam;
	unsigned long		unsignedLongParam;
	float				floatParam;
	double				doubleParam;
//	long double			longDoubleParam;
	long long			longLongParam;
	unsigned long long  unsignedLongLongParam;
	unsigned char		*ptr;
} LLArg;


typedef struct {
	NSString *name;
	LLArg defaultValue;
	long lengthBytes;
	long type;
} LLParameter;

@interface LLParameterController : NSObject {

@protected
	NSMutableDictionary *parameters;
}

- (void)loadViewAndSubviews:(NSView *)view;
- (void)registerParameters:(LLParameter *)paramList;

@end
