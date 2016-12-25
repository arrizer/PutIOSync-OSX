
@import Foundation;
@import CoreData;

@class SyncInstruction;

@interface KnownItem : NSManagedObject

@property (nonatomic, retain) NSNumber *itemID;
@property (nonatomic, retain) SyncInstruction *syncInstruction;

@end
