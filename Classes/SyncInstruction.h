
@import Foundation;
@import CoreData;


@interface SyncInstruction : NSManagedObject

@property (nonatomic, retain) NSNumber *originFolderID;
@property (nonatomic, retain) NSString *originFolderName;
@property (nonatomic, retain) NSData *localDestinationBookmark;
@property (nonatomic, retain) NSNumber *deleteRemoteFilesAfterSync;
@property (nonatomic, retain) NSNumber *deleteRemoteEmptyFolders;
@property (nonatomic, retain) NSNumber *recursive;
@property (nonatomic, retain) NSNumber *flattenSubdirectories;
@property (nonatomic, retain) NSDate *lastSynced;
@property (nonatomic, retain) NSSet *knownItems;

@property (strong) NSURL *localDestination;

+ (NSArray*)allSyncInstructions;

- (void)addKnownItemWithID:(NSInteger)itemID;
- (BOOL)itemWithIDIsKnown:(NSInteger)itemID;
- (void)resetKnownItems;

@end

@interface SyncInstruction (CoreDataGeneratedAccessors)

- (void)addKnownItemsObject:(NSManagedObject *)value;
- (void)removeKnownItemsObject:(NSManagedObject *)value;
- (void)addKnownItems:(NSSet *)values;
- (void)removeKnownItems:(NSSet *)values;

@end
