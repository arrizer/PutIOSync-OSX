
#import "MASPreferencesViewController.h"
#import "SyncInstructionEditor.h"
#import <Cocoa/Cocoa.h>

@interface SyncPreferences : NSViewController
<MASPreferencesViewController, NSTableViewDataSource, NSTableViewDelegate, SyncInstructionEditorDelegate>
{
    NSMutableArray *syncInstructions;
    SyncInstructionEditor *syncInstructionEditor;
    NSInteger editedSyncInstructionIndex;
    
    IBOutlet NSArrayController *syncInstructionsController;
    IBOutlet NSButton *removeButton;
    IBOutlet NSTableView *tableView;
}

@property (strong) NSMutableArray *syncInstrucions;

-(IBAction)addSyncInstruction:(id)sender;
-(IBAction)editSyncInstruction:(id)sender;
-(IBAction)removeSelectedSyncInstructions:(id)sender;

@end
