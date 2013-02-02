
#import "MASPreferencesViewController.h"

@interface GeneralPreferences : NSViewController <MASPreferencesViewController>
{
    IBOutlet NSButton *autocheckForUpdatesCheckbox;
    IBOutlet NSTextField *lastUpdateLabel;
}

-(IBAction)checkForUpdatesNow:(id)sender;
-(IBAction)autocheckForUpdatesChanged:(id)sender;

@end
