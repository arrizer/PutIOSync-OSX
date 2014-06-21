#import "ApplicationDelegate.h"

#import "MASPreferencesWindowController.h"
#import "GeneralPreferences.h"
#import "AccountPreferences.h"
#import "SyncPreferences.h"
#import "PutIODownload.h"
#import "SyncInstruction.h"
#import "SyncScheduler.h"
#import "PutIOAPI.h"
#import "PersistenceManager.h"

@implementation ApplicationDelegate

- (void)dealloc
{
    [_panelController removeObserver:self forKeyPath:@"hasActivePanel"];
}

void *kContextActivePanel = &kContextActivePanel;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == kContextActivePanel) {
        self.menubarController.hasActiveIcon = self.panelController.hasActivePanel;
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Getters/Setters

- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSArray *preferencePanes = @[
            [[GeneralPreferences alloc] init],
            [[AccountPreferences alloc] init],
            [[SyncPreferences alloc] init]
        ];
        NSString *title = NSLocalizedString(@"Preferences", @"preferences.title");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:preferencePanes title:title];
    }
    return _preferencesWindowController;
}

- (PanelController *)panelController
{
    if (_panelController == nil) {
        _panelController = [[MainPanel alloc] initWithDelegate:self];
        [_panelController addObserver:self forKeyPath:@"hasActivePanel" options:0 context:kContextActivePanel];
    }
    return _panelController;
}

-(SUUpdater *)updater
{
    return updater;
}

#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [ApplicationDelegate setupUserDefaults];
    // Install icon into the menu bar
    self.menubarController = [[MenubarController alloc] init];
    [PutIODownload allDownloads];
    [[SyncScheduler sharedSyncScheduler] scheduleSyncs];
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"general_syncinterval"] != 5){
        [[SyncScheduler sharedSyncScheduler] startSyncingAll];
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    
    // Register URL scheme
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:self
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [PutIODownload pauseAndSaveAllDownloads];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.menubarController = nil;
    return [[PersistenceManager manager] applicationShouldTerminate:sender];
}

#pragma mark - Actions

- (IBAction)togglePanel:(id)sender
{
    self.menubarController.hasActiveIcon = !self.menubarController.hasActiveIcon;
    self.panelController.hasActivePanel = self.menubarController.hasActiveIcon;
}

- (IBAction)showPreferences:(id)sender
{
    [self.preferencesWindowController showWindow:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (IBAction)checkForUpdates:(id)sender
{
    [updater checkForUpdates:self];
}

#pragma mark - PanelControllerDelegate

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller
{
    return self.menubarController.statusItemView;
}

#pragma mark - User Defaults

+ (void)setupUserDefaults
{
    NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
    
    // load the default values for the user defaults
    userDefaultsValuesPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults"
                                                           ofType:@"plist"];
    userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
    
    // set them in the standard user defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsValuesDict];
}

#pragma mark - User Notifications

static NSDictionary *userNotifications = nil;

- (void)deliverUserNotificationWithIdentifier:(NSString*)identifier message:(NSString*)message
{
    NSString *preferenceKey = [NSString stringWithFormat:@"general_notifications_%@", identifier];
    if(!userNotifications)
        userNotifications = @{@"newfiles": NSLocalizedString(@"Downloading new files", nil),
                              @"downloadfinished": NSLocalizedString(@"Download finished", nil),
                              @"downloadfailed": NSLocalizedString(@"Download failed", nil)};
    if(!userNotifications[identifier])
        return;
    if([[NSUserDefaults standardUserDefaults] boolForKey:preferenceKey]){
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = userNotifications[identifier];
        notification.hasActionButton = NO;
        notification.informativeText = message;
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
}

#pragma mark - URL Scheme Handling

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    NSString *url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSLog(@"Got URL event: %@", url);
}

#pragma mark - Login Item

-(void)addApplicationAsLoginItem
{
    // Make sure we are not added twice
    [self removeApplicationLoginItem];
    
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
    
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,
                                                            kLSSharedFileListSessionLoginItems, NULL);
	if(loginItems){
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
                                                                     kLSSharedFileListItemLast, NULL, NULL,
                                                                     url, NULL, NULL);
		if(item)
			CFRelease(item);
	}
	CFRelease(loginItems);
}

-(void)removeApplicationLoginItem
{
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
    
	CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:appPath];
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if(loginItems){
		UInt32 seedValue;
		NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		for(int i = 0; i < [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
                                                                                 objectAtIndex:i];
			//Resolve the item with URL
			if (LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*) &url, NULL) == noErr) {
				NSString * urlPath = [(__bridge NSURL*)url path];
				if ([urlPath compare:appPath] == NSOrderedSame){
					LSSharedFileListItemRemove(loginItems,itemRef);
				}
			}
		}
	}
}

@end
