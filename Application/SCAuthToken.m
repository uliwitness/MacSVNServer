//
//  SCAuthToken.m
//  SCPlugin
//
//  Created by Christopher Pavicich on Thu Jun 10 2004.
//  Copyright (c) 2004 Christopher Pavicich. All rights reserved.
//

#import "SCAuthToken.h"

@implementation SCAuthToken

-(id)	init
{
	self = [super init];
	if( self )
	{
		// Try fetching last used user name from prefs:
		NSUserDefaults*	ud = [NSUserDefaults standardUserDefaults];
		username = [[ud objectForKey: @"SCAuthTokenLastUsername"] retain];
	}
	
	return self;
}

-(void)	dealloc
{
	[username release];
	[password release];
	
	[super dealloc];
}

- (NSString *) username
{
	return username;
}

- (void) setUsername:(NSString *)value
{
	if( username != value )
	{
		[username release];
		username = [value retain];
		
		// Remember this name in prefs:
		NSUserDefaults*	ud = [NSUserDefaults standardUserDefaults];
		[ud setObject: username forKey: @"SCAuthTokenLastUsername"];
	}
}

- (NSString *) password
{
	return password;
}

- (void) setPassword:(NSString *)value
{
    [password release];
    password = [value retain];
}

@end
