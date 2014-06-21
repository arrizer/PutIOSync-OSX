
#import <Foundation/Foundation.h>

@interface PersistenceManager : NSObject

+(instancetype)manager;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *model;
@property (readonly, strong, nonatomic) NSManagedObjectContext *context;

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

- (NSEntityDescription*)entityNamed:(NSString*)entityName;

//+(id)retrievePersistentObjectForKey:(NSString*)key;
//+(void)storePersistentObject:(id<NSCoding>)object forKey:(NSString*)key;

@end
