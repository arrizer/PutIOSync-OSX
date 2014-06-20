
#import <Foundation/Foundation.h>

@interface PutIOAPIKeychainManager : NSObject

+ (NSString*)keychainItemPassword;
+ (void)setKeychainItemPassword:(NSString*)password;

@end
