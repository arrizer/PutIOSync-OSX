
#import "MainPanel.h"
#import "ApplicationDelegate.h"
#import "SyncScheduler.h"
#import "PutIODownload.h"
#import "DownloadCellView.h"
#import "PutIOTransfersMonitor.h"
#import "TransferCellView.h"

@implementation MainPanel

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithDelegate:delegate];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reloadTableData) name:SyncDidBeginOrFinishNotification object:nil];
    [nc addObserver:self selector:@selector(reloadTableData) name:NewDownloadNotification object:nil];
    [nc addObserver:self selector:@selector(reloadTableData) name:TransfersUpdatedNotification object:nil];
    listMode = MainPanelListModeDownloads;
    [listModeSelector setSelectedSegment:listMode];
    [[PutIOTransfersMonitor monitor] startMonitoringTransfers];
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
    CGFloat maxHeight = NSHeight([[NSScreen mainScreen] visibleFrame]);
    CGSize size = CGSizeMake(420.0f, MIN(46.0f + (rowCount * 56.0f), maxHeight));
    NSRect frame = self.window.frame;
    NSRect statusRect = [self statusRectForWindow:self.window];
    
    frame.size = NSSizeFromCGSize(size);
    frame.origin.y = NSMaxY(statusRect) - NSHeight(frame);
    
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:(animate ? 0.2f : 0.0f)];
    [[self.window animator] setFrame:frame display:YES];
    [NSAnimationContext endGrouping];
}

#pragma mark - Actions

-(IBAction)showOptionsMenu:(id)sender
{
    NSRect frame = [(NSButton *)sender frame];
    NSPoint menuOrigin = [[(NSButton *)sender superview] convertPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height-27)
                                                               toView:nil];
    NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
                                         location:menuOrigin
                                    modifierFlags:NSLeftMouseDownMask // 0x100
                                        timestamp:0
                                     windowNumber:[[(NSButton *)sender window] windowNumber]
                                          context:[[(NSButton *)sender window] graphicsContext]
                                      eventNumber:0
                                       clickCount:1
                                         pressure:1];
    [NSMenu popUpContextMenu:optionsMenu withEvent:event forView:(NSButton*)sender];
}

-(IBAction)showPreferences:(id)sender
{
    [(ApplicationDelegate*)[NSApp delegate] showPreferences:self];
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
    for(PutIODownload *download in [PutIODownload allDownloads])
        [download pauseDownload];
}

- (IBAction)resumeAllDownloads:(id)sender
{
    for(PutIODownload *download in [PutIODownload allDownloads])
        [download startDownload];
}

-(IBAction)clearDownloads:(id)sender
{
    [PutIODownload clearDownloadList];
    [self reloadTableData];
}

- (IBAction)changeListMode:(id)sender
{
    NSInteger index = [listModeSelector selectedSegment];
    listMode = index;
    [self reloadTableData];
}

#pragma mark - TableView Delegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(listMode == MainPanelListModeDownloads){
        return ([[[SyncScheduler sharedSyncScheduler] runningSyncs] count] + [[PutIODownload allDownloads] count]);
    }else if(listMode == MainPanelListModeTransfers){
        return ([[[PutIOTransfersMonitor monitor] allActiveTransfers] count]);
    }
    return 0;
}

-(NSView *)tableView:(NSTableView *)aTableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(listMode == MainPanelListModeDownloads){
        if(row < [[[SyncScheduler sharedSyncScheduler] runningSyncs] count]){
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"syncRunnerCell" owner:self];
            SyncRunner *runner = [[SyncScheduler sharedSyncScheduler] runningSyncs][row];
            cell.textField.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Syncing '%@'...", nil), runner.syncInstruction.originFolderName];
            return cell;
        }else{
            row -= [[[SyncScheduler sharedSyncScheduler] runningSyncs] count];
            DownloadCellView *cell = [tableView makeViewWithIdentifier:@"downloadCell" owner:self];
            PutIODownload *download = [PutIODownload allDownloads][row];
            [cell setDownload:download];
            return cell;
        }
    }else if(listMode == MainPanelListModeTransfers){
        TransferCellView *cell = [tableView makeViewWithIdentifier:@"transferCell" owner:self];
        return cell;
    }
    return nil;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(listMode == MainPanelListModeDownloads){
        if(row < [[[SyncScheduler sharedSyncScheduler] runningSyncs] count]){
            SyncRunner *runner = [[SyncScheduler sharedSyncScheduler] runningSyncs][row];
            return runner;
        }else{
            row -= [[[SyncScheduler sharedSyncScheduler] runningSyncs] count];
            PutIODownload *download = [PutIODownload allDownloads][row];
            return download;
        }
    }else if(listMode == MainPanelListModeTransfers){
        PutIOAPITransfer *transfer = [[PutIOTransfersMonitor monitor] allActiveTransfers][row];
        return transfer;
    }
    return nil;
}

@end
