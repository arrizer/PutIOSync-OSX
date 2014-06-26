
#import "SyncInstructionEditor.h"

@interface SyncInstructionEditor()
{
    SyncInstruction *_originalSyncInstruction;
    SyncInstruction *_editedSyncInstruction;
    PutIOFolderPicker *folderPicker;
    NSManagedObjectContext *context;
    
    IBOutlet NSTextField *originLabel;
    IBOutlet NSTextField *destinationLabel;
    IBOutlet NSTextField *lastSyncLabel;
    IBOutlet NSButton *commitButton;
    IBOutlet NSButton *deleteAfterSyncCheckbox;
    IBOutlet NSButton *deleteEmptyFoldersCheckbox;
    IBOutlet NSButton *recursiveCheckbox;
    IBOutlet NSButton *flattenCheckbox;
    IBOutlet NSButton *resetKnownItemsButton;
}

@end

@implementation SyncInstructionEditor

- (id)init
{
    self = [super initWithWindowNibName:NSStringFromClass([self class])];
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.parentContext = [[Persistency manager] context];
    return self;
}

-(void)setSyncInstruction:(SyncInstruction *)syncInstruction
{
    _originalSyncInstruction = syncInstruction;
    if(_originalSyncInstruction == nil){
        // New sync instruction
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"SyncInstruction" inManagedObjectContext:context];
        _editedSyncInstruction = [[SyncInstruction alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    }else{
        // Make a copy in case the user cancels the editing process
        _editedSyncInstruction = (SyncInstruction*)[context existingObjectWithID:[syncInstruction objectID] error:nil];
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
    [deleteAfterSyncCheckbox setState:([_editedSyncInstruction.deleteRemoteFilesAfterSync boolValue] ? NSOnState : NSOffState)];
    [deleteEmptyFoldersCheckbox setState:([_editedSyncInstruction.deleteRemoteEmptyFolders boolValue] ? NSOnState : NSOffState)];
    [recursiveCheckbox setState:([_editedSyncInstruction.recursive boolValue] ? NSOnState : NSOffState)];
    if([_editedSyncInstruction.recursive boolValue]){
        [flattenCheckbox setState:([_editedSyncInstruction.flattenSubdirectories boolValue] ? NSOnState : NSOffState)];
        [flattenCheckbox setEnabled:YES];
    }else{
        [flattenCheckbox setState:NSOffState];
        [flattenCheckbox setEnabled:NO];
    }
    if(_editedSyncInstruction.lastSynced != nil){
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        NSString *dateString = [dateFormatter stringFromDate:_editedSyncInstruction.lastSynced];
        lastSyncLabel.stringValue = [NSString stringWithFormat:NSLocalizedString(@"Last sync: %@",nil), dateString];
        [resetKnownItemsButton setEnabled:YES];
    }else{
        lastSyncLabel.stringValue = NSLocalizedString(@"Last sync: never", nil);
        [resetKnownItemsButton setEnabled:NO];
    }
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
    if(folder.fileID != [_originalSyncInstruction.originFolderID integerValue]){
        _editedSyncInstruction.originFolderID = @(folder.fileID);
        _editedSyncInstruction.originFolderName = folder.name;
    }
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
    _editedSyncInstruction.deleteRemoteFilesAfterSync = @(deleteAfterSyncCheckbox.state == NSOnState);
    _editedSyncInstruction.deleteRemoteEmptyFolders = @(deleteEmptyFoldersCheckbox.state == NSOnState);
    _editedSyncInstruction.recursive = @(recursiveCheckbox.state == NSOnState);
    _editedSyncInstruction.flattenSubdirectories = @(flattenCheckbox.state == NSOnState);
    [self updateLabels];
}

-(void)resetKnownItems:(id)sender
{
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Are you sure that you want to forget all previously synced items",nil)
                                     defaultButton:NSLocalizedString(@"Forget synced items",nil)
                                   alternateButton:NSLocalizedString(@"Cancel",nil)
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"After forgetting all syned items, files that have already been downloaded but are still available at the put.io origin folder will be downloaded again",nil)];
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if(returnCode == NSAlertDefaultReturn){
        [_originalSyncInstruction resetKnownItems];
        [_editedSyncInstruction resetKnownItems];
        [self updateLabels];
    }
}

-(IBAction)commit:(id)sender
{
    if(_originalSyncInstruction){
        // Update the last sync time and known items since they might have changed since
        // we made a copy of the sync instruction being edited
        _editedSyncInstruction.knownItems = _originalSyncInstruction.knownItems;
        _editedSyncInstruction.lastSynced = _originalSyncInstruction.lastSynced;
    }
    [context performBlock:^{
        [context save:nil];
        [context.parentContext performBlock:^{
            [context.parentContext save:nil];
        }];
    }];
    
    _editedSyncInstruction = nil;
    [self.window close];
    [NSApp endSheet:self.window];
}

-(IBAction)cancel:(id)sender
{
    [context reset];
    _editedSyncInstruction = nil;
    [self.window close];
    [NSApp endSheet:self.window];
}

@end
