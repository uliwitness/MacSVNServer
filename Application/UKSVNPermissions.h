//
//  UKSVNPermissions.h
//  SVNBrowser
//
//  Created by Uli Kusterer on 22.07.06.
//  Copyright 2006 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define		SVN_PERMISSION_READ		(1 << 0)
#define		SVN_PERMISSION_WRITE	(1 << 1)
#define		SVN_PERMISSION_BOTH		(SVN_PERMISSION_READ | SVN_PERMISSION_WRITE)


@interface UKSVNPermissions : NSObject
{
	NSMutableDictionary*	parsedPermissions;
}

-(id)				initWithContentsOfFile: (NSString*)filePath;

// Manage permissions:
-(NSArray*)			usersHavingPermissionsAtPath: (NSString*)pathInRepository;
-(NSDictionary*)	usersAndPermissionsAtPath: (NSString*)pathInRepository;

-(int)				permissionsAtPath: (NSString*)pathInRepository forUser: (NSString*)userName;
-(void)				setPermissions: (int)permissions atPath: (NSString*)pathInRepository forUser: (NSString*)userName;
-(void)				removePermissionsAtPath: (NSString*)pathInRepository forUser: (NSString*)userName;

// Manage groups:
-(NSArray*)			groups;
-(NSArray*)			usersInGroup: (NSString*)groupName;
-(void)				addUser: (NSString*)userName toGroup: (NSString*)groupName;			// Creates group if there is none.
-(void)				removeUser: (NSString*)userName fromGroup: (NSString*)groupName;	// Deletes group if last member is removed.

-(BOOL)				isEmpty;

// Save changes to disk:
-(BOOL)				writeToFile: (NSString*)permissionsFilePath atomically: (BOOL)yorn;

// Private:
-(NSMutableDictionary*)	inheritedPermissionsAtPath: (NSString*)pathInRepository;	// Used by permissions stuff to find the right dictionary for READING.
-(NSString*)			unifyRepositoryPath: (NSString*)pathInRepository;

@end
