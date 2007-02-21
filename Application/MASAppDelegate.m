#import "MASAppDelegate.h"
#import "UKFinderIconCell.h"
#import "NSFileManager+CreateDirectoriesForPath.h"
#import "UKSVNPermissions.h"
#import <SystemConfiguration/SystemConfiguration.h>


@implementation MASAppDelegate

-(void)	applicationDidFinishLaunching: (NSNotification*)notification
{
	// Are we being run from the right folder?
	NSString*	bPath = [[NSBundle mainBundle] bundlePath];
	if( ![bPath isEqualToString: GUI_APP_PATH] )
	{
		NSLog(@"%@ != %@", GUI_APP_PATH, bPath );
		if( NSRunCriticalAlertPanel( @"MAS can not run from this folder!", @"Please move the MAS folder into your \"Applications\" folder.", @"Quit", @"Run Anyway", @"" ) == NSAlertDefaultReturn )
			[NSApp terminate: self];
	}
	
	// Don't have a repository yet? Create it!
	if( ![[NSFileManager defaultManager] fileExistsAtPath: REPOSITORY_FOLDER_PATH] )
	{
		///	Applications/MAS/bin/svnadmin create /Applications/MAS/repositories
		NSTask*	createRepoTask = [NSTask launchedTaskWithLaunchPath: SVNADMIN_APP_PATH
			arguments: [NSArray arrayWithObjects:
							@"create",
							REPOSITORY_FOLDER_PATH,
						nil]];
		
		// Create a folder where we can put our RSS feed:
		if( ![[NSFileManager defaultManager] fileExistsAtPath: HTDOCS_FOLDER_PATH] )
		{
			[[NSFileManager defaultManager] createDirectoriesForPath: HTDOCS_FOLDER_PATH];
		}
		
		// Create a default index file next to our RSS feed:
		if( ![[NSFileManager defaultManager] fileExistsAtPath: HTML_INDEX_FILE_PATH] )
		{
			NSString*	sourceFile = [[NSBundle mainBundle] pathForResource: @"index.html" ofType: @""];
			NSString*	afBody = [NSString stringWithContentsOfFile: sourceFile];
			[afBody writeToFile: HTML_INDEX_FILE_PATH atomically: NO];
		}
		
		// Create a post-commit hook in repository that'll update our RSS feed:
		[createRepoTask waitUntilExit];	// Can't do that until repository has been created.
		
		if( ![[NSFileManager defaultManager] fileExistsAtPath: POST_COMMIT_HOOK_FILE_PATH] )
		{
			[[NSFileManager defaultManager] createDirectoriesForPath: HOOKS_FOLDER_PATH];
			NSString*	sourceFile = [[NSBundle mainBundle] pathForResource: @"post-commit" ofType: @""];
			NSString*	afBody = [NSString stringWithContentsOfFile: sourceFile];
			[afBody writeToFile: POST_COMMIT_HOOK_FILE_PATH atomically: NO];
			unsigned long	posixPermissions = [[[NSFileManager defaultManager] fileAttributesAtPath: POST_COMMIT_HOOK_FILE_PATH traverseLink: NO] filePosixPermissions];
			posixPermissions |= (1 << 6);	// Allow execute by owner, which is this user, which is what the server will run as. If this isn't set, SVN won't call us.
			[[NSFileManager defaultManager] changeFileAttributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithUnsignedLong: posixPermissions], NSFilePosixPermissions, nil] atPath: POST_COMMIT_HOOK_FILE_PATH];
		}
	}
	
	if( ![[NSFileManager defaultManager] fileExistsAtPath: PERMISSIONS_FILE_PATH] )
	{
		NSString*	sourceFile = [[NSBundle mainBundle] pathForResource: @"svn-access-file" ofType: @""];
		NSString*	afBody = [NSString stringWithContentsOfFile: sourceFile];
		[afBody writeToFile: PERMISSIONS_FILE_PATH atomically: NO];
	}
	
	// Set up our "Users & Groups" dist view:
	UKFinderIconCell*		bCell = [[[UKFinderIconCell alloc] init] autorelease];
	[bCell setImagePosition: NSImageAbove];
	[bCell setEditable: NO];
	[usersAndGroupsView setPrototype: bCell];
	[usersAndGroupsView setCellSize: NSMakeSize(100.0,80.0)];
	[usersAndGroupsView setSizeToFit: YES];
	
	// Get list of existing users:
	NSString		*	str = [NSString stringWithContentsOfFile: PASSWORD_FILE_PATH];
	NSArray			*	usernames = [str componentsSeparatedByString: @"\n"];
	NSEnumerator	*	enny = [usernames objectEnumerator];
	NSString		*	pwLine = nil;
	userList = [[NSMutableArray alloc] init];
	
	while( (pwLine = [enny nextObject]) )
	{
		if( [pwLine length] == 0 )
			continue;
		
		NSRange	colonPos = [pwLine rangeOfString: @":"];
		if( colonPos.location != NSNotFound )
		{
			NSString*	userName = [pwLine substringToIndex: colonPos.location];
			[userList addObject: [NSDictionary dictionaryWithObjectsAndKeys: @"user", @"type", userName, @"name", nil]];
		}
	}
	
	[usersAndGroupsView reloadData];
	
	[self startUpServer: nil];
}


-(void)	dealloc
{
	[userList release];
	[svnBrowser release];
	[svnPermissions release];
	
	[super dealloc];
}


-(int)			numberOfItemsInDistributedView: (UKDistributedView*)distributedView
{
	return [userList count];
}

-(NSPoint)		distributedView: (UKDistributedView*)distributedView
						positionForCell:(NSCell*)cell /* may be nil if the view only wants the item position. */
						atItemIndex: (int)row
{
	NSDictionary*	dict = [userList objectAtIndex: row];
	if( cell )
	{
		[cell setImage: [NSImage imageNamed: [dict objectForKey: @"type"]]];
		[cell setTitle: [dict objectForKey: @"name"]];
	}
	
	return [distributedView itemPositionBasedOnItemIndex: row];
}


-(void) distributedView: (UKDistributedView*)distributedView cellDoubleClickedAtItemIndex: (int)item
{
	NSDictionary*	dict = [userList objectAtIndex: item];
	[self showCreateUserSheetForUserName: [dict objectForKey: @"name"]];
}


-(IBAction)	showSVNBrowser: (id)sender
{
	if( !svnBrowser )
		svnBrowser = [[UKSVNBrowser alloc] initWithPermissionsFile: svnPermissions];
}


-(void)	createNewUserSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[[passwordField window] orderOut: nil];
}


-(IBAction)		showCreateUserSheet: (id)sender
{
	[self showCreateUserSheetForUserName: nil];
}


// Specify NIL to create a new user, specify a user name string to change that
//	user's password.
-(IBAction)		showCreateUserSheetForUserName: (NSString*)userName
{
	if( userName )
	{
		[userNameField setStringValue: userName];
		[passwordField setStringValue: @""];
		[confirmPasswordField setStringValue: @""];
		[createUserButton setTitle: @"Change"];
	}
	else
		[createUserButton setTitle: @"Create"];

	[userNameField setEnabled: (userName == nil)];
	
	[NSApp beginSheet: [passwordField window] modalForWindow: [usersAndGroupsView window]
				modalDelegate: self didEndSelector: @selector(createNewUserSheetDidEnd:returnCode:contextInfo:)
				contextInfo: nil];
}


-(IBAction)		cancelCreateUserSheet: (id)sender
{
	[NSApp endSheet: [passwordField window]];
}


-(IBAction)		createUser: (id)sender
{
	NSString*		theUserName = [userNameField stringValue];
	
	[NSApp endSheet: [passwordField window]];
	
	// First check whether we have a valid name & password:
	if( [theUserName length] <= 3 || [theUserName rangeOfString: @":"].location != NSNotFound
		|| [theUserName rangeOfString: @"\n"].location != NSNotFound || [theUserName rangeOfString: @"\r"].location != NSNotFound
		|| [theUserName rangeOfString: @"\t"].location != NSNotFound )
	{
		NSRunCriticalAlertPanel( @"No Valid Username specified!", @"A user name must be at least 3 characters long and may not contain any of the following characters:\n\tcolon (\":\")\n\ttab\n\treturn (\"newline\")", @"OK", @"", @"" );
		return;
	}
	
	if( [[passwordField stringValue] length] == 0 )
	{
		NSRunCriticalAlertPanel( @"No Password specified!", @"Please specify a valid password before clicking this button!", @"OK", @"", @"" );
		return;
	}
	
	if( ![[passwordField stringValue] isEqualToString: [confirmPasswordField stringValue]] )
	{
		NSRunCriticalAlertPanel( @"You mistyped the password!", @"Please retype your password the same way into both fields to make sure you don't register a password with a typo and are unable to log into your repository.", @"OK", @"", @"" );
		return;
	}
	
	// Now either create a new password file or just create a new user in the existing one:
	if( ![[NSFileManager defaultManager] fileExistsAtPath: PASSWORD_FILE_PATH] )
	{
		//Applications/MAS/bin/htpasswd -b -c /Applications/MAS/conf/svn-auth-file username password
		[NSTask launchedTaskWithLaunchPath: PASSWORD_APP_PATH
					arguments: [NSArray arrayWithObjects:
									@"-b", @"-c",	// -c means create new password, -b means we're passing in name & password instead of having the tool ask for the password interacively.
									PASSWORD_FILE_PATH,
									theUserName,
									[passwordField stringValue],
								nil]];
	}
	else
	{
		//Applications/MAS/bin/htpasswd -b /Applications/MAS/conf/svn-auth-file username password
		[NSTask launchedTaskWithLaunchPath: PASSWORD_APP_PATH
					arguments: [NSArray arrayWithObjects:
									@"-b",
									PASSWORD_FILE_PATH,
									theUserName,
									[passwordField stringValue],
								nil]];
	}
	
	// Now find whether our cached list of users already contains this user:
	NSEnumerator	*	enny = [userList objectEnumerator];
	NSDictionary	*	dict = nil;
	BOOL				userExists = NO;
	
	while( (dict = [enny nextObject]) )
	{
		if( [[dict objectForKey: @"name"] isEqualToString: theUserName] )
		{
			userExists = YES;
			break;
		}
	}
	
	// If not, we now add it so it's up-to-date again:
	if( !userExists )
	{
		[userList addObject: [NSDictionary dictionaryWithObjectsAndKeys: @"user", @"type", theUserName, @"name", nil]];
		[usersAndGroupsView reloadData];
	}
	
	if( retryStartUpAfterUserCreation )
	{
		retryStartUpAfterUserCreation = NO;
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged: PASSWORD_FILE_PATH];	// Give OS opportunity to notice the new password file.
		sleep(2);
		[[NSWorkspace sharedWorkspace] noteFileSystemChanged: PASSWORD_FILE_PATH];	// Give OS opportunity to notice the new password file.
		[self startUpServer: self];
	}
}


-(BOOL)	deleteUserNamed: (NSString*)userName
{
	// Try to find line for our user in the htpasswd file:
	NSString		*	str = [NSString stringWithFormat: @"\n%@\n", [NSString stringWithContentsOfFile: PASSWORD_FILE_PATH]];
	NSString		*	searchStr = [NSString stringWithFormat: @"\n%@:", userName];
	NSRange				userNamePos = [str rangeOfString: searchStr];
	NSRange				userNameLineEndPos;
	
	if( userNamePos.location == NSNotFound )
		return NO;
	
	// Have such a name? Find the end of its line:
	userNameLineEndPos = [str rangeOfString: @"\n" options: 0 range: NSMakeRange( userNamePos.location +1, [str length] -userNamePos.location -2 )];
	
	NSRange				userLineRange = NSMakeRange( userNamePos.location +1, userNameLineEndPos.location -userNamePos.location );
	NSMutableString*	newPasswordFile = [[str mutableCopy] autorelease];
	
	// Delete the line specifying this user and save the changed file:
	[newPasswordFile deleteCharactersInRange: userLineRange];
	BOOL	success = [newPasswordFile writeToFile: PASSWORD_FILE_PATH atomically: YES];
	
	// Now delete entry for this user in our GUI:
	if( success )
	{
		NSEnumerator	*	enny = [userList objectEnumerator];
		NSDictionary	*	dict = nil;
		int					x = 0;
		
		while( (dict = [enny nextObject]) )
		{
			if( [[dict objectForKey: @"name"] isEqualToString: userName] )
			{
				[userList removeObjectAtIndex: x];
				[usersAndGroupsView reloadData];
				return success;
			}
			
			x++;
		}
	}
	
	return success;
}


-(void)	delete: (id)sender
{
	int		selectedIndex = [usersAndGroupsView selectedItemIndex];
	
	if( selectedIndex == -1 )
	{
		NSBeep();
		return;
	}
	
	NSString*		userName = [[userList objectAtIndex: selectedIndex] objectForKey: @"name"];
	
	[self deleteUserNamed: userName];
}


-(BOOL) validateMenuItem: (id <NSMenuItem>)menuItem
{
	if( [menuItem action] == @selector(delete:) )
		return( [usersAndGroupsView selectedItemIndex] != -1 );
	else
		return [self respondsToSelector: [menuItem action]];
}


-(void)	applicationWillTerminate: (NSNotification*)notification
{
	NS_DURING
		if( isRunning )
			[self shutDownServer: nil];
	NS_HANDLER
		NSRunCriticalAlertPanel( @"Error!", @"%@", @"OK", @"", @"", [localException reason] );
	NS_ENDHANDLER
}

-(IBAction)	startStopMAS: (id)sender
{
	NS_DURING
		if( !isRunning )
			[self startUpServer: nil];
		else
			[self shutDownServer: nil];
	NS_HANDLER
		NSRunCriticalAlertPanel( @"Error!", @"%@", @"OK", @"", @"", [localException reason] );
	NS_ENDHANDLER
}


-(void)		shutDownServer: (id)sender
{
	[urlField setString: @"Shutting Down..."];
	[startButton setEnabled: NO];
	[progress startAnimation: self];
	// Applications/MAS/bin/apachectl stop
	NSTask*	theTask = [NSTask launchedTaskWithLaunchPath: APACHECTL_PATH arguments: [NSArray arrayWithObject: @"stop"]];
	while( [theTask isRunning] )
	{
		NSEvent * theEvent = [NSApp nextEventMatchingMask: NSAnyEventMask untilDate: [NSDate dateWithTimeIntervalSinceNow: 1]
										inMode: NSModalPanelRunLoopMode dequeue: YES];
		if( theEvent )
			[NSApp sendEvent: theEvent];
	}
	[progress stopAnimation: self];
	[urlField setString: @"<not running>"];
	[startButton setTitle: @"Start"];
	[startButton setEnabled: YES];
	isRunning = NO;
}


-(void)		makeSureWeHaveAccessFile
{
	if( svnPermissions )
		return;
	
	svnPermissions = [[UKSVNPermissions alloc] initWithContentsOfFile: PERMISSIONS_DB_FILE];
	if( [svnPermissions isEmpty] && [userList count] > 0 )
	{
		NSDictionary*	userDict = [userList objectAtIndex: 0];
		[svnPermissions setPermissions: SVN_PERMISSION_BOTH atPath: @"/" forUser: [userDict objectForKey: @"name"]];
		[svnPermissions setPermissions: 0 atPath: @"/" forUser: @"*"];
		[svnPermissions writeToFile: PERMISSIONS_DB_FILE atomically: YES];
	}
}


-(void)		startUpServer: (id)sender
{
	if( ![[NSFileManager defaultManager] fileExistsAtPath: PASSWORD_FILE_PATH] )
	{
		NSRunCriticalAlertPanel( @"No username and password set!", @"Please create at least one user before launching the server.", @"OK", @"", @"" );
		[self showCreateUserSheet: self];
		retryStartUpAfterUserCreation = YES;
		return;
	}
	
	[self makeSureWeHaveAccessFile];

	[urlField setString: @"Starting up..."];
	[startButton setEnabled: NO];
	[progress startAnimation: self];
	// Applications/MAS/bin/apachectl start
	NSTask*	theTask = [NSTask launchedTaskWithLaunchPath: APACHECTL_PATH arguments: [NSArray arrayWithObject: @"start"]];
	while( [theTask isRunning] )
	{
		NSEvent * theEvent = [NSApp nextEventMatchingMask: NSAnyEventMask untilDate: [NSDate dateWithTimeIntervalSinceNow: 1]
										inMode: NSModalPanelRunLoopMode dequeue: YES];
		if( theEvent )
			[NSApp sendEvent: theEvent];
	}
	
	// Build path:
	int					portNum = 8800;
	NSString*			serverName = [(NSString*)SCDynamicStoreCopyLocalHostName(NULL) autorelease];
	NSString*			serverURL = [NSString stringWithFormat: @"http://%@.local:%d/svn/", serverName, portNum];
	NSDictionary*		attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
														[NSURL URLWithString: serverURL], NSLinkAttributeName,
														[NSColor blueColor], NSForegroundColorAttributeName,
														nil];
	NSAttributedString*	attrStr = [[[NSAttributedString alloc] initWithString: serverURL attributes: attrDict] autorelease];
	
	[progress stopAnimation: self];
	[[urlField textStorage] setAttributedString: attrStr];
	[startButton setTitle: @"Stop"];
	[startButton setEnabled: YES];
	isRunning = YES;
}


-(BOOL) textView: (NSTextView*)textView clickedOnLink: (id)link atIndex: (unsigned)charIndex
{
	NSURL*	theURL = [[textView textStorage] attribute: NSLinkAttributeName atIndex: charIndex effectiveRange: NULL];
	
	if( theURL )
	{
		[[NSWorkspace sharedWorkspace] openURL: theURL];
		return YES;
	}
	else
		return NO;
}

@end
