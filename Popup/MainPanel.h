
#import "PanelController.h"

@interface MainPanel : PanelController
<NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet NSTableView *tableView;
    IBOutlet NSMenu *optionsMenu;
}

- (IBAction)showOptionsMenu:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)syncNow:(id)sender;
- (IBAction)pauseAllDownloads:(id)sender;
- (IBAction)resumeAllDownloads:(id)sender;
- (IBAction)clearDownloads:(id)sender;
- (IBAction)quit:(id)sender;

@end
