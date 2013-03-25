
#import "MASPreferencesViewController.h"

@interface GeneralPreferences : NSViewController <MASPreferencesViewController>
{
    IBOutlet NSButton *autocheckForUpdatesCheckbox;
    IBOutlet NSTextField *lastUpdateLabel;
    IBOutlet NSButton *launchOnLoginCheckbox;
}

-(IBAction)checkForUpdatesNow:(id)sender;
-(IBAction)autocheckForUpdatesChanged:(id)sender;
-(IBAction)launchOnLoginToggled:(id)sender;
-(IBAction)maxParallelDownloadsChanged:(id)sender;

@end
