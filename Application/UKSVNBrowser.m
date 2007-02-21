//
//  UKSVNBrowser.m
//  SVNBrowser
//
//  Created by Uli Kusterer on 14.10.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import "UKSVNBrowser.h"
#import "NSFileManager+ExistingFilesAtPaths.h"
#import "NSString+ArrayWithRanges.h"
#import "SCAuthorizationUI.h"
#import "UKFilePathView.h"
#import "UKSVNPermissions.h"
//#import "UKSubversionRepository.h"
#import "UKKQueue.h"
#import "MASAppDelegate.h"
#include <Carbon/Carbon.h>


@implementation UKSVNBrowser

-(id)	init
{
	return [self initWithPermissionsFile: nil];
}

-(id)	initWithPermissionsFile: (UKSVNPermissions*)perms
{
	self = [super init];
	if( self )
	{
		updateUIOnFileChange = YES;
		repositoryURL = [[[NSUserDefaults standardUserDefaults] objectForKey: @"SVNBrowserRepositoryURL"] retain];
		if( !repositoryURL )
			repositoryURL = [@"http://localhost:8800/svn/" retain];		showTrunkOnly = YES;
		authUI = [[SCAuthorizationUI alloc] init];
		if( perms )
			permissionsDB = [perms retain];
		else
			[self loadPermissionsStuff];
		[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: NSApp];
		
		//[UKSubversionRepository checkOutCurrentRevisionOfPath: @"/" atURLString: repositoryURL];
	}
	
	return self;
}

-(void)	dealloc
{
	[repositoryRoot release];
	repositoryRoot = nil;
	[permissionsDB release];
	permissionsDB = nil;
	[repository release];
	repository = nil;
	[repositoryURL release];
	repositoryURL = nil;
	[authUI release];
	authUI = nil;
	
	[super dealloc];
}


-(void)	applicationWillTerminate: (NSNotification*)notif
{
	[permissionsDB writeToFile: PERMISSIONS_DB_FILE atomically: YES];
	[[NSUserDefaults standardUserDefaults] setObject: repositoryURL forKey: @"SVNBrowserRepositoryURL"];
}


-(void)	awakeFromNib
{
	if( projectPathField )
	{
		[listView setDoubleAction: @selector(listRowDoubleClicked:)];
		
		[projectPathField setCanChooseFiles: NO];
		[projectPathField setCanChooseDirectories: YES];
		[projectPathField setTreatsFilePackagesAsDirectories: YES];
		[projectPathField setAction: @selector(refreshNewProjectName:)];
		[self performSelector: @selector(initialLoadRepository:) withObject: nil afterDelay: 1.0];	// Let's hope by that time our window is up.
	}
	
	[[UKKQueue sharedFileWatcher] addPath: REPOSITORY_FOLDER_PATH "db/"];
	[[UKKQueue sharedFileWatcher] addPath: PERMISSIONS_FILE_PATH];
	[[UKKQueue sharedFileWatcher] setDelegate: self];
}


-(void) watcher: (id<UKFileWatcher>)kq receivedNotification: (NSString*)nm forPath: (NSString*)fpath
{
	if( [[listView window] isVisible] && updateUIOnFileChange )
		[self reloadRepositoryAuthorized: self];
}


-(void)	showSVNBrowserWindow: (id)sender
{
	[self reloadRepositoryAuthorized: sender];
	[[listView window] makeKeyAndOrderFront: sender];
}


-(void)	loadPermissionsStuff
{
	[permissionsDB release];
	permissionsDB = [[UKSVNPermissions alloc] initWithContentsOfFile: PERMISSIONS_DB_FILE];
}


-(void)	listRowDoubleClicked: (id)sender
{
	NSDictionary*	theItem = [listView itemAtRow: [listView clickedRow]];
	
	NSLog( @"double clicked item %@", theItem );
}


-(void)	outlineViewSelectionDidChange:(NSNotification *)notification
{
	[permissionsView reloadData];
}


-(int)	numberOfRowsInTableView:(NSTableView *)tableView;
{
	int				selRow = [listView selectedRow];
	if( selRow == -1 )
		return 0;
	
	NSDictionary*	theItem = [listView itemAtRow: selRow];
	
	return [[[theItem objectForKey: @"userPermissions"] allKeys] count];
}


-(id)	tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
{
	int				selRow = [listView selectedRow];
	if( selRow == -1 )
		return nil;
	
	NSDictionary*	theItem = [listView itemAtRow: selRow];
	NSString*		colName = [tableColumn identifier];
	NSDictionary*	permDict = [theItem objectForKey: @"userPermissions"];
	NSString*		currKey = [[permDict allKeys] objectAtIndex: row];
	
	if( [colName isEqualToString: @"userName"] )
	{
		if( [currKey isEqualToString: @"*"] )
			return @"all users";
		else if( [currKey characterAtIndex: 0] == '@' )
			return [[currKey substringWithRange: NSMakeRange( 1, [currKey length] -1)] stringByAppendingString: @" group"];
		else
			return currKey;
	}
	else
	{
		NSString*	permStr = [permDict objectForKey: currKey];
		if( [colName isEqualToString: @"read"] )
			return [NSNumber numberWithBool: ([permStr rangeOfString: @"r"].location != NSNotFound)];
		else if( [colName isEqualToString: @"write"] )
			return [NSNumber numberWithBool: ([permStr rangeOfString: @"w"].location != NSNotFound)];
	}
	
	return @"?";
}


-(void)	tableView: (NSTableView*)tableView setObjectValue: (id)object forTableColumn: (NSTableColumn*)tableColumn row: (int)row
{
	int				selRow = [listView selectedRow];
	if( selRow == -1 )
		return;
	
	NSDictionary*			theItem = [listView itemAtRow: selRow];
	NSString*				colName = [tableColumn identifier];
	NSMutableDictionary*	permDict = [theItem objectForKey: @"userPermissions"];
	NSString*				currKey = [[permDict allKeys] objectAtIndex: row];
	NSString*				permStr = nil;
	
	if( [colName isEqualToString: @"userName"] )
	{
		NSString*		newUserName = object;
		if( [newUserName isEqualToString: @"all users"] )
			newUserName = @"*";
		else if( [newUserName hasSuffix: @" group"] )
			newUserName = [@"@" stringByAppendingString: [currKey substringWithRange: NSMakeRange( 0, [newUserName length] -[@" group" length])]];
		if( ![newUserName isEqualToString: currKey] )
		{
			permStr = [permDict objectForKey: currKey];
			[permDict setObject: permStr forKey: newUserName];
			[permDict removeObjectForKey: currKey];
			
			int newPerms = ([permStr rangeOfString: @"r"].location != NSNotFound) ? SVN_PERMISSION_READ : 0;
			newPerms |= ([permStr rangeOfString: @"w"].location != NSNotFound)  ? SVN_PERMISSION_WRITE : 0;
			[permissionsDB removePermissionsAtPath: [theItem objectForKey: @"path"] forUser: currKey];
			[permissionsDB setPermissions: newPerms atPath: [theItem objectForKey: @"path"] forUser: newUserName];
			updateUIOnFileChange = NO;
			[permissionsDB writeToFile: PERMISSIONS_DB_FILE atomically: YES];
			updateUIOnFileChange = YES;
			
			[permissionsView reloadData];
		}
	}
	else
	{
		NSString*	permStr = [permDict objectForKey: currKey];
		char		rdPerm = ([permStr rangeOfString: @"r"].location != NSNotFound) ? 'r' : ' ';
		char		wrPerm = ([permStr rangeOfString: @"w"].location != NSNotFound) ? 'w' : ' ';
		if( [colName isEqualToString: @"read"] )
			rdPerm = [object boolValue] ? 'r' : ' ';
		else if( [colName isEqualToString: @"write"] )
			wrPerm = [object boolValue] ? 'w' : ' ';
		
		[permDict setObject: [NSString stringWithFormat: @"%c%c", rdPerm, wrPerm] forKey: currKey];
		
		int newPerms = (rdPerm == 'r') ? SVN_PERMISSION_READ : 0;
		newPerms |= (wrPerm == 'w')  ? SVN_PERMISSION_WRITE : 0;
		[permissionsDB setPermissions: newPerms atPath: [theItem objectForKey: @"path"] forUser: currKey];
		updateUIOnFileChange = NO;
		[permissionsDB writeToFile: PERMISSIONS_DB_FILE atomically: YES];
		updateUIOnFileChange = YES;
		
		[permissionsView reloadData];
	}
}


-(void)	addNewPermissionsEntry: (id)sender
{
	int				selRow = [listView selectedRow];
	if( selRow == -1 )
		return;
	
	NSDictionary*			theItem = [listView itemAtRow: selRow];
	NSMutableDictionary*	permDict = [theItem objectForKey: @"userPermissions"];
	NSString*				currKey = @"put user name here";
	[permDict setObject: @"" forKey: currKey];

	[permissionsDB setPermissions: 0 atPath: [theItem objectForKey: @"path"] forUser: currKey];
	updateUIOnFileChange = NO;
	[permissionsDB writeToFile: PERMISSIONS_DB_FILE atomically: YES];
	updateUIOnFileChange = YES;
	
	[permissionsView reloadData];
}


-(void)	removePermissionsEntry: (id)sender
{
	int				selRow = [listView selectedRow];
	int				selRow2 = [permissionsView selectedRow];
	if( selRow == -1 || selRow2 == -1  )
		return;
	
	NSDictionary*			theItem = [listView itemAtRow: selRow];
	NSMutableDictionary*	permDict = [theItem objectForKey: @"userPermissions"];
	NSString*				currKey = [[permDict allKeys] objectAtIndex: selRow2];
	[permDict removeObjectForKey: currKey];

	updateUIOnFileChange = YES;
	[permissionsDB removePermissionsAtPath: [theItem objectForKey: @"path"] forUser: currKey];
	updateUIOnFileChange = NO;
	
	[permissionsView reloadData];
}


-(void)	initialLoadRepository: (id)sender
{
	//if( ![self reloadRepositoryNoAuth] )
	{
		[authUI setController: self];
		[authUI setAuthorizationSelector: @selector(reloadRepositoryAuthorized:)];
		[authUI showForWindow: [listView window]];
	}
}

-(void)	reloadRepository: (id)sender
{
	[repository autorelease];
	repository = [[self filesAtRepositoryPath: @"/" subfiles: YES] retain];
	
	[self repositoryListChanged];
	[listView reloadData];
}


-(void)	repositoryListChanged
{
	if( !repositoryRoot )
	{
	NSImage*		diskIcon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode( kGenericFileServerIcon )];
	[diskIcon setSize: NSMakeSize(16,16)];
	NSDictionary*	usersAndPerms = [permissionsDB usersAndPermissionsAtPath: @"/"];
	repositoryRoot = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
									@"/", @"name",
									@"/", @"path",
									@"/", @"displayName",
									repository, @"contents",
									@"", @"date",
									@"", @"size",
									@"- unknown -", @"user",
									@"", @"revision",
									diskIcon, @"icon",
									usersAndPerms, @"userPermissions",
								nil] retain];
	}
	else
	{
		[repositoryRoot setObject: repository forKey: @"contents"];
	}
}


-(BOOL)	reloadRepositoryNoAuth
{
	NSMutableArray*	arr = [self filesAtRepositoryPath: @"/" subfiles: YES authenticate: NO];
	if( arr )
	{
		[repository autorelease];
		repository = [arr retain];
		
		[self repositoryListChanged];
		[listView reloadData];
	}
	
	return( arr != nil );
}


-(void)	reloadRepositoryAuthorized: (id)sender
{
	NSMutableArray*	arr = [self filesAtRepositoryPath: @"/" subfiles: YES authenticate: YES];
	if( arr )
	{
		[repository autorelease];
		repository = [arr retain];
		
		[self repositoryListChanged];
		[listView reloadData];
	}
}


-(void)	markProjectFilesInArray: (NSMutableArray*)arr forOwner: (NSMutableDictionary*)owner
{
	if( !arr )
		return;
	
	NSEnumerator*			enny = [arr objectEnumerator];
	NSMutableDictionary*	currFile;
	BOOL					haveBranches = NO;
	BOOL					haveTags = NO;
	id						trunkItem = nil;
	
	while( (currFile = [enny nextObject]) )
	{
		NSString*	nm = [currFile objectForKey: @"name"];
		BOOL		isFolder = [nm characterAtIndex: [nm length] -1] == '/';
		
		if( isFolder )
		{
			if( [nm isEqualToString: @"branches/"] )
				haveBranches = YES;
			else if( [nm isEqualToString: @"tags/"] )
				haveTags = YES;
			else if( [nm isEqualToString: @"trunk/"] )
				trunkItem = currFile;
			
			[self markProjectFilesInArray: [currFile objectForKey: @"contents"] forOwner: owner];
		}
	}
	
	if( owner != nil && haveBranches && haveTags && trunkItem )
		[owner setObject: trunkItem forKey: @"projectTrunk"];
}


-(void)	delete: (id)sender
{
	[authUI setController: self];
	[authUI setAuthorizationSelector: @selector(deleteAuthorized:)];
	[authUI showForWindow: [listView window]];
}


-(void)	deleteAuthorized: (SCAuthToken*)token
{
	int						selRow = [listView selectedRow];
	NSMutableDictionary*	dict = nil;
	NSString*				path = nil;
	
	if( selRow == -1 )
		return;
		
	dict = [listView itemAtRow: selRow];
	path = [dict objectForKey: @"path"];
	
	NSString*			exePath = [self subversionToolPath];
	NSArray*			args = [NSArray arrayWithObjects: @"delete",
											[repositoryURL stringByAppendingString: path],
											@"--message", [@"Deleted " stringByAppendingString: [path lastPathComponent]],
											@"--username", [token username],
											@"--password", [token password],
											@"--non-interactive",
											nil];
	NSTask*				task = [[[NSTask alloc] init] autorelease];
	NSPipe*				thePipe = [NSPipe pipe];
	[task setStandardOutput: thePipe];
	[task setArguments: args];
	[task setLaunchPath: exePath];
	[task launch];
	NSData*				data = [[thePipe fileHandleForReading] readDataToEndOfFile];
	NSLog( @"%@", [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease] );
	
	// Update display:
	[self reloadRepository: self];
	[listView reloadData];
}


-(void)	addProject: (id)sender
{
	[authUI setController: self];
	[authUI setAuthorizationSelector: @selector(addAuthorizedProject:)];
	[authUI showForWindow: [listView window]];
}


-(void)	addAuthorizedProject: (SCAuthToken*)token
{
	// Find out where to create it:
	int						selRow = [listView selectedRow];
	NSMutableDictionary*	dict = nil;
	NSString*				path = nil;
	NSString*				projectName = [projectNameField stringValue];
	NSString*				localProjectFiles = [projectPathField stringValue];
	NSFileManager*			fm = [NSFileManager defaultManager];
	
	if( selRow == -1 )
	{
		if( [projectName length] == 0 )
			path = @"";		// Create at root.
		else
			path = projectName;
	}
	else
	{
		dict = [listView itemAtRow: selRow];
		path = [[dict objectForKey: @"path"] stringByAppendingString: projectName];
	}
	
	// Create a template for this project:
	NSString*				localPath = [NSTemporaryDirectory() stringByAppendingPathComponent: @"TestProject/"];
	NSString*				localTrunkPath = [localPath stringByAppendingPathComponent: @"trunk/"];
	
	[fm createDirectoryAtPath: localPath attributes: nil];
	[fm createDirectoryAtPath: [localPath stringByAppendingPathComponent: @"branches/"] attributes: nil];
	[fm createDirectoryAtPath: [localPath stringByAppendingPathComponent: @"tags/"] attributes: nil];
	
	if( [localProjectFiles length] != 0 )
	{
		NSString* localDestPath = [localPath stringByAppendingPathComponent: [localProjectFiles lastPathComponent]];
		if( ![fm copyPath: localProjectFiles toPath: localDestPath handler: nil] )
			NSLog(@"Couldn't copy %@ to %@", localProjectFiles, localTrunkPath);
		else
			[fm movePath: localDestPath toPath: localTrunkPath handler: nil];
	}
	else
		[fm createDirectoryAtPath: localTrunkPath attributes: nil];
	
	// Import that project into the repository:
	NSString*			exePath = [self subversionToolPath];
	NSArray*			args = [NSArray arrayWithObjects: @"import", localPath,
											[repositoryURL stringByAppendingString: path],
											@"--message", [@"Added project " stringByAppendingString: [projectNameField stringValue]],
											@"--username", [token username],
											@"--password", [token password],
											@"--non-interactive",
											nil];
	NSTask*				task = [[[NSTask alloc] init] autorelease];
	NSPipe*				thePipe = [NSPipe pipe];
	[task setStandardOutput: thePipe];
	[task setArguments: args];
	[task setLaunchPath: exePath];
	[task launch];
	NSData*				data = [[thePipe fileHandleForReading] readDataToEndOfFile];
	NSLog( @"%@", [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease] );
	
	// Remove template:
	[[NSFileManager defaultManager] removeFileAtPath: localPath handler: nil];
	
	// Update display:
	[self reloadRepository: self];
	[listView reloadData];
}


-(NSString*)	subversionToolPath
{
	NSString*		exePath = [[NSUserDefaults standardUserDefaults] objectForKey: @"svn_executable"];
	if( exePath == nil )
	{
		exePath = [[NSFileManager defaultManager] firstExistingFileAtPaths:
						[NSArray arrayWithObjects: @"/Applications/MAS.app/Contents/Resources/MAS/bin/svn",
						@"/bin/svn", @"/bin/subversion/svn",
						@"/usr/bin/svn", @"/usr/bin/subversion/svn",
						@"/usr/local/bin/svn", @"/usr/local/bin/subversion/svn",
						@"/usr/opt/subversion/bin/svn",
						nil]];
		[[NSUserDefaults standardUserDefaults] setObject: exePath forKey: @"svn_executable"];
	}
	
	return exePath;
}


-(NSMutableArray*)	filesAtRepositoryPath: (NSString*)path subfiles: (BOOL)oneLevelDeeper
{
	NSMutableArray*		arr = nil; //[self filesAtRepositoryPath: path subfiles: oneLevelDeeper authenticate: NO];
	if( !arr )
		arr = [self filesAtRepositoryPath: path subfiles: oneLevelDeeper authenticate: YES];
	
	return arr;
}


-(NSMutableArray*)	filesAtRepositoryPath: (NSString*)path subfiles: (BOOL)oneLevelDeeper authenticate: (BOOL)doAuth
{
	NSString*			exePath = [self subversionToolPath];
	NSArray*			args = nil;
	if( doAuth )
	{
		args = [NSArray arrayWithObjects: @"list", [repositoryURL stringByAppendingString: path],
												@"--non-interactive", @"--xml",
												@"--username", [[authUI authorizationToken] username],
												@"--password", [[authUI authorizationToken] password],
												nil];
	}
	else
	{
		args = [NSArray arrayWithObjects: @"list", [repositoryURL stringByAppendingString: path],
												@"--non-interactive", @"--xml",
												nil];
	}
	NSTask*				task = [[[NSTask alloc] init] autorelease];
	NSPipe*				thePipe = [NSPipe pipe];
	[task setStandardOutput: thePipe];
	[task setArguments: args];
	[task setLaunchPath: exePath];
	[task launch];
	NSData*				data = [[thePipe fileHandleForReading] readDataToEndOfFile];
	
	[task waitUntilExit];
	if( [task terminationStatus] != 0 )
		return nil;
	
	NSMutableArray*		arr = [NSMutableArray array];
	
	NSXMLDocument*		xmlDoc = [[[NSXMLDocument alloc] initWithData: data options: 0 error: nil] autorelease];
	NSXMLElement*		listsElem = [xmlDoc rootElement];
	NSXMLElement*		firstList = [[listsElem elementsForName: @"list"] objectAtIndex: 0];
	NSArray*			entries = [firstList elementsForName: @"entry"];
	NSEnumerator*		enny = [entries objectEnumerator];
	NSXMLElement*		currEntry = nil;
	NSWorkspace*		wsp = [NSWorkspace sharedWorkspace];
	
	while( (currEntry = [enny nextObject]) )
	{
		NS_DURING
			//NSLog( @"%@", [currEntry XMLString]  );
			NSXMLNode*			fileKind = [currEntry attributeForName: @"kind"];
			BOOL				isFolder = [[fileKind objectValue] isEqualToString: @"dir"];
			NSXMLElement*		nameElem = [[currEntry elementsForName: @"name"] objectAtIndex: 0];
			nameElem = (NSXMLElement*) [nameElem childAtIndex: 0];
			NSString*			fileSize = @"0";
			if( !isFolder )
			{
				NSXMLElement*		sizeElem = [[currEntry elementsForName: @"size"] objectAtIndex: 0];
				sizeElem = (NSXMLElement*) [sizeElem childAtIndex: 0];
				fileSize = [sizeElem XMLString];
			}
			NSXMLElement*		commitBlock = [[currEntry elementsForName: @"commit"] objectAtIndex: 0];
			NSXMLNode*			revisionNo = [commitBlock attributeForName: @"revision"];
			NSXMLNode*			authorElem = nil;
			NSArray*			authorElems = [commitBlock elementsForName: @"author"];
			if( [authorElems count] > 0 )
			{
				authorElem = [authorElems objectAtIndex: 0];
				authorElem = (NSXMLElement*) [authorElem childAtIndex: 0];
			}
			NSXMLElement*		dateElem = [[commitBlock elementsForName: @"date"] objectAtIndex: 0];
			dateElem = (NSXMLElement*) [dateElem childAtIndex: 0];
			
			NSString*	displayName = [nameElem XMLString];
			NSString*	currFile = [displayName stringByAppendingString: (isFolder? @"/" : @"")];
			NSString*	ext = [displayName pathExtension];
			NSImage*	fileIcon = [wsp iconForFileType: ext];
			if( isFolder && ([ext length] == 0 || [ext isEqualToString: @"lproj"]) )
				fileIcon = [[NSWorkspace sharedWorkspace] iconForFileType: NSFileTypeForHFSTypeCode(kGenericFolderIcon)]; //[NSImage imageNamed: @"Folder"];
			[fileIcon setSize: NSMakeSize(16,16)];
			NSString*				authorName = (authorElem ? [authorElem XMLString] : @"- unknown -");
			NSString*				itemPath = [path stringByAppendingString: currFile];
			NSMutableDictionary*	currItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
													currFile, @"name",
													displayName, @"displayName",
													itemPath, @"path",
													[dateElem XMLString], @"date",
													fileSize, @"size",
													authorName, @"user",
													[revisionNo objectValue], @"revision",
													fileIcon, @"icon",
													nil];
			[arr addObject: currItem];
			
			if( [itemPath length] > 0 && [itemPath characterAtIndex: 0] != '/' ) 
				itemPath = [@"/" stringByAppendingString: itemPath];
			NSDictionary*	usersAndPerms = [permissionsDB usersAndPermissionsAtPath: itemPath];
			if( usersAndPerms )
				[currItem setObject: usersAndPerms forKey: @"userPermissions"];
			
			if( isFolder && oneLevelDeeper )
			{
				NSMutableArray* arr;
				arr = [self filesAtRepositoryPath: [currItem objectForKey: @"path"] subfiles: NO];	// Don't go any deeper, or we'd recursively load entire tree.
				if( arr )
				{
					[currItem setObject: arr forKey: @"contents"];
					[currItem setObject: [NSNumber numberWithBool: YES] forKey: @"twoLevelsLoaded"];
				}
			}

		NS_HANDLER
			NSLog(@"Error: %@\nOn node: %@", localException, currEntry);
		NS_ENDHANDLER
	}
	
	return arr;
}


-(void)	loadSubitemsForItem: (NSMutableDictionary*)currItem
{
	NS_DURING
	NSString*		currFile = [currItem objectForKey: @"name"];
	if( [currFile characterAtIndex: [currFile length] -1] == '/' )
	{
		NSMutableArray*	subItems = [currItem objectForKey: @"contents"];
		
		if( subItems == nil )
		{
			subItems = [self filesAtRepositoryPath: [currItem objectForKey: @"path"] subfiles: YES];
			if( subItems )
			{
				[currItem setObject: subItems forKey: @"contents"];
				
				[self markProjectFilesInArray: subItems forOwner: currItem];
			}
		}
		else
		{
			NSEnumerator*			enny = [subItems objectEnumerator];
			NSMutableDictionary*	subItem;
			
			while( (subItem = [enny nextObject]) )
			{
				NSString*	nm = [subItem objectForKey: @"name"];
				BOOL		isFolder = [nm characterAtIndex: [nm length] -1] == '/';
				
				if( isFolder && [subItem objectForKey: @"twoLevelsLoaded"] == nil )
				{
					NSMutableArray* arr;
					arr = [self filesAtRepositoryPath: [subItem objectForKey: @"path"] subfiles: NO];	// Don't go any deeper, or we'd recursively load entire tree.
					if( arr )
					{
						[subItem setObject: arr forKey: @"contents"];
						[self markProjectFilesInArray: arr forOwner: subItem];
						[subItem setObject: [NSNumber numberWithBool: YES] forKey: @"twoLevelsLoaded"];
					}
				}
			}
			
		}
	}
	NS_HANDLER
		NSBeep();
	NS_ENDHANDLER
}


-(void)	refreshNewProjectName: (id)sender
{
	NSString*		ppath = [[projectPathField stringValue] lastPathComponent];
	
	if( ppath )
		[projectNameField setStringValue: [ppath lastPathComponent]];
}


// ---------------------------------------------------------- 
// - repositoryURL:
// ---------------------------------------------------------- 
-(NSString *) repositoryURL
{
    return repositoryURL; 
}

// ---------------------------------------------------------- 
// - setRepositoryURL:
// ---------------------------------------------------------- 
-(void) setRepositoryURL: (NSString *) theRepositoryURL
{
    if (repositoryURL != theRepositoryURL)
	{
        [repositoryURL release];
        repositoryURL = [theRepositoryURL retain];
		[[NSUserDefaults standardUserDefaults] setObject: repositoryURL forKey: @"SVNBrowserDefaultRepositoryURL"];
		
		// Load new repository and update display:
		[self reloadRepository: self];
		[listView reloadData];
    }
}


-(NSMutableArray*)	repository
{
	return repository;
}


-(void) setRepository: (NSArray*) theRepository
{
    if (repository != theRepository)
	{
        [repository release];
        repository = [theRepository retain];
		
		[self repositoryListChanged];
    }
}


- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	id obj = nil;
	
	if( item == nil )
		obj = repositoryRoot;
	else
	{
		[self loadSubitemsForItem: (NSMutableDictionary*) item];
		if( showTrunkOnly )
		{
			NSMutableDictionary*	trunkItem = [item objectForKey: @"projectTrunk"];
			if( trunkItem )
				return [self outlineView: outlineView child: index ofItem: trunkItem];
		}
		
		NSArray*	contents = [item objectForKey: @"contents"];
		obj = [contents objectAtIndex: index];
	}
	
	return obj;
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if( item == nil )
		return YES;
	
	NSString*	nm = [item objectForKey: @"name"];
	BOOL		isExpandable = [nm characterAtIndex:[nm length] -1] == '/';
	NSString*	ext = [[item objectForKey: @"displayName"] pathExtension];
	
	if( isExpandable &&
		([ext isEqualToString: @"nib"] || [ext isEqualToString: @"xcodeproj"] || [ext isEqualToString: @"xCode"] || [ext isEqualToString: @"xcode"] || [ext isEqualToString: @"rtfd"] || [ext isEqualToString: @"pbproj"]) )
		isExpandable = NO;
	
	return( isExpandable );
}


- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if( item == nil )
		return 1;
	else
	{
		[self loadSubitemsForItem: (NSMutableDictionary*) item];
		if( showTrunkOnly )
		{
			NSMutableDictionary*	trunkItem = [item objectForKey: @"projectTrunk"];
			if( trunkItem )
				return [self outlineView: outlineView numberOfChildrenOfItem: trunkItem];
		}
		
		return [[item objectForKey: @"contents"] count];
	}
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	NSString*			tid = [tableColumn identifier];
	id					val = [item objectForKey: tid];
	
	if( [tid isEqualToString: @"displayName"] )
	{
		id	projectTrunk = [item objectForKey: @"projectTrunk"];
		if( projectTrunk )
			return [[[NSAttributedString alloc] initWithString: (NSString*)val
							attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont boldSystemFontOfSize: [NSFont systemFontSize]], NSFontAttributeName, nil]]
							autorelease];
	}
	
	return val;
}






@end
