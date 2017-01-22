
#import "MainPanel.h"
#import "ApplicationDelegate.h"
#import "SyncScheduler.h"
#import "PutIODownloadManager.h"
#import "DownloadCellView.h"
#import "PutIOTransfersMonitor.h"
#import "TransferCellView.h"
#import "PanelRowView.h"

@implementation MainPanel

- (instancetype)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reloadTableData)
               name:SyncSchedulerSyncDidChangeNotification
             object:nil];
    [nc addObserver:self selector:@selector(reloadTableData)
               name:PutIODownloadAddedNotification
             object:nil];
    [nc addObserver:self selector:@selector(reloadTableData)
               name:PutIOTransfersMonitorUpdatedNotification
             object:nil];
    listMode = MainPanelListModeDownloads;
    listModeSelector.selectedSegment = listMode;
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[PutIOTransfersMonitor monitor] stopMonitoringTransfers];
}

-(void)openPanel
{
    [self adaptiveResizeAnimated:NO];
    if(listMode == MainPanelListModeTransfers)
        [[PutIOTransfersMonitor monitor] startMonitoringTransfers];
    else
        [[PutIOTransfersMonitor monitor] stopMonitoringTransfers];
    tableView.target = self;
    tableView.doubleAction = @selector(doubleClickTableViewRow:);
    [super openPanel];
}

-(void)reloadTableData
{
    [tableView reloadData];
    [self adaptiveResizeAnimated:YES];
}

- (void)adaptiveResizeAnimated:(BOOL)animate
{
    NSUInteger rowCount = MAX(2, [self numberOfRowsInTableView:tableView]);
    CGFloat maxHeight = NSHeight([NSScreen mainScreen].visibleFrame);
    CGSize size = CGSizeMake(420.0f, MIN(46.0f + (rowCount * 56.0f), maxHeight));
    NSRect frame = self.window.frame;
    NSRect statusRect = [self statusRectForWindow:self.window];
    
    frame.size = NSSizeFromCGSize(size);
    frame.origin.y = NSMaxY(statusRect) - NSHeight(frame);
    
    [NSAnimationContext beginGrouping];
    [NSAnimationContext currentContext].duration = (animate ? 0.2f : 0.0f);
    [[self.window animator] setFrame:frame display:YES];
    [NSAnimationContext endGrouping];
}

#pragma mark - Window Delegate

-(void)windowWillClose:(NSNotification *)notification
{
    [[PutIOTransfersMonitor monitor] stopMonitoringTransfers];
    [super windowWillClose:notification];
}

-(void)windowDidResignKey:(NSNotification *)notification
{
    if((self.window).visible)
        [[PutIOTransfersMonitor monitor] stopMonitoringTransfers];
    [super windowDidResignKey:notification];
}

#pragma mark - Actions

-(IBAction)showOptionsMenu:(id)sender
{
    NSRect frame = ((NSButton *)sender).frame;
    NSPoint menuOrigin = [((NSButton *)sender).superview convertPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height-27)
                                                               toView:nil];
    NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
                                         location:menuOrigin
                                    modifierFlags:0
                                        timestamp:0
                                     windowNumber:((NSButton *)sender).window.windowNumber
                                          context:((NSButton *)sender).window.graphicsContext
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
    [NSMenu popUpContextMenu:optionsMenu withEvent:event forView:(NSButton*)sender];
}

-(IBAction)showPreferences:(id)sender
{
    [(ApplicationDelegate*)NSApp.delegate showPreferences:self];
}

-(IBAction)quit:(id)sender
{
    [[NSApplication sharedApplication] terminate:nil];
}

-(IBAction)syncNow:(id)sender
{
    [[SyncScheduler sharedSyncScheduler] startSyncingAll];
}

- (IBAction)pauseAllDownloads:(id)sender
{
    for(Download *download in [[PutIODownloadManager manager] allDownloads])
        [download pauseDownload];
}

- (IBAction)resumeAllDownloads:(id)sender
{
    for(Download *download in [[PutIODownloadManager manager] allDownloads])
        [download startDownload];
}

-(IBAction)clearDownloads:(id)sender
{
    if(listMode == MainPanelListModeDownloads){
        [[PutIODownloadManager manager] clearDownloadList];
        [self reloadTableData];
    }else if(listMode == MainPanelListModeTransfers){
        
    }
}

- (IBAction)changeListMode:(id)sender
{
    NSInteger index = listModeSelector.selectedSegment;
    listMode = index;
    [self reloadTableData];
    if(listMode == MainPanelListModeTransfers)
        [[PutIOTransfersMonitor monitor] startMonitoringTransfers];
    else
        [[PutIOTransfersMonitor monitor] stopMonitoringTransfers];
}

- (IBAction)doubleClickTableViewRow:(id)sender
{
    NSInteger row = tableView.clickedRow;
    NSTableCellView *cell = [tableView viewAtColumn:0 row:row makeIfNecessary:NO];
    if([cell.objectValue isKindOfClass:[Download class]]){
        Download *download = (Download*)cell.objectValue;
        if(download.status == PutIODownloadStatusFinished){
            [[NSWorkspace sharedWorkspace] openFile:download.localFile];
        }
    }
}

#pragma mark - TableView Delegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(listMode == MainPanelListModeDownloads){
        return ([[SyncScheduler sharedSyncScheduler] runningSyncs].count + [[PutIODownloadManager manager] allDownloads].count);
    }else if(listMode == MainPanelListModeTransfers){
        return ([[PutIOTransfersMonitor monitor] allActiveTransfers].count);
    }
    return 0;
}

-(NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(listMode == MainPanelListModeDownloads){
        if(row < [[SyncScheduler sharedSyncScheduler] runningSyncs].count){
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"syncRunnerCell" owner:self];
            SyncRunner *runner = [[SyncScheduler sharedSyncScheduler] runningSyncs][row];
            cell.textField.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Syncing '%@'...", nil), runner.syncInstruction.originFolderName];
            return cell;
        }else{
            row -= [[SyncScheduler sharedSyncScheduler] runningSyncs].count;
            DownloadCellView *cell = [tableView makeViewWithIdentifier:@"downloadCell" owner:self];
            Download *download = [[PutIODownloadManager manager] allDownloads][row];
            cell.download = download;
            return cell;
        }
    }else if(listMode == MainPanelListModeTransfers){
        TransferCellView *cell = [tableView makeViewWithIdentifier:@"transferCell" owner:self];
        return cell;
    }
    return nil;
}

-(NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    return [[PanelRowView alloc] init];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(listMode == MainPanelListModeDownloads){
        if(row < [[SyncScheduler sharedSyncScheduler] runningSyncs].count){
            SyncRunner *runner = [[SyncScheduler sharedSyncScheduler] runningSyncs][row];
            return runner;
        }else{
            row -= [[SyncScheduler sharedSyncScheduler] runningSyncs].count;
            Download *download = [[PutIODownloadManager manager] allDownloads][row];
            return download;
        }
    }else if(listMode == MainPanelListModeTransfers){
        PutIOAPITransfer *transfer = [[PutIOTransfersMonitor monitor] allActiveTransfers][row];
        return transfer;
    }
    return nil;
}

@end
