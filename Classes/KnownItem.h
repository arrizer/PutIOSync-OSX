
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SyncInstruction;

@interface KnownItem : NSManagedObject

@property (nonatomic, retain) NSNumber *itemID;
@property (nonatomic, retain) SyncInstruction *syncInstruction;

@end
