
#import <Cocoa/Cocoa.h>
#import "SyncInstruction.h"
#import "PutIOFolderPicker.h"

@class SyncInstructionEditor;
@protocol SyncInstructionEditorDelegate <NSObject>
-(void)syncInstructionEditorFinishedEditing:(SyncInstructionEditor*)editor;
-(void)syncInstructionEditorCancelled:(SyncInstructionEditor*)editor;
@end

@interface SyncInstructionEditor : NSWindowController
<PutIOFolderPickerDelegate>
{
    SyncInstruction *_originalSyncInstruction;
    SyncInstruction *_editedSyncInstruction;
    PutIOFolderPicker *folderPicker;
    
    IBOutlet NSTextField *originLabel;
    IBOutlet NSTextField *destinationLabel;
    IBOutlet NSTextField *lastSyncLabel;
    IBOutlet NSButton *commitButton;
    IBOutlet NSButton *deleteAfterSyncCheckbox;
    IBOutlet NSButton *recursiveCheckbox;
    IBOutlet NSButton *flattenCheckbox;
    IBOutlet NSButton *resetKnownItemsButton;
}

@property (strong) SyncInstruction *syncInstruction;
@property (weak) id<SyncInstructionEditorDelegate>delegate;

-(IBAction)pickOriginFolder:(id)sender;
-(IBAction)pickDestinationFolder:(id)sender;
-(IBAction)commit:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)optionsChanged:(id)sender;
-(IBAction)resetKnownItems:(id)sender;

@end