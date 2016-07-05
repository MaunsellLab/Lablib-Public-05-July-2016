/*
 *  LLDataReader.h
 *  Lablib
 *  
 *  Protocol specifying required methods for reading data bytes
 *
 *  This is needed for a quirky reason.  The LLDataEventDefs need to call the LLDataFileReader so they can
 *  read their definitions from the data file.  But the LLDataFileReaders also need to declare the LLDataEventDefs,
 *  because they need them all the time.  I couldn't figure out a simpler way to avoid the circular header file
 *  call than to just use a protocol.
 *  Created by John Maunsell on Tue May 17, 2005.
 *  Copyright (c) 2005. All rights reserved.
 *
 */

@protocol LLDataReader <NSObject>

- (BOOL)dataBytes:(Ptr)buffer length:(long)numBytes;
- (NSString *)dataString;

@end