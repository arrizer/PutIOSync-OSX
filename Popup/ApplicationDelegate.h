
#import <Sparkle/Sparkle.h>
#import "MenubarController.h"
#import "MainPanel.h"

@interface ApplicationDelegate : NSObject
<NSApplicationDelegate, PanelControllerDelegate>
{
    IBOutlet SUUpdater *updater;
}

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong) PanelController *panelController;
@property (nonatomic, strong) NSWindowController *preferencesWindowController;
@property (readonly) SUUpdater *updater;

- (IBAction)showPreferences:(id)sender;
- (IBAction)togglePanel:(id)sender;
- (IBAction)checkForUpdates:(id)sender;

- (void)deliverUserNotificationWithIdentifier:(NSString*)identifier message:(NSString*)message;

+ (void)setupUserDefaults;

- (void)addApplicationAsLoginItem;
- (void)removeApplicationLoginItem;

@end
