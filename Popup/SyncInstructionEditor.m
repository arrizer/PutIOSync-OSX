
#import "SyncInstructionEditor.h"

@implementation SyncInstructionEditor

- (id)init
{
    self = [super initWithWindowNibName:NSStringFromClass([self class])];
    return self;
}

-(void)setSyncInstruction:(SyncInstruction *)syncInstruction
{
    _originalSyncInstruction = syncInstruction;
    if(_originalSyncInstruction == nil){
        // New sync instruction
        _editedSyncInstruction = [[SyncInstruction alloc] init];
    }else{
        // Make a copy in case the user cancels the editing process
        _editedSyncInstruction = [_originalSyncInstruction copy];
    }
    [self updateLabels];
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    [self updateLabels];
}

-(SyncInstruction *)syncInstruction
{
    return _originalSyncInstruction;
}

-(void)updateLabels
{
    if(_originalSyncInstruction == nil){
        commitButton.stringValue = NSLocalizedString(@"Create", nil);
    }else{
        commitButton.stringValue = NSLocalizedString(@"Save", nil);
    }
    if(_editedSyncInstruction.originFolderName != nil){
        originLabel.stringValue = _editedSyncInstruction.originFolderName;
        [originLabel setHidden:NO];
    }else{
        [originLabel setHidden:YES];
    }
    if(_editedSyncInstruction.localDestination != nil){
        destinationLabel.stringValue = [[_editedSyncInstruction.localDestination relativePath] lastPathComponent];
        [destinationLabel setHidden:NO];
    }else{
        [destinationLabel setHidden:YES];
    }
    [deleteAfterSyncCheckbox setState:(_editedSyncInstruction.deleteRemoteFilesAfterSync ? NSOnState : NSOffState)];
    BOOL configurationIsValid = (_editedSyncInstruction.originFolderName != nil && _editedSyncInstruction.localDestination != nil);
    [commitButton setEnabled:configurationIsValid];
}

#pragma mark - Actions

-(IBAction)pickOriginFolder:(id)sender
{
    if(!folderPicker){
        folderPicker = [[PutIOFolderPicker alloc] init];
        folderPicker.delegate = self;
    }
    [NSApp beginSheet:folderPicker.window
       modalForWindow:self.window
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
    [folderPicker updateFolders];
}

-(void)folderPicker:(PutIOFolderPicker *)picker didPickFolder:(PutIOAPIFile *)folder
{
    [NSApp endSheet:folderPicker.window];
    _editedSyncInstruction.originFolderID = folder.fileID;
    _editedSyncInstruction.originFolderName = folder.name;
    [self updateLabels];
}

-(void)folderPickerDidCancel:(PutIOFolderPicker *)picker
{
    [NSApp endSheet:folderPicker.window];
}

-(IBAction)pickDestinationFolder:(id)sender
{
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setCanCreateDirectories:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSArray* urls = [panel URLs];
            if([urls count] == 1){
                _editedSyncInstruction.localDestination = urls[0];
                [self updateLabels];
            }
        }
    }];
}

-(void)optionsChanged:(id)sender
{
    _editedSyncInstruction.deleteRemoteFilesAfterSync = (deleteAfterSyncCheckbox.state == NSOnState);
}

-(IBAction)commit:(id)sender
{
    _originalSyncInstruction = _editedSyncInstruction;
    _editedSyncInstruction = nil;
    [self.window close];
    if([_delegate respondsToSelector:@selector(syncInstructionEditorFinishedEditing:)])
        [_delegate syncInstructionEditorFinishedEditing:self];
}

-(IBAction)cancel:(id)sender
{
    _editedSyncInstruction = nil;
    [self.window close];
    if([_delegate respondsToSelector:@selector(syncInstructionEditorCancelled:)])
        [_delegate syncInstructionEditorCancelled:self];
}

@end
