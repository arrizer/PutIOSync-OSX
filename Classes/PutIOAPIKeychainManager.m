
#import "PutIOAPIKeychainManager.h"
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

@implementation PutIOAPIKeychainManager

static void *keychainServiceName = "PutIOSync";
static void *keychainAccountName = "APIOAuthToken";

+ (NSString*)keychainItemPassword
{
    OSStatus status;
    UInt32 passwordLength;
    void *passwordData = nil;
    SecKeychainItemRef itemRef = nil;
    NSString *password = nil;
    status = SecKeychainFindGenericPassword(NULL,
                                            (UInt32)strlen(keychainServiceName), keychainServiceName,
                                            (UInt32)strlen(keychainAccountName), keychainAccountName,
                                            &passwordLength, &passwordData, &itemRef);
    if(status == noErr){
        password = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
        SecKeychainItemFreeContent(NULL, passwordData);
        //NSLog(@"Successfully read keychain item");
    }else{
        if(status != noErr)
            NSLog(@"Failed to get keychain item: %@", (NSString*)CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
    }
    return password;
}

+ (void)setKeychainItemPassword:(NSString*)password
{
    OSStatus status;
    SecKeychainItemRef itemRef = nil;
    void *passwordData = (void*)[password cStringUsingEncoding:NSUTF8StringEncoding];
    // Check if the item is already in the keycain
    status = SecKeychainFindGenericPassword(NULL,
                                            (UInt32)strlen(keychainServiceName), keychainServiceName,
                                            (UInt32)strlen(keychainAccountName), keychainAccountName,
                                            NULL, NULL,
                                            &itemRef);
    if(status == noErr){
        // Update the existing item
        status = SecKeychainItemModifyAttributesAndData(itemRef, NULL, (UInt32)strlen(passwordData), passwordData);
        if(status != noErr)
            NSLog(@"Failed to update keychain item: %@", (NSString*)CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
    }else if(status == errSecItemNotFound){
        // Create a new item
        status = SecKeychainAddGenericPassword(NULL,
                                               (UInt32)strlen(keychainServiceName), keychainServiceName,
                                               (UInt32)strlen(keychainAccountName), keychainAccountName,
                                               (UInt32)strlen(passwordData), passwordData,
                                               NULL);
        if(status != noErr)
            NSLog(@"Failed to add new keychain item: %@", (NSString*)CFBridgingRelease(SecCopyErrorMessageString(status, NULL)));
    }
}

@end
