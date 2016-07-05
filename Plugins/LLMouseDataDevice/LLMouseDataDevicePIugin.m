//
//  LLMouseDataDevicePIugin.m
//  LLMouseDataDevice
//
//  Created by John Maunsell on 11/13/06.
//  Copyright 2006. All rights reserved.
//
// This is a dummy object that inherits from LLMouseDataDevice.  It is needed to avoid name 
// conflicts with LLMouseDataDevice, which exists in Lablib, a framework included in this project.

#import "LLMouseDataDevicePIugin.h"

@implementation LLMouseDataDevicePIugin

+ (NSInteger)version;
{
	return kLLPluginVersion;
}

@end
