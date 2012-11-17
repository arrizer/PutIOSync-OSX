
#import <Foundation/Foundation.h>

@interface SyncInstruction : NSObject
<NSCoding, NSCopying>
{
    NSInteger _originFolderID;
}

+ (NSMutableArray*)allSyncInstructions;
+ (void)saveAllSyncInstructions;

@property (assign) NSInteger originFolderID;
@property (strong) NSString *originFolderName;
@property (strong) NSURL *localDestination;
@property (assign) BOOL localDestinationIsStale;
@property (assign) BOOL deleteRemoteFilesAfterSync;
@property (assign) BOOL recursive;
@property (assign) BOOL flattenSubdirectories;
@property (strong) NSDate *lastSynced;

@property (strong) NSMutableArray *knownItems;
@property (readonly) NSError *bookmarkResolveError;
@property (readonly) NSInteger uniqueID;

- (void)addKnownItemWithID:(NSInteger)itemID;
- (BOOL)itemWithIDIsKnown:(NSInteger)itemID;
- (void)resetKnownItems;

@end
