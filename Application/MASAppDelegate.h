/* =============================================================================

File: MASAppDelegate.h

Copyright (c) 2006 by M. Uli Kusterer.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

============================================================================= */

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import "UKSVNBrowser.h"


// -----------------------------------------------------------------------------
//	Constants:
// -----------------------------------------------------------------------------

// File paths:
//	This uses a trick: You can concatenate NSStrings by writing
//	@"foo" "bar" instead of @"foobar". Note how the second
//	string doesn't have an at sign.
#define USERDATA_PATH				@"/Library/Application Support/MAS/"
#define BASE_PATH					@"/usr/"
#define GUI_APP_PATH				@"/Applications/MAS.app"
#define	PASSWORD_APP_PATH			BASE_PATH "sbin/htpasswd"
#define	SVNADMIN_APP_PATH			BASE_PATH "bin/svnadmin"
#define	APACHECTL_PATH				BASE_PATH "sbin/apachectl"
#define	HTDOCS_FOLDER_PATH			USERDATA_PATH "htdocs/"
#define	HTML_INDEX_FILE_PATH		HTDOCS_FOLDER_PATH "index.html"
#define	PASSWORD_FILE_PATH			USERDATA_PATH "svn-auth-file"
#define	PERMISSIONS_FILE_PATH		USERDATA_PATH "svn-access-file"
#define	REPOSITORY_FOLDER_PATH		USERDATA_PATH "repositories/"
#define	HOOKS_FOLDER_PATH			REPOSITORY_FOLDER_PATH "hooks/"
#define	POST_COMMIT_HOOK_FILE_PATH	HOOKS_FOLDER_PATH "post-commit"


// -----------------------------------------------------------------------------
//	Classes:
// -----------------------------------------------------------------------------

@interface MASAppDelegate : NSObject
{
    IBOutlet NSButton				*	startButton;
    IBOutlet NSTextView				*	urlField;
    IBOutlet NSTextField			*	userNameField;
    IBOutlet NSTextField			*	passwordField;
    IBOutlet NSTextField			*	confirmPasswordField;
	IBOutlet NSButton				*	createUserButton;
	IBOutlet NSProgressIndicator	*	progress;
	IBOutlet NSOutlineView			*	usersAndGroupsView;
	NSMutableArray					*	userList;
	BOOL								isRunning;
	BOOL								retryStartUpAfterUserCreation;
	UKSVNBrowser					*	svnBrowser;
	UKSVNPermissions				*	svnPermissions;
}

-(IBAction)	startStopMAS: (id)sender;

-(IBAction)	showSVNBrowser: (id)sender;
-(IBAction)	showCreateUserSheet: (id)sender;
-(IBAction)	showCreateUserSheetForUserName: (NSString*)userName;
-(IBAction)	createUser: (id)sender;
-(void)		delete: (id)sender;
-(IBAction)	cancelCreateUserSheet: (id)sender;

-(BOOL)		deleteUserNamed: (NSString*)userName;

-(void)		startUpServer: (id)sender;
-(void)		shutDownServer: (id)sender;

-(void)		makeSureWeHaveAccessFile;

@end
