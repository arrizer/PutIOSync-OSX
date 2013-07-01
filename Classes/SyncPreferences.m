
#import "SyncPreferences.h"
#import "SyncScheduler.h"
#import "PutIODownload.h"

@interface SyncPreferences ()

@end

@implementation SyncPreferences

- (id)init
{
    self = [super initWithNibName:@"SyncPreferences" bundle:nil];
    return self;
}

#pragma mark - PreferencesViewController

- (NSString *)identifier
{
    return @"SyncPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"syncIcon.png"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Synced Folders", @"Sync Preferences title");
}

-(void)viewWillAppear
{
    [tableView reloadData];
    [addButton setEnabled:([PutIOAPI oAuthAccessToken] != nil)];
}

#pragma mark - Actions

-(void)addSyncInstruction:(id)sender
{
    [self presentSyncInstrucionEditorFor:-1];
}

-(void)editSyncInstruction:(id)sender
{
    NSInteger row = [tableView rowForView:(NSView *)sender];
    [self presentSyncInstrucionEditorFor:row];
}

-(void)removeSelectedSyncInstructions:(id)sender
{
    NSIndexSet *indexesToDelete = [tableView selectedRowIndexes];
    [tableView removeRowsAtIndexes:indexesToDelete withAnimation:NSTableViewAnimationSlideUp];
    [[SyncInstruction allSyncInstructions] removeObjectsAtIndexes:indexesToDelete];
    [SyncInstruction saveAllSyncInstructions];
}

#pragma mark - TableView Delegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[SyncInstruction allSyncInstructions] count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    SyncInstruction *syncInstruction = [SyncInstruction allSyncInstructions][row];
    return syncInstruction;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    removeButton.enabled = ([tableView selectedRow] != -1);
}

#pragma mark - Edit Sync Instruction

- (void)presentSyncInstrucionEditorFor:(NSInteger)row
{
    if([PutIOAPI oAuthAccessToken] == nil)
        return;
    if(!syncInstructionEditor){
        syncInstructionEditor = [[SyncInstructionEditor alloc] init];
        syncInstructionEditor.delegate = self;
    }
    editedSyncInstructionIndex = row;
    if(row == -1)
        [syncInstructionEditor setSyncInstruction:nil];
    else
        [syncInstructionEditor setSyncInstruction:[SyncInstruction allSyncInstructions][row]];
    [NSApp beginSheet:syncInstructionEditor.window
       modalForWindow:self.view.window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}

-(void)syncInstructionEditorFinishedEditing:(SyncInstructionEditor *)editor
{
    [NSApp endSheet:syncInstructionEditor.window];
    SyncInstruction *editedItem = editor.syncInstruction;
    if(editedSyncInstructionIndex == -1){
        [[SyncInstruction allSyncInstructions] addObject:editedItem];
    }else{
        SyncInstruction *oldItem = [SyncInstruction allSyncInstructions][editedSyncInstructionIndex];
        // Cancel running syncs for the edited instruction, since the behaviour might have changed
        [[SyncScheduler sharedSyncScheduler] cancelSyncForInstruction:oldItem];
        
        // Unlink running downloads from the edited sync instruction
        for(PutIODownload *download in [PutIODownload allDownloads])
            if([download originatingSyncInstruction] == oldItem)
                [download unlinkFromOriginatingSyncInstruction];
        
        [[SyncInstruction allSyncInstructions] replaceObjectAtIndex:editedSyncInstructionIndex withObject:editedItem];
    }
    [tableView reloadData];
    [SyncInstruction saveAllSyncInstructions];
}

-(void)syncInstructionEditorCancelled:(SyncInstructionEditor *)editor
{
    [NSApp endSheet:syncInstructionEditor.window];
}

@end
