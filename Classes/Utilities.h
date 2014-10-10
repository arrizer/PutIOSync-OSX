
#include <stdio.h>

NSString* unitStringFromSeconds(NSTimeInterval interval);
NSString* unitStringFromBytes(double bytes);
NSString* unitStringFromBytes2(double bytes, uint8_t flags);

BOOL leopardOrGreater(void);
BOOL yosemiteOrGreater(void);

enum {
    kUnitStringBinaryUnits     = 1 << 0,
    kUnitStringOSNativeUnits   = 1 << 1,
    kUnitStringLocalizedFormat = 1 << 2
};
