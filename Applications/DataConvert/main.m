//
//  main.m
//  DataConverter
//
//  Created by John Maunsell on Sun Jul 07 2002.
//  Copyright (c) 2002. All rights reserved.
//

#import <Foundation/NSDebug.h>

int main(int argc, const char *argv[])
{
	NSDebugEnabled = YES;
	NSZombieEnabled = YES;
	NSDeallocateZombies = NO;
    //	NSHangOnUncaughtException = YES;
    //    [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSHangOnUncaughtExceptionMask];
	NSLog(@"NSDebugEnabled: %d", NSDebugEnabled);
	NSLog(@"NSZombieEnabled: %d", NSZombieEnabled);
	NSLog(@"NSDeallocateZombies: %d", NSDeallocateZombies);
//	NSLog(@"NSHangOnUncaughtException: %d", NSHangOnUncaughtException);

    return NSApplicationMain(argc, (const char **)argv);
}
