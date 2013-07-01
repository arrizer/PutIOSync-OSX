
#import <Foundation/Foundation.h>

@interface PersistenceManager : NSObject

+(id)retrievePersistentObjectForKey:(NSString*)key;
+(void)storePersistentObject:(id<NSCoding>)object forKey:(NSString*)key;

@end
