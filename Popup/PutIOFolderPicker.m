
#import "PutIOFolderPicker.h"

@interface PutIOFolderPicker ()

@end

@implementation PutIOFolderPicker

- (id)init
{
    self = [super initWithWindowNibName:@"PutIOFolderPicker"];
    putio = [PutIOAPI apiWithDelegate:self];
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
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

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if(item == nil && folderTree == nil)
        return NO;
    if(item == nil)
        item = folderTree;
    return ([[(NSTreeNode*)item mutableChildNodes] count] > 0);
}


-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(item == nil && folderTree == nil)
        return 0;
    if(item == nil)
        item = folderTree;
    return [[(NSTreeNode*)item mutableChildNodes] count];
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if(item == nil)
        item = folderTree;
    return [[(NSTreeNode*)item mutableChildNodes] objectAtIndex:index];
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [(NSTreeNode*)item representedObject];
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    [chooseButton setEnabled:([outlineView selectedRow] != -1)];
}

#pragma mark - Fetch Folder Listing

- (void)updateFolders
{
    [putio cancel];
    folderTree = nil;
    [outlineView reloadData];
    [chooseButton setEnabled:NO];
    fileQueue = [NSMutableArray array];
    [fileQueue addObject:[NSNull null]];
    [activitySpinner startAnimation:self];
    [self fetchNextQueuedItem];
}

- (void)fetchNextQueuedItem
{
    if([fileQueue count] > 0){
        id nextNode = [fileQueue objectAtIndex:0];
        if(nextNode == [NSNull null]){
            [putio filesInRootFolder];
        }else{
            PutIOAPIFile *folder = (PutIOAPIFile*)[(NSTreeNode*)nextNode representedObject];
            [putio filesInFolderWithID:[folder fileID]];
        }
    }else{
        [activitySpinner stopAnimation:self];
        NSLog(@"Done updating all put.io folders");
        [outlineView reloadData];
    }
}

-(void)api:(PutIOAPI *)api didFinishRequest:(PutIOAPIRequest)request withResult:(id)result
{
    NSArray *files = result[@"files"];
    id currentNode = [fileQueue objectAtIndex:0];
    if(currentNode == [NSNull null]){
        NSTreeNode *node = [[NSTreeNode alloc] initWithRepresentedObject:result[@"parent"]];
        folderTree = node;
        currentNode = node;
    }
    for(PutIOAPIFile *file in files){
        if([file isFolder] && [currentNode isKindOfClass:[NSTreeNode class]]){
            NSTreeNode *node = [[NSTreeNode alloc] initWithRepresentedObject:file];
            [[(NSTreeNode*)currentNode mutableChildNodes] addObject:node];
            [fileQueue addObject:node];
        }
    }
    [fileQueue removeObjectAtIndex:0];
    [self fetchNextQueuedItem];
}

-(void)api:(PutIOAPI *)api didFailRequest:(PutIOAPIRequest)request withError:(NSError *)error
{
    [fileQueue removeAllObjects];
    [activitySpinner stopAnimation:self];

}

@end
