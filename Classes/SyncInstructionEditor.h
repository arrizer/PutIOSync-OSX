
#import <Cocoa/Cocoa.h>
#import "SyncInstruction.h"
#import "PutIOFolderPicker.h"

@interface SyncInstructionEditor : NSWindowController
<PutIOFolderPickerDelegate>

@property (strong) SyncInstruction *syncInstruction;
//@property (unsafe_unretained) id<SyncInstructionEditorDelegate>delegate;

-(IBAction)pickOriginFolder:(id)sender;
-(IBAction)pickDestinationFolder:(id)sender;
-(IBAction)commit:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)optionsChanged:(id)sender;
-(IBAction)resetKnownItems:(id)sender;

@end