//
//  UKSVNBrowser.h
//  SVNBrowser
//
//  Created by Uli Kusterer on 14.10.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKNibOwner.h"

@class SCAuthorizationUI;
@class UKFilePathView;
@class UKSVNPermissions;

@interface UKSVNBrowser : UKNibOwner
{
	NSMutableArray			*	repository;
	NSMutableDictionary		*	repositoryRoot;
	NSString				*	repositoryURL;
	BOOL						showTrunkOnly;
	SCAuthorizationUI		*	authUI;
	IBOutlet NSOutlineView	*	listView;
	IBOutlet NSTextField	*	projectNameField;
	IBOutlet UKFilePathView	*	projectPathField;
	IBOutlet NSTableView	*	permissionsView;
	BOOL						updateUIOnFileChange;
	UKSVNPermissions		*	permissionsDB;
}

-(id)				initWithPermissionsFile: (UKSVNPermissions*)perms;

-(void)				showSVNBrowserWindow: (id)sender;

-(NSString*)		repositoryURL;
-(void)				setRepositoryURL: (NSString *) theRepositoryURL;

-(NSMutableArray*)	repository;
-(void)				setRepository: (NSArray*) theRepository;

-(void)				reloadRepository: (id)sender;
-(BOOL)				reloadRepositoryNoAuth;
-(void)				reloadRepositoryAuthorized: (id)sender;

-(void)				markProjectFilesInArray: (NSMutableArray*)arr forOwner: (NSMutableDictionary*)owner;

-(NSMutableArray*)	filesAtRepositoryPath: (NSString*)path subfiles: (BOOL)oneLevelDeeper;
-(NSMutableArray*)	filesAtRepositoryPath: (NSString*)path subfiles: (BOOL)oneLevelDeeper authenticate: (BOOL)doAuth;
-(void)				loadSubitemsForItem: (NSMutableDictionary*)currItem;

-(void)				addNewPermissionsEntry: (id)sender;
-(void)				removePermissionsEntry: (id)sender;

-(void)				addProject: (id)sender;
-(void)				delete: (id)sender;
-(void)				refreshNewProjectName: (id)sender;

-(NSString*)		subversionToolPath;

-(void)				loadPermissionsStuff;
-(void)				repositoryListChanged;

@end


#define PERMISSIONS_DB_FILE	@"/Library/Application Support/MAS/svn-access-file"
