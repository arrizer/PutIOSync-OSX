
#import "MASPreferencesViewController.h"
#import "SyncInstructionEditor.h"
#import <Cocoa/Cocoa.h>

@interface SyncPreferences : NSViewController
<MASPreferencesViewController, NSTableViewDelegate>
{
    SyncInstructionEditor *syncInstructionEditor;
    NSInteger editedSyncInstructionIndex;
    
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *removeButton;
    IBOutlet NSTableView *tableView;
}

@property (strong) NSMutableArray *syncInstrucions;
@property (readonly) NSManagedObjectContext *context;

-(IBAction)addSyncInstruction:(id)sender;
-(IBAction)editSyncInstruction:(id)sender;

@end
