//
//  LLVisualStimulus.m
//  Lablib
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

/* 
The LLVisualStimulus implements a complicated case of binding between instance variables, text fields in a settings
dialog, and NSUserDefaults.  The text fields in a setting dialog always wants to be bound to instance variables in 
LLVisualStimulus (their owner), and sometimes we want the instance variables to be bound to NSUserDefaults.  But the 
NSUserDefaults is optional, because we can't have all instances of an LLVisualStimulus bound to the same defaults. If 
the user specifies a prefix for the keys for NSUserDefaults, we activate binding to NSUserDefaults. (Note that the user
might choose to bind multiple instances of LLVisualStimuli to the same keys.) 

If we are bound to NSUserDefaults, the binding must be bi-directional, because the user might want to change the
LLVisualStimulus using either changes to the NSUserDefaults or using  a direct call to the LLVisualStimulus.  Because
the instance variables are bound to both the text fields and NSUserDefaults, there will be infinite loops if we don't
intervene.  A change at any point will lead to calls to -set*, which will generate further calls to -set*.  To prevent
this, we use a flag that causes -set* to do nothing if a -set* call is underway.  This is implements in -updateFloatDefault
for simplicity.

The binding with the textfields is implemented in the Interface Builder.  Note that this binding is automatically
bi-directional.  Binding with NSUserDefaults is more complicated.  We use [self -bind...] to bind to NSUserDefaults.
This binding causes the instance variables to stay in synch with NSUserDefaults, but not the converse.  Keeping
NSUserDefaults synched (with changes from the textFields or -set*) is achieved by direct calls (when they are not
prevented by the flag). 

*/

#import "LLVisualStimulus.h"
#import "LLTextUtil.h"

NSString *LLAzimuthDegKey = @"azimuthDeg";
NSString *LLBackColorKey = @"backColor";
NSString *LLDirectionDegKey = @"directionDeg";
NSString *LLElevationDegKey = @"elevationDeg";
NSString *LLForeColorKey = @"foreColor";
NSString *LLKdlThetaDegKey = @"kdlThetaDeg";
NSString *LLKdlPhiDegKey = @"kdlPhiDeg";
NSString *LLRadiusDegKey = @"radiusDeg";

@implementation LLVisualStimulus

- (float)azimuthDeg;
{
	return azimuthDeg;
}

- (NSColor *)backColor;
{
	return backColor;
}

// The binding will simply fail if the keys have not been registered with in user defaults.  Compulsive users
// will have taken care of this, but others may not have.  For that reason, we register all the prefixed-keys
// with user defaults before attempting to bind.

- (void)bindValuesToKeysWithPrefix:(NSString *)newPrefix;
{
	NSEnumerator *enumerator;
	NSString *key, *prefixedKey;
	
	[self unbindValues];

	[newPrefix retain];
	[taskPrefix release];
	taskPrefix = newPrefix;
	[prefix release];
	prefix = [[NSString stringWithFormat:@"%@%@", taskPrefix, stimPrefix] retain];

	enumerator = [keys objectEnumerator];
	while ((key = [enumerator nextObject]) != nil) {
		prefixedKey = [LLTextUtil capitalize:key prefix:prefix];
		if ([[NSUserDefaults standardUserDefaults] objectForKey:prefixedKey] == nil) {
			[[NSUserDefaults standardUserDefaults] setFloat:0.0 forKey:prefixedKey];
			NSLog(@"Registering value for %@", prefixedKey);
		}
		[self bind:key toObject:[NSUserDefaultsController sharedUserDefaultsController] 
				withKeyPath:[NSString stringWithFormat:@"values.%@", prefixedKey] options:nil];
	}
	key = LLForeColorKey;
	prefixedKey = [LLTextUtil capitalize:key prefix:prefix];
	[self bind:key toObject:[NSUserDefaultsController sharedUserDefaultsController] 
				withKeyPath:[NSString stringWithFormat:@"values.%@", prefixedKey] 
				options:[NSDictionary dictionaryWithObjects:
				[NSArray arrayWithObjects:NSUnarchiveFromDataTransformerName,
				[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0], nil]
				forKeys:[NSArray arrayWithObjects:
				@"NSValueTransformerName", NSNullPlaceholderBindingOption, nil]]];
	key = LLBackColorKey;
	prefixedKey = [LLTextUtil capitalize:key prefix:prefix];
	[self bind:key toObject:[NSUserDefaultsController sharedUserDefaultsController] 
				withKeyPath:[NSString stringWithFormat:@"values.%@", prefixedKey] 
				options:[NSDictionary dictionaryWithObjects:
				[NSArray arrayWithObjects:NSUnarchiveFromDataTransformerName,
				[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0], nil]
				forKeys:[NSArray arrayWithObjects:
				@"NSValueTransformerName", NSNullPlaceholderBindingOption, nil]]];
}

- (void)dealloc;
{

// If we have had values bound to key words, we need to clean up all those bindings.
// -unbindValues will also do the job of releasing prefix and taskPrefix, so we don't nee
// to do that here.

	[self unbindValues];
	
	[displays release];
	[stimPrefix release];
	[foreColor release];
	[backColor release];
	[keys release];
    [topLevelObjects release];
	[super dealloc];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"(0x%x) state: %s azi: %.1f ele: %.1f rad: %.1f dir %.1f",
		(unsigned int)self, (state ? "\"On\"" : "\"Off\""), azimuthDeg, elevationDeg, radiusDeg, directionDeg];
}

// We need this to adhere to the LLVisualStimulus protocol, but return zero because we have no direction

- (float)directionDeg;
{
	return directionDeg;
}

- (void)directSetAzimuthDeg:(float)aziDeg elevationDeg:(float)eleDeg;
{
	azimuthDeg = aziDeg;
	elevationDeg = eleDeg;
}

// Overwrite this method if you want to do a setFrame that is not key-value compliant
// (but will run faster)

- (void)directSetFrame:(NSNumber *)frameNumber;
{
	[self setFrame:frameNumber];
}

- (void)directSetDirectionDeg:(float)newDirection;
{
	while (newDirection < 0) {							// direction must be positive
		newDirection += 360.0;
	}
	directionDeg = newDirection;
}

- (void)directSetRadiusDeg:(float)newRadius;
{
	radiusDeg = newRadius;
}

// The draw function must be overridden by subclassed.  It assumes than an OpenGL context has already 
// been properly set up.

- (void)draw;
{	
}

- (float)elevationDeg;
{
	return elevationDeg;
}

- (NSColor *)foreColor;
{
	return foreColor;
}

- (id)init;
{	
	if ((self = [super init]) != nil) {
		keys = [[NSMutableArray alloc] initWithObjects:LLAzimuthDegKey, LLDirectionDegKey, LLElevationDegKey, 
				LLKdlPhiDegKey, LLKdlThetaDegKey, LLRadiusDegKey, nil];
        
        // Create the fore and back colors, coercing them because they default to the simplest space that can hold them
        
		foreColor = [[[NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0] 
                     colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
		backColor = [[[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0] 
                     colorUsingColorSpaceName:NSCalibratedRGBColorSpace] retain];
	}
	return self;
}

- (float)kdlThetaDeg;
{
	return kdlThetaDeg;
}

- (float)kdlPhiDeg;
{
	return kdlPhiDeg;
}

- (float)radiusDeg;
{
	return radiusDeg;
}

- (void)removeKeyFromBinding:(NSString *)key;
{
	long index = [keys indexOfObjectIdenticalTo:key];
	
	if (index == NSNotFound) {
		NSLog(@"LLVisualStimulus: removeKeyFromBinding failed to find key %@ in keys", key);
	}
	else {
		[self unbindValues];
		[keys removeObjectAtIndex:index];
	}
}

- (void)removeKeysFromBinding:(NSArray *)removeKeys;
{
	NSString *key;
	NSEnumerator *enumerator = [removeKeys objectEnumerator];
	while ((key = [enumerator nextObject])) {
		[self removeKeyFromBinding:key];
	}
}

- (void)runSettingsDialog;
{
	if (dialogWindow == nil) {
		[[NSBundle bundleForClass:[self class]] loadNibNamed:@"LLVisualStimulus"
                                        owner:self topLevelObjects:&topLevelObjects];
        [topLevelObjects retain];
		if (taskPrefix != nil) {
			[dialogWindow setTitle:[NSString stringWithFormat:@"%@ Visual Stimulus", taskPrefix]];
		}
	}
	[dialogWindow makeKeyAndOrderFront:self];
}

- (void)setAzimuthDeg:(float)azimuth;
{
	azimuthDeg = azimuth;
	[self updateFloatDefault:azimuthDeg key:LLAzimuthDegKey];
}

- (void)setAzimuthDeg:(float)aziDeg elevationDeg:(float)eleDeg;
{
	[self setAzimuthDeg:aziDeg];
	[self setElevationDeg:eleDeg];
}

- (void)setBackColor:(NSColor *)newColor;
{
	[newColor retain];
	[backColor release];
	backColor = newColor;
	if (prefix != nil) {
		[[NSUserDefaults standardUserDefaults] 
				setObject:[NSArchiver archivedDataWithRootObject:backColor] 
				forKey:[LLTextUtil capitalize:LLBackColorKey prefix:prefix]];
	}
}

- (void)setBackOnRed:(float)red green:(float)green blue:(float)blue;
{
	[self setBackColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0]];
}

- (void)setDirectionDeg:(float)newDirection;
{
	[self directSetDirectionDeg:newDirection];
	[self updateFloatDefault:directionDeg key:LLDirectionDegKey];
}

- (void)setDisplays:(LLDisplays *)newDisplays displayIndex:(long)index;
{
	[newDisplays retain];
	[displays release];
    displays = newDisplays;
	displayIndex = index;
}

- (void)setElevationDeg:(float)elevation;
{
	elevationDeg = elevation;
	[self updateFloatDefault:elevationDeg key:LLElevationDegKey];
}

- (void)setForeColor:(NSColor *)newColor;
{
	[newColor retain];
	[foreColor release];
	foreColor = newColor;
	if (prefix != nil) {
		[[NSUserDefaults standardUserDefaults] 
				setObject:[NSArchiver archivedDataWithRootObject:foreColor] 
				forKey:[LLTextUtil capitalize:LLForeColorKey prefix:prefix]];
	}
}

- (void)setFrame:(NSNumber *)frameNumber;
{
}

- (void)setForeOnRed:(float)red green:(float)green blue:(float)blue;
{
	[self setForeColor:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1.0]];
}

- (void)setKdlThetaDeg:(float)newKdltheta;
{
    kdlThetaDeg = newKdltheta;
	[self updateFloatDefault:kdlThetaDeg key:LLKdlThetaDegKey];
}

- (void)setKdlPhiDeg:(float)newKdlphi;
{
    kdlPhiDeg = newKdlphi;
	[self updateFloatDefault:kdlPhiDeg key:LLKdlPhiDegKey];
}

- (void)setRadiusDeg:(float)newRadius;
{
	radiusDeg = newRadius;
	[self updateFloatDefault:radiusDeg key:LLRadiusDegKey];
}

- (void)setState:(long)newState;
{
	state = newState;
}

- (long)state;
{
	return state;
}

- (void)unbindValues;
{
	NSEnumerator *enumerator;
	NSString *key;
	
	if (prefix != nil) {
		enumerator = [keys objectEnumerator];
		while ((key = [enumerator nextObject]) != nil) {
			[self unbind:key];
		}
		[self unbind:LLForeColorKey];
		[self unbind:LLBackColorKey];
		[prefix release];
		[taskPrefix release];
		prefix = taskPrefix = nil;
	}
}

- (void)updateFloatDefault:(float)value key:(NSString *)key;
{
	if (prefix != nil && !setUnderway) {
		setUnderway = YES;
		[[NSUserDefaults standardUserDefaults] setFloat:value forKey:[LLTextUtil capitalize:key prefix:prefix]];
		setUnderway = NO;
	}
}

- (void)updateIntegerDefault:(long)value key:(NSString *)key;
{
	if (prefix != nil && !setUnderway) {
		setUnderway = YES;
		[[NSUserDefaults standardUserDefaults] setInteger:value forKey:[LLTextUtil capitalize:key prefix:prefix]];
		setUnderway = NO;
	}
}

@end
