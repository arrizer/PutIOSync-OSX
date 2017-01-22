
@import Foundation;

@interface PutIOAPIObject : NSObject
<NSCoding>
{
    id rawData;
}

@property (readonly) id rawData;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithRawData:(id)data NS_DESIGNATED_INITIALIZER;

// Helper functions

+ (NSDate*)dateFromRawDataString:(NSString*)dateString;

@end
