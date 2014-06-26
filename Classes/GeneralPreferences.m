
#import "GeneralPreferences.h"
#import "ApplicationDelegate.h"
#import "PutIODownloadManager.h"

@implementation GeneralPreferences

- (id)init
{
    return [super initWithNibName:@"GeneralPreferences" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

-(void)viewWillAppear
{
    [self updateUpdaterState];
}

- (void)updateUpdaterState
{
    SUUpdater *updater = [(ApplicationDelegate*)[NSApp delegate] updater];
    autocheckForUpdatesCheckbox.state = ([updater automaticallyChecksForUpdates] ? NSOnState : NSOffState);
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    NSString *dateString = (updater.lastUpdateCheckDate == nil
                            ? NSLocalizedString(@"never", nil)
                            : [dateFormatter stringFromDate:updater.lastUpdateCheckDate]);
    lastUpdateLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Last update: %@", nil), dateString];
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

#pragma mark - Actions

-(IBAction)checkForUpdatesNow:(id)sender
{
    [(ApplicationDelegate*)[NSApp delegate] checkForUpdates:sender];
    [self updateUpdaterState];
}

-(IBAction)autocheckForUpdatesChanged:(id)sender
{
    SUUpdater *updater = [(ApplicationDelegate*)[NSApp delegate] updater];
    updater.automaticallyChecksForUpdates = ((autocheckForUpdatesCheckbox.state == NSOnState) ? YES : NO);
}

-(IBAction)launchOnLoginToggled:(id)sender
{
    ApplicationDelegate *appDelegate = (ApplicationDelegate*)[NSApp delegate];
    if(launchOnLoginCheckbox.state == NSOnState)
        [appDelegate addApplicationAsLoginItem];
    else
        [appDelegate removeApplicationLoginItem];
}

-(IBAction)maxParallelDownloadsChanged:(id)sender
{
    [[PutIODownloadManager manager] complyWithMaximumParallelDownloads];
}

@end
