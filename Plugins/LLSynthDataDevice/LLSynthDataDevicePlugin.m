//
//  LLSynthDataDevicePlugin.m
//  LLSynthDataDevice
//
//  Created by John Maunsell on 11/14/06.
//  Copyright 2006. All rights reserved.
//
// This is a dummy object that inherits from LLSynthDataDevice.  It is needed to avoid name 
// conflicts with LLSynthDataDevice, which exists in Lablib, a framework included in this project.

#import "LLSynthDataDevicePlugin.h"

@implementation LLSynthDataDevicePlugin

+ (NSInteger)version;
{
	return kLLPluginVersion;
}

@end
