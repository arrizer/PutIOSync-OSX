
#import "SyncInstruction.h"
#import "KnownItem.h"
#import "Persistency.h"

@implementation SyncInstruction

@dynamic originFolderID;
@dynamic originFolderName;
@dynamic localDestinationBookmark;
@dynamic deleteRemoteFilesAfterSync;
@dynamic deleteRemoteEmptyFolders;
@dynamic recursive;
@dynamic flattenSubdirectories;
@dynamic lastSynced;
@dynamic knownItems;

@synthesize localDestination = _localDestination;

-(void)awakeFromInsert
{
    self.deleteRemoteFilesAfterSync = @(NO);
    self.deleteRemoteEmptyFolders = @(NO);
    self.flattenSubdirectories = @(YES);
    self.recursive = @(YES);
}

+ (NSArray *)allSyncInstructions
{
    NSFetchRequest *request = [[Persistency manager].model fetchRequestTemplateForName:@"AllSyncInstructions"];
    NSArray *objects = [[Persistency manager].context executeFetchRequest:request error:nil];
    return objects;
}

-(void)setLocalDestination:(NSURL *)localDestination
{
    _localDestination = localDestination;
    self.localDestinationBookmark = [self.localDestination bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                                                    includingResourceValuesForKeys:nil
                                                                     relativeToURL:nil
                                                                             error:nil];
}

-(NSURL *)localDestination
{
    if(_localDestination == nil && self.localDestinationBookmark != nil){
        NSError *error;
        BOOL isStale = NO;
        _localDestination =[NSURL URLByResolvingBookmarkData:self.localDestinationBookmark
                                                     options:NSURLBookmarkResolutionWithoutUI
                                               relativeToURL:nil
                                         bookmarkDataIsStale:&isStale
                                                       error:&error];
    }
    return _localDestination;
}

-(void)resetKnownItems
{
    for(KnownItem *item in [self knownItems]){
        [item.managedObjectContext deleteObject:item];
    }
}

-(void)addKnownItemWithID:(NSInteger)itemID
{
    KnownItem *item = [[KnownItem alloc] initWithEntity:[[Persistency manager] entityNamed:@"KnownItem"]
       insertIntoManagedObjectContext:self.managedObjectContext];
    item.itemID = @(itemID);
    [self addKnownItemsObject:item];
}

-(BOOL)itemWithIDIsKnown:(NSInteger)itemID
{
    for(KnownItem *item in [self knownItems]){
        if([item.itemID isEqual:@(itemID)]){
            return YES;
        }
    }
    return NO;
}

@end
