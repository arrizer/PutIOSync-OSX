
#import "PanelController.h"

typedef NS_ENUM(NSInteger, MainPanelListMode) {
    MainPanelListModeDownloads = 1,
    MainPanelListModeTransfers = 0
};

@interface MainPanel : PanelController
<NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>
{
    IBOutlet NSTableView *tableView;
    IBOutlet NSMenu *optionsMenu;
    IBOutlet NSSegmentedControl *listModeSelector;
    MainPanelListMode listMode;
}

- (IBAction)showOptionsMenu:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)syncNow:(id)sender;
- (IBAction)pauseAllDownloads:(id)sender;
- (IBAction)resumeAllDownloads:(id)sender;
- (IBAction)clearDownloads:(id)sender;
- (IBAction)quit:(id)sender;
- (IBAction)changeListMode:(id)sender;

@end
