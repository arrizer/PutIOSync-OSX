
#import "PutIOFolderPicker.h"
#import "PutIOAPIFileRequest.h"

@interface PutIOFolderPicker ()

@end

@implementation PutIOFolderPicker
@synthesize pendingFetches = _pendingFetches;

- (id)init
{
    self = [super initWithWindowNibName:@"PutIOFolderPicker"];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

-(void)setPendingFetches:(NSInteger)pendingFetches
{
    _pendingFetches = pendingFetches;
    if(pendingFetches > 0){
        [activitySpinner startAnimation:self];
    }else{
        [activitySpinner stopAnimation:self];
    }
}

#pragma mark - Actions

-(void)chooseSelectedFolder:(id)sender
{
    if([outlineView selectedRow] != -1){
        NSTableCellView *selectedCellView = [outlineView viewAtColumn:0 row:[outlineView selectedRow] makeIfNecessary:YES];
        PutIOAPIFile *pickedFolder = [selectedCellView objectValue];
        [self.window close];
        if([_delegate respondsToSelector:@selector(folderPicker:didPickFolder:)])
            [_delegate folderPicker:self didPickFolder:pickedFolder];
    }
}

-(void)cancel:(id)sender
{
    [self.window close];
    if([_delegate respondsToSelector:@selector(folderPickerDidCancel:)])
        [_delegate folderPickerDidCancel:self];
}

#pragma mark - Outline View Delegate

-(PutIOAPIFile*)folderForOutlineItem:(id)item
{
    if(item == nil){
        return folderTree;
    }else{
        return (PutIOAPIFile*)item;
    }
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if(folderTree == nil)
        return NO;
    PutIOAPIFile *folder = [self folderForOutlineItem:item];
    if(folder.subfolders == nil){
        return YES;
    }else{
        return folder.subfolders.count > 0;
    }
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(folderTree == nil)
        return NO;
    PutIOAPIFile *folder = [self folderForOutlineItem:item];
    if(folder.subfolders == nil){
        if(folder != folderTree){
            [self fetchSubfoldersOfNode:item];
        }
        return 0;
    }else{
        return folder.subfolders.count;
    }
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    PutIOAPIFile *folder = [self folderForOutlineItem:item];
    return folder.subfolders[index];
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [self folderForOutlineItem:item];
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    [chooseButton setEnabled:([outlineView selectedRow] != -1)];
}

#pragma mark - Fetch Folder Listing

- (void)updateFolders
{
    folderTree = nil;
    [outlineView reloadData];
    [chooseButton setEnabled:NO];
    [self fetchSubfoldersOfNode:nil];
}

- (void)fetchSubfoldersOfNode:(PutIOAPIFile*)parent
{
    NSInteger folderID = 0;
    if(parent != nil){
        folderID = parent.fileID;
    }
    __block PutIOAPIFileRequest *request = [PutIOAPIFileRequest requestFilesInFolderWithID:folderID completion:^{
        self.pendingFetches--;
        if(request.error == nil && !request.isCancelled){
            PutIOAPIFile *node = parent;
            if(node == nil){
                folderTree = request.parentFolder;
                node = folderTree;
            }
            NSMutableArray *subfolders = [NSMutableArray array];
            for(PutIOAPIFile *file in request.files){
                if([file isFolder]){
                    [subfolders addObject:file];
                }
            }
            node.subfolders = subfolders;
            [outlineView reloadData];
        }else if(request.error != nil){
            [activitySpinner stopAnimation:self];
            [outlineView reloadData];
        }
    }];
    
    PutIOAPI *api = [PutIOAPI api];
    [api performRequest:request];
    self.pendingFetches++;


}

@end
