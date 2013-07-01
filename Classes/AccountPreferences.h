
#import "MASPreferencesViewController.h"

#import "AccountSetupController.h"
#import "PutIOAPI.h"

@interface AccountPreferences : NSViewController
<MASPreferencesViewController, AccountSetupControllerDelegate, PutIOAPIDelegate>
{
    IBOutlet NSTextField *infoLabel;
    IBOutlet NSTextField *accountEMailAddressLabel;
    IBOutlet NSTextField *accountUsernameLabel;
    IBOutlet NSTextField *spaceLabel;
    IBOutlet NSButton *connectButton;
    
    IBOutlet NSProgressIndicator *activitySpinner;
    IBOutlet NSTextField *activityLabel;
        
    AccountSetupController *accountSetup;
}

@property (strong) PutIOAPI *putio;

-(IBAction)connectAccountButtonClicked:(id)sender;

@end
