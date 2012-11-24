
#import "GeneralPreferences.h"
#import "ApplicationDelegate.h"

@implementation GeneralPreferences

- (id)init
{
    return [super initWithNibName:@"GeneralPreferences" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

-(void)viewWillAppear
{
    SUUpdater *updater = [(ApplicationDelegate*)[NSApp delegate] updater];
    autocheckForUpdatesCheckbox.state = ([updater automaticallyChecksForUpdates] ? NSOnState : NSOffState);
}

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"General Preferences title");
}

-(void)checkForUpdatesNow:(id)sender
{
    [(ApplicationDelegate*)[NSApp delegate] checkForUpdates:sender];
}

@end
