
#import "SyncInstruction.h"
#import "PersistenceManager.h"

static NSMutableArray *allSyncInstructions;

@implementation SyncInstruction

+ (NSMutableArray*)allSyncInstructions
{
    if(!allSyncInstructions){
        // Load the sync instructions from disk
        allSyncInstructions = [PersistenceManager retrievePersistentObjectForKey:@"syncinstructions"];
        if(allSyncInstructions == nil)
            allSyncInstructions = [NSMutableArray array];
    }
    return allSyncInstructions;
}

+ (void)saveAllSyncInstructions;
{
    // Save the sync instructions to disk
    [PersistenceManager storePersistentObject:allSyncInstructions forKey:@"syncinstructions"];
}

- (id)init
{
    self = [super init];
    if (self) {
        _uniqueID = arc4random_uniform(INT32_MAX);
        self.deleteRemoteFilesAfterSync = NO;
        self.deleteRemoteEmptyFolders = NO;
        self.flattenSubdirectories = YES;
        self.recursive = YES;
        self.lastSynced = nil;
        [self resetKnownItems];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    
    _uniqueID = [decoder decodeIntegerForKey:@"uniqueID"];
    self.originFolderID = [decoder decodeIntegerForKey:@"originFolderID"];
    self.originFolderName = [decoder decodeObjectForKey:@"originFolderName"];
    self.deleteRemoteFilesAfterSync = [decoder decodeBoolForKey:@"deleteRemoteFilesAfterSync"];
    self.deleteRemoteEmptyFolders = [decoder decodeBoolForKey:@"deleteRemoteEmptyFolders"];
    self.flattenSubdirectories = [decoder decodeBoolForKey:@"flattenSubdirectories"];
    self.recursive = [decoder decodeBoolForKey:@"recursive"];
    self.lastSynced = [decoder decodeObjectForKey:@"lastSynced"];
    self.knownItems = [decoder decodeObjectForKey:@"knownItems"];
    NSError *error;
    BOOL isStale = NO;
    self.localDestination = [NSURL URLByResolvingBookmarkData:[decoder decodeObjectForKey:@"localDestinationBookmark"]
                                                     options:NSURLBookmarkResolutionWithoutUI
                                               relativeToURL:nil
                                         bookmarkDataIsStale:&isStale
                                                       error:&error];
    if(isStale || error != nil){
        self.localDestinationIsStale = YES;
        _bookmarkResolveError = error;
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:_uniqueID forKey:@"uniqueID"];
    [coder encodeInteger:self.originFolderID forKey:@"originFolderID"];
    [coder encodeObject:self.originFolderName forKey:@"originFolderName"];
    [coder encodeBool:self.deleteRemoteFilesAfterSync forKey:@"deleteRemoteFilesAfterSync"];
    [coder encodeBool:self.deleteRemoteEmptyFolders forKey:@"deleteRemoteEmptyFolders"];
    [coder encodeBool:self.flattenSubdirectories forKey:@"flattenSubdirectories"];
    [coder encodeBool:self.recursive forKey:@"recursive"];
    [coder encodeObject:self.lastSynced forKey:@"lastSynced"];
    [coder encodeObject:self.knownItems forKey:@"knownItems"];
    NSData *localDestinationBookmark = [self.localDestination bookmarkDataWithOptions:NSURLBookmarkCreationSuitableForBookmarkFile
                                                       includingResourceValuesForKeys:nil
                                                                        relativeToURL:nil
                                                                                error:nil];
    [coder encodeObject:localDestinationBookmark forKey:@"localDestinationBookmark"];
}

#pragma mark - Getters/Setters

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey
{
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"originFolderID"])
        automatic = NO;
    else
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    return automatic;
}

-(NSInteger)originFolderID
{
    @synchronized(self){
        return _originFolderID;
    }
}

-(void)setOriginFolderID:(NSInteger)originFolderID
{
    @synchronized(self){
        [self willChangeValueForKey:@"originFolderID"];
        _originFolderID = originFolderID;
        [self didChangeValueForKey:@"originFolderID"];
        [self resetKnownItems];
        self.lastSynced = nil;
    }
}

-(id)copyWithZone:(NSZone *)zone
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

-(void)resetKnownItems
{
    self.knownItems = [NSMutableArray array];
    self.lastSynced = nil;
    [SyncInstruction saveAllSyncInstructions];
}

-(void)addKnownItemWithID:(NSInteger)itemID
{
    [self.knownItems addObject:@(itemID)];
    [SyncInstruction saveAllSyncInstructions];
}

-(BOOL)itemWithIDIsKnown:(NSInteger)itemID
{
    for(NSNumber *number in self.knownItems)
        if([number isEqualToNumber:@(itemID)])
            return YES;
    return NO;
}

@end
