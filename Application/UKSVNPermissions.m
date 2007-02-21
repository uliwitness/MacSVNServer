//
//  UKSVNPermissions.m
//  SVNBrowser
//
//  Created by Uli Kusterer on 22.07.06.
//  Copyright 2006 Uli Kusterer. All rights reserved.
//

#import "UKSVNPermissions.h"


@implementation UKSVNPermissions

-(id)	initWithContentsOfFile: (NSString*)filePath
{
	self = [super init];
	if( self )
	{
		parsedPermissions = [[NSMutableDictionary alloc] init];
		
		NSString*				str = [NSString stringWithContentsOfFile: filePath encoding: NSUTF8StringEncoding error: nil];
		NSArray*				lines = [str componentsSeparatedByString: @"\n"];
		NSEnumerator*			enny = [lines objectEnumerator];
		NSString*				currLine = nil;
		NSMutableDictionary*	currGroup = nil;
		NSCharacterSet*			cs = [NSCharacterSet characterSetWithCharactersInString: @"\t \n[]"];
		NSCharacterSet*			wcs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		
		while( (currLine = [enny nextObject]) )
		{
			if( [currLine length] < 3 )
				continue;
			
			if( [currLine characterAtIndex: 0] == '[' )		// Found path or group header:
			{
				currGroup = [NSMutableDictionary dictionary];
				NSString*		currGroupKey = [currLine stringByTrimmingCharactersInSet: cs];
				currGroupKey = [self unifyRepositoryPath: currGroupKey];

				[parsedPermissions setObject: currGroup forKey: currGroupKey];
			}
			else if( currGroup != nil )
			{
				NSArray*	halves = [currLine componentsSeparatedByString: @"="];
				id			value = [[halves objectAtIndex: 1] stringByTrimmingCharactersInSet: wcs];
				if( [value rangeOfString: @","].location != NSNotFound )
				{
					NSArray*		listItems = [value componentsSeparatedByString: @","];
					value = [NSMutableArray array];
					NSEnumerator*	listItemEnny = [listItems objectEnumerator];
					NSString*		currItem = nil;
					
					while( (currItem = [listItemEnny nextObject]) )
					{
						[value addObject: [currItem stringByTrimmingCharactersInSet: wcs]];
					}
				}
				NSString*	keyStr = [[halves objectAtIndex: 0] stringByTrimmingCharactersInSet: wcs];
				[currGroup setObject: value forKey: keyStr];
			}
			else
				NSLog( @"UKSVNPermissions initWithContentsOfFile: Ignoring line \"%@\"", currLine );
		}
		
		//NSLog(@"\n%@\n", parsedPermissions );
	}
	
	return self;
}


-(void)	dealloc
{
	[parsedPermissions release];
	
	[super dealloc];
}


-(NSString*)	unifyRepositoryPath: (NSString*)pathInRepository
{
	if( [pathInRepository length] > 1 && [pathInRepository characterAtIndex: [pathInRepository length] -1] == '/' )
		pathInRepository = [pathInRepository substringWithRange: NSMakeRange( 0, [pathInRepository length] -1)];
	return pathInRepository;
}


-(NSMutableDictionary*)	inheritedPermissionsAtPath: (NSString*)pathInRepository
{
	pathInRepository = [self unifyRepositoryPath: pathInRepository];
	
	NSMutableDictionary*	permissionsDict = nil;
	while( permissionsDict == nil || [permissionsDict count] == 0 )		// Search up the chain until we find a path from which we inherit permissions.
	{
		permissionsDict = [parsedPermissions objectForKey: pathInRepository];
		if( permissionsDict == nil || [permissionsDict count] == 0 )
		{
			if( [pathInRepository length] == 0 )
				return nil;	// Shouldn't happen, but we don't want to endlessly loop on invalid data.
			pathInRepository = [pathInRepository stringByDeletingLastPathComponent];
		}
	}
	return permissionsDict;
}


-(void)	removePermissionsAtPath: (NSString*)pathInRepository forUser: (NSString*)userName
{
	pathInRepository = [self unifyRepositoryPath: pathInRepository];
	
	NSMutableDictionary*	permissionsDict = [parsedPermissions objectForKey: pathInRepository];
	if( !permissionsDict )	// No permissions set at this path.
		return;				// Nothing to do.
	
	[permissionsDict removeObjectForKey: userName];	// Delete permissions for this user. This may cause it to inherit another set of permissions.

	if( [permissionsDict count] == 0 )
		[parsedPermissions removeObjectForKey: pathInRepository];
}


-(NSArray*)	usersHavingPermissionsAtPath: (NSString*)pathInRepository
{
	NSDictionary*	permissionsDict = [self inheritedPermissionsAtPath: pathInRepository];	// This unifies the path as needed.
	return [permissionsDict allKeys];
}


-(NSDictionary*)	usersAndPermissionsAtPath: (NSString*)pathInRepository
{
	NSDictionary*	permissionsDict = [self inheritedPermissionsAtPath: pathInRepository];	// This unifies the path as needed.
	return [[permissionsDict mutableCopy] autorelease];
}


-(int)	permissionsAtPath: (NSString*)pathInRepository forUser: (NSString*)userName
{
	NSDictionary*	permissionsDict = [self inheritedPermissionsAtPath: pathInRepository];	// This unifies the path as needed.
	NSString*		str = [permissionsDict objectForKey: userName];
	int				perms = 0;
	if( [str rangeOfString: @"r"].location != NSNotFound )
		perms |= SVN_PERMISSION_READ;
	if( [str rangeOfString: @"w"].location != NSNotFound )
		perms |= SVN_PERMISSION_WRITE;
	
	return perms;
}


-(void)	setPermissions: (int)permissions atPath: (NSString*)pathInRepository forUser: (NSString*)userName
{
	pathInRepository = [self unifyRepositoryPath: pathInRepository];	// Not using inheritedPermissionsAtPath:, so unify the path manually.
	
	NSMutableDictionary*	permissionsDict = [parsedPermissions objectForKey: pathInRepository];
	if( !permissionsDict )	// Had inherited permissions so far? Create a permissions dictionary for it:
	{
		permissionsDict = [NSMutableDictionary dictionary];
		[parsedPermissions setObject: permissionsDict forKey: pathInRepository];
	}
	
	// Now assign permissions string:
	if( (permissions & SVN_PERMISSION_BOTH) == SVN_PERMISSION_BOTH )
		[permissionsDict setObject: @"rw" forKey: userName];
	else if( (permissions & SVN_PERMISSION_READ) == SVN_PERMISSION_READ )
		[permissionsDict setObject: @"r" forKey: userName];
	else if( (permissions & SVN_PERMISSION_WRITE) == SVN_PERMISSION_WRITE )
		[permissionsDict setObject: @"w" forKey: userName];
	else
		[permissionsDict setObject: @"" forKey: userName];
}


-(NSArray*)	usersInGroup: (NSString*)groupName
{
	NSMutableDictionary*	groupsDict = [parsedPermissions objectForKey: @"groups"];
	NSMutableArray*			groupUsers = [groupsDict objectForKey: groupName];
	
	return groupUsers;
}


-(NSArray*)	groups
{
	NSMutableDictionary*	groupsDict = [parsedPermissions objectForKey: @"groups"];
	
	return [groupsDict allKeys];
}


-(void)	addUser: (NSString*)userName toGroup: (NSString*)groupName
{
	// Find the "groups" dictionary or add one if there are no groups yet:
	NSMutableDictionary*	groupsDict = [parsedPermissions objectForKey: @"groups"];
	if( !groupsDict )
	{
		groupsDict = [NSMutableDictionary dictionary];
		[parsedPermissions setObject: groupsDict forKey: @"groups"];
	}
	
	// Get the group's list of users, or create a new group if there's none yet:
	NSMutableArray*			groupUsers = [groupsDict objectForKey: groupName];
	if( !groupUsers )
	{
		groupUsers = [NSMutableArray array];
		[groupsDict setObject: groupUsers forKey: groupName];
	}

	// Add this user to the group's list of users:
	[groupUsers addObject: userName];
}


-(void)	removeUser: (NSString*)userName fromGroup: (NSString*)groupName
{
	NSMutableDictionary*	groupsDict = [parsedPermissions objectForKey: @"groups"];
	if( !groupsDict )
		return;	// Nothing to do, if we have no groups.
	
	// Get the group's list of users, or create a new group if there's none yet:
	NSMutableArray*			groupUsers = [groupsDict objectForKey: groupName];
	if( groupUsers )
	{
		[groupUsers removeObject: userName];
	
		if( [groupUsers count] == 0 )
			[groupsDict removeObjectForKey: groupName];	// Delete group if it contains no items anymore.
	}
	
	if( [groupsDict count] == 0 )
		[parsedPermissions removeObjectForKey: @"groups"];	// Delete groups dictionary if it contains no groups anymore.
}


-(BOOL)		isEmpty
{
	if( [parsedPermissions count] <= 0 )
		return YES;
	else if( [parsedPermissions count] == 1 )	// Only groups?
	{
		NSDictionary	*groupsDict = [parsedPermissions objectForKey: @"groups"];
		if( !groupsDict || [groupsDict count] == 0 )
			return YES;
	}
	
	return NO;
}


-(BOOL)		writeToFile: (NSString*)permissionsFilePath atomically: (BOOL)yorn
{
	// Write out all groups first:
	NSMutableString*		fileData = [NSMutableString stringWithString: @"[groups]"];
	NSMutableDictionary*	groupsDict = [parsedPermissions objectForKey: @"groups"];
	NSEnumerator*			enny = [groupsDict keyEnumerator];
	NSString*				currGroup = nil;
	
	while( (currGroup = [enny nextObject]) )
	{
		[fileData appendString: @"\n"];
		[fileData appendString: currGroup];
		[fileData appendString: @" = "];
		
		NSEnumerator*		memberEnny = [[groupsDict objectForKey: currGroup] objectEnumerator];
		NSString*			currMember = nil;
		BOOL				first = YES;
		while( (currMember = [memberEnny nextObject]) )
		{
			if( !first )
				[fileData appendString: @", "];
			else
				first = NO;
			
			[fileData appendString: currMember];
		}
	}
	
	// Now write all paths:
	enny = [parsedPermissions keyEnumerator];
	while( (currGroup = [enny nextObject]) )
	{
		if( [currGroup isEqualToString: @"groups"] )	// Already did that one, skip!
			continue;
		
		NSDictionary*	users = [parsedPermissions objectForKey: currGroup];
		if( [users count] > 0 )
		{
			NSEnumerator*	userEnny = [users keyEnumerator];
			NSString*		currUser = nil;
			
			[fileData appendString: @"\n\n["];
			[fileData appendString: currGroup];
			[fileData appendString: @"]"];
			
			while( (currUser = [userEnny nextObject]) )
			{
				[fileData appendString: @"\n"];
				[fileData appendString: currUser];
				[fileData appendString: @" = "];
				[fileData appendString: [users objectForKey: currUser]];
			}
		}
	}
	
	[fileData appendString: @"\n"];	// To make the Unix geeks happy.
	
	return [fileData writeToFile: permissionsFilePath atomically: yorn];
}


@end
