/* SCAuthorizationUI */

#import <Cocoa/Cocoa.h>

#import "SCAuthToken.h"


#define	MODAL_AUTH_MODE_PENDING			0		// Pending or inactive.
#define MODAL_AUTH_MODE_SUCCESS			1
#define MODAL_AUTH_MODE_FAILURE			2


@interface SCAuthorizationUI : NSObject
{
    IBOutlet id				authWindow;
	IBOutlet NSTextField*	usernameField;
	IBOutlet NSTextField*	passwordField;

    @private
    id						controller;
    SEL						cancelSelector;
    SEL						authorizationSelector;
	int						modalAuthMode;
    SCAuthToken				*token;
}

- (IBAction)authorize:(id)sender;
- (IBAction)cancel:(id)sender;

- (void) showForWindow:(id)window;
- (BOOL) runModalForWindow:(id)window;

- (id) controller;
- (void) setController:(id)c;

- (SEL) cancelSelector;
- (void) setCancelSelector:(SEL)value;

- (SEL) authorizationSelector;
- (void) setAuthorizationSelector:(SEL)value;

- (SCAuthToken *) authorizationToken;

@end
