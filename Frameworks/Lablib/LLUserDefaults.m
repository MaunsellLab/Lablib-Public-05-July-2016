//
//  LLUserDefaults.m
//  Lablib
//
//  Created by John Maunsell on 1/4/05.
//  Copyright 2005. All rights reserved.
//

#import "LLUserDefaults.h"


@implementation LLUserDefaults

- (void)addSuiteNamed:(NSString *)suiteName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] addSuiteNamed:suiteName];
	[defaultsLock unlock];
}

- (NSArray *)arrayForKey:(NSString *)defaultName;
{
	NSArray *array;
	
	[defaultsLock lock];
	array = [[NSUserDefaults standardUserDefaults] arrayForKey:defaultName];
	[defaultsLock unlock];
	return array;
}

- (BOOL)boolForKey:(NSString *)defaultName;
{
	BOOL value;
	
	[defaultsLock lock];
	value = [[NSUserDefaults standardUserDefaults] boolForKey:defaultName];
	[defaultsLock unlock];
	return value;
}

- (NSData *)dataForKey:(NSString *)defaultName;
{
	NSData *data;
	
	[defaultsLock lock];
	data = [[NSUserDefaults standardUserDefaults] dataForKey:defaultName];
	[defaultsLock unlock];
	return data;
}

- (void)dealloc;
{
	[defaultsLock release];
	[super dealloc];
}

- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
{
	NSDictionary *dictionary;
	
	[defaultsLock lock];
	dictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:defaultName];
	[defaultsLock unlock];
	return dictionary;
}

- (NSDictionary *)dictionaryRepresentation;
{
	NSDictionary *dictionary;
	
	[defaultsLock lock];
	dictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
	[defaultsLock unlock];
	return dictionary;
}

- (float)floatForKey:(NSString *)defaultName;
{
	float value;
	
	[defaultsLock lock];
	value = [[NSUserDefaults standardUserDefaults] floatForKey:defaultName];
	[defaultsLock unlock];
	return value;
}

- (id)init;
{
	if ((self = [super init]) != nil) {
		defaultsLock = [[NSLock alloc] init];
	}
	return self;
}

- (id)initWithUser:(NSString *)username;
{
	if ((self = [super initWithUser:username]) != nil) {
		defaultsLock = [[NSLock alloc] init];
	}
	return self;
}

- (NSInteger)integerForKey:(NSString *)defaultName;
{
	int value;
	
	[defaultsLock lock];
	value = [[NSUserDefaults standardUserDefaults] integerForKey:defaultName];
	[defaultsLock unlock];
	return value;
}

- (id)objectForKey:(NSString *)defaultName;
{
	id object;
	
	[defaultsLock lock];
	object = [[NSUserDefaults standardUserDefaults] objectForKey:defaultName];
	[defaultsLock unlock];
	return object;
}

- (BOOL)objectIsForcedForKey:(NSString *)key;
{
	BOOL result;
	
	[defaultsLock lock];
	result = [[NSUserDefaults standardUserDefaults] objectIsForcedForKey:key];
	[defaultsLock unlock];
	return result;
}

- (BOOL)objectIsForcedForKey:(NSString *)key inDomain:(NSString *)domain;
{
	BOOL result;
	
	[defaultsLock lock];
	result = [[NSUserDefaults standardUserDefaults] objectIsForcedForKey:key inDomain:domain];
	[defaultsLock unlock];
	return result;
}

- (NSDictionary *)persistentDomainForName:(NSString *)domainName;
{
	NSDictionary *domain;
	
	[defaultsLock lock];
	domain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:domainName];
	[defaultsLock unlock];
	return domain;
}

- (NSArray *)persistentDomainNames;
{
	NSArray *names;
	
	[defaultsLock lock];
	names = [[NSUserDefaults standardUserDefaults] persistentDomainNames];
	[defaultsLock unlock];
	return names;
}

- (void)registerDefaults:(NSDictionary *)dictionary;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
	[defaultsLock unlock];
}

- (void)removeObjectForKey:(NSString *)defaultName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:defaultName];
	[defaultsLock unlock];
}

- (void)removePersistentDomainForName:(NSString *)domainName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:domainName];
	[defaultsLock unlock];
}

- (void)removeSuiteNamed:(NSString *)suiteName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] removeSuiteNamed:suiteName];
	[defaultsLock unlock];
}

- (void)removeVolatileDomainForName:(NSString *)domainName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] removeVolatileDomainForName:domainName];
	[defaultsLock unlock];
}


- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] setBool:value forKey:defaultName];
	[defaultsLock unlock];
}


- (void)setFloat:(float)value forKey:(NSString *)defaultName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] setFloat:value forKey:defaultName];
	[defaultsLock unlock];
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] setInteger:value forKey:defaultName];
	[defaultsLock unlock];
}

- (void)setObject:(id)value forKey:(NSString *)defaultName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] setObject:value forKey:defaultName];
	[defaultsLock unlock];
}

- (void)setPersistentDomain:(NSDictionary *)domain forName:(NSString *)domainName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:domain forName:domainName];
	[defaultsLock unlock];
}

- (void)setVolatileDomain:(NSDictionary *)domain forName:(NSString *)domainName;
{
	[defaultsLock lock];
	[[NSUserDefaults standardUserDefaults] setVolatileDomain:domain forName:domainName];
	[defaultsLock unlock];
}

- (NSArray *)stringArrayForKey:(NSString *)defaultName;
{
	NSArray *array; 
	
	[defaultsLock lock];
	array = [[NSUserDefaults standardUserDefaults] stringArrayForKey:defaultName];
	[defaultsLock unlock];
	return array;
}

- (NSString *)stringForKey:(NSString *)defaultName;
{
	NSString *string; 
	
	[defaultsLock lock];
	string = [[NSUserDefaults standardUserDefaults] stringForKey:defaultName];
	[defaultsLock unlock];
	return string;
}

- (BOOL)synchronize;
{
	BOOL result;
	
	[defaultsLock lock];
	result = [[NSUserDefaults standardUserDefaults] synchronize];
	[defaultsLock unlock];
	return result;
}

- (NSDictionary *)volatileDomainForName:(NSString *)domainName;
{
	NSDictionary *domain; 
	
	[defaultsLock lock];
	domain = [[NSUserDefaults standardUserDefaults] volatileDomainForName:domainName];
	[defaultsLock unlock];
	return domain;
}

- (NSArray *)volatileDomainNames;
{
	NSArray *names; 
	
	[defaultsLock lock];
	names = [[NSUserDefaults standardUserDefaults] volatileDomainNames];
	[defaultsLock unlock];
	return names;
}

@end