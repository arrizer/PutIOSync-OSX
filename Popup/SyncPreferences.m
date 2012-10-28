
#import "SyncPreferences.h"

@interface SyncPreferences ()

@end

@implementation SyncPreferences

- (id)init
{
    self = [super initWithNibName:@"SyncPreferences" bundle:nil];
    return self;
}

-(void)loadView
{
    [super loadView];
    
    // Load the sync instructions from disk
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    NSData *data = [d objectForKey:@"syncInstructions"];
    if(data){
        syncInstructions = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }else{
        syncInstructions = [NSMutableArray array];
    }
}

-(void)saveSyncInstructions
{
    // Save the sync instructions to disk
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:syncInstructions];
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setObject:data forKey:@"syncInstructions"];
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

#pragma mark - Actions

-(void)addSyncInstruction:(id)sender
{
    [self presentSyncInstrucionEditorFor:nil];
}

-(void)editSyncInstruction:(id)sender
{
    NSInteger row = [tableView rowForView:(NSView *)sender];
    [self presentSyncInstrucionEditorFor:syncInstructions[row]];
}

-(void)removeSelectedSyncInstructions:(id)sender
{
    NSIndexSet *indexesToDelete = [tableView selectedRowIndexes];
    [tableView removeRowsAtIndexes:indexesToDelete withAnimation:NSTableViewAnimationSlideUp];
    [syncInstructions removeObjectsAtIndexes:indexesToDelete];
    [self saveSyncInstructions];
}

#pragma mark - TableView Delegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [syncInstructions count];
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    SyncInstruction *syncInstruction = syncInstructions[row];
    return syncInstruction;
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    removeButton.enabled = ([tableView selectedRow] != -1);
}

#pragma mark - Edit Sync Instruction

- (void)presentSyncInstrucionEditorFor:(SyncInstruction*)instruction
{
    if(!syncInstructionEditor){
        syncInstructionEditor = [[SyncInstructionEditor alloc] init];
        syncInstructionEditor.delegate = self;
    }
    if(instruction != nil)
        editedSyncInstructionIndex = [syncInstructions indexOfObject:instruction];
    else
        editedSyncInstructionIndex = -1;
    [syncInstructionEditor setSyncInstruction:instruction];
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
        [syncInstructions addObject:editedItem];
    }else{
        [syncInstructions replaceObjectAtIndex:editedSyncInstructionIndex withObject:editedItem];
    }
    [tableView reloadData];
    [self saveSyncInstructions];
}

-(void)syncInstructionEditorCancelled:(SyncInstructionEditor *)editor
{
    [NSApp endSheet:syncInstructionEditor.window];
}

@end
