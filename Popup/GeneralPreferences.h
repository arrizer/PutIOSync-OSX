
#import "MASPreferencesViewController.h"

@interface GeneralPreferences : NSViewController <MASPreferencesViewController>
{
    IBOutlet NSButton *autocheckForUpdatesCheckbox;
}

-(IBAction)checkForUpdatesNow:(id)sender;

@end
