#import "SCAuthorizationUI.h"

@implementation SCAuthorizationUI

- (id) init
{
	self = [super init];
	if( self )
	{
		if (![NSBundle loadNibNamed:@"SCAuthorizationUI" owner:self]) 
		{
			NSLog(@"***ERROR*** Failed to load SCAuthorizationUI nib. (%s:%d)", __FILE__, __LINE__);
			[self release];
			return nil;
		}
		
		token = [[SCAuthToken alloc] init];
	}
	
	return self;
}

- (void) dealloc
{
    [controller release];
    [token release];
    [super dealloc];
}

- (IBAction) authorize:(id)sender
{
    [NSApp endSheet: authWindow returnCode:1];
}

- (IBAction) cancel:(id)sender
{
    [NSApp endSheet: authWindow returnCode:0];
}

- (void) showForWindow:(id)window
{
	NSString*	userName = [[NSUserDefaults standardUserDefaults] objectForKey: @"SCAuthorizationUIUserName"];
	if( userName )
	{
		[usernameField setStringValue: userName];
		[authWindow makeFirstResponder: passwordField];
	}
	
    [NSApp beginSheet:authWindow
       modalForWindow:window
        modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

-(void)	modalAuthorizationEndedWithOK: (id)sender
{
	modalAuthMode = MODAL_AUTH_MODE_SUCCESS;
}


-(void)	modalAuthorizationEndedWithCancel: (id)sender
{
	modalAuthMode = MODAL_AUTH_MODE_FAILURE;
}



- (BOOL) runModalForWindow:(id)window
{
	[self setController: self];
	[self setAuthorizationSelector: @selector(modalAuthorizationEndedWithOK:)];
	[self setCancelSelector: @selector(modalAuthorizationEndedWithCancel:)];
	[self showForWindow: window];
	
	while( modalAuthMode == MODAL_AUTH_MODE_PENDING )
	{
		NSEvent*	theEvent = [NSApp nextEventMatchingMask: NSAnyEventMask untilDate: [NSDate dateWithTimeIntervalSinceNow: 1] inMode: NSModalPanelRunLoopMode dequeue: YES];
		if( theEvent )
			[NSApp sendEvent: theEvent];
	}
	
	BOOL		success = (modalAuthMode == MODAL_AUTH_MODE_SUCCESS);
	modalAuthMode = MODAL_AUTH_MODE_PENDING;
	
	return success;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    
    if (returnCode == 0 && [controller respondsToSelector: [self cancelSelector]] )
    {
        [controller performSelector:[self cancelSelector]];
    }
    
    if (returnCode != 0 && [controller respondsToSelector:[self authorizationSelector]])
    {
		SCAuthToken*	vToken = [self authorizationToken];
		
		[vToken setUsername: [usernameField stringValue]];
		[[NSUserDefaults standardUserDefaults] setObject: [usernameField stringValue] forKey: @"SCAuthorizationUIUserName"];
		[vToken setPassword: [passwordField stringValue]];
		
        [controller performSelector:[self authorizationSelector] withObject: vToken];
    }
}

- (id) controller
{
    return controller;
}

- (void) setController:(id)c;
{
    [controller release];
    controller = [c retain];
}

- (SEL) cancelSelector
{
    return cancelSelector;
}

- (void) setCancelSelector:(SEL)value
{
    cancelSelector = value;
}

- (SEL) authorizationSelector
{
    return authorizationSelector;
}

- (void) setAuthorizationSelector:(SEL)value
{
    authorizationSelector = value;
}

- (SCAuthToken *) authorizationToken
{
    return token;
}

@end
