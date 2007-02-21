/* MASAppDelegate */

#import <Cocoa/Cocoa.h>
#import "UKDistributedView.h"
#import "UKSVNBrowser.h"


// File paths:
//	This uses a trick: You can concatenate NSStrings by writing
//	@"foo" "bar" instead of @"foobar". Note how the second
//	string doesn't have an at sign.
#define USERDATA_PATH				@"/Library/Application Support/MAS/"
#define BASE_PATH					@"/Applications/MAS.app/Contents/Resources/MAS/"
#define GUI_APP_PATH				@"/Applications/MAS.app"
#define	PASSWORD_APP_PATH			BASE_PATH "bin/htpasswd"
#define	SVNADMIN_APP_PATH			BASE_PATH "bin/svnadmin"
#define	APACHECTL_PATH				BASE_PATH "bin/apachectl"
#define	HTDOCS_FOLDER_PATH			USERDATA_PATH "htdocs/"
#define	HTML_INDEX_FILE_PATH		HTDOCS_FOLDER_PATH "index.html"
#define	PASSWORD_FILE_PATH			USERDATA_PATH "svn-auth-file"
#define	PERMISSIONS_FILE_PATH		USERDATA_PATH "svn-access-file"
#define	REPOSITORY_FOLDER_PATH		USERDATA_PATH "repositories/"
#define	HOOKS_FOLDER_PATH			REPOSITORY_FOLDER_PATH "hooks/"
#define	POST_COMMIT_HOOK_FILE_PATH	HOOKS_FOLDER_PATH "post-commit"


@interface MASAppDelegate : NSObject
{
    IBOutlet NSButton				*	startButton;
    IBOutlet NSTextView				*	urlField;
    IBOutlet NSTextField			*	userNameField;
    IBOutlet NSTextField			*	passwordField;
    IBOutlet NSTextField			*	confirmPasswordField;
	IBOutlet NSButton				*	createUserButton;
	IBOutlet NSProgressIndicator	*	progress;
	IBOutlet UKDistributedView		*	usersAndGroupsView;
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

-(BOOL)	deleteUserNamed: (NSString*)userName;

-(void)		startUpServer: (id)sender;
-(void)		shutDownServer: (id)sender;

-(void)		makeSureWeHaveAccessFile;
@end
