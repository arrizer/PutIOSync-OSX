#import "MenubarController.h"
#import "TransfersPanel.h"

@interface ApplicationDelegate : NSObject <NSApplicationDelegate, PanelControllerDelegate>

@property (nonatomic, strong) MenubarController *menubarController;
@property (nonatomic, strong) PanelController *panelController;
@property (nonatomic, strong) NSWindowController *preferencesWindowController;

- (IBAction)showPreferences:(id)sender;
- (IBAction)togglePanel:(id)sender;

+ (void)setupUserDefaults;

@end
