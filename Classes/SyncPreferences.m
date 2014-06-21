
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
    [super viewWillAppear];
    [addButton setEnabled:[[PutIOAPI api] isAuthenticated]];
}

#pragma mark - Accessors

-(NSManagedObjectContext *)context
{
    return [PersistenceManager manager].context;
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

#pragma mark - Edit Sync Instruction

- (void)presentSyncInstrucionEditorFor:(NSInteger)row
{
    if(![[PutIOAPI api] isAuthenticated])
        return;
    if(!syncInstructionEditor){
        syncInstructionEditor = [[SyncInstructionEditor alloc] init];
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

@end
