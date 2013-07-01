
#include <stdio.h>

NSString* unitStringFromSeconds(NSTimeInterval interval);
NSString* unitStringFromBytes(double bytes);
NSString* unitStringFromBytes2(double bytes, uint8_t flags);

enum {
    kUnitStringBinaryUnits     = 1 << 0,
    kUnitStringOSNativeUnits   = 1 << 1,
    kUnitStringLocalizedFormat = 1 << 2
};