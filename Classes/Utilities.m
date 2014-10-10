
#include <stdio.h>
#import "Utilities.h"

static BOOL _alreadyComputedOS = NO;
static BOOL _leopardOrGreater = NO;
static BOOL _yosemiteOrGreater = NO;

static void computeOS()
{
    SInt32 majorVersion, minorVersion;
    Gestalt(gestaltSystemVersionMajor, &majorVersion);
    Gestalt(gestaltSystemVersionMinor, &minorVersion);
    _leopardOrGreater = ((majorVersion == 10 && minorVersion >= 5) || majorVersion > 10);
    _yosemiteOrGreater = ((majorVersion == 10 && minorVersion >= 10) || majorVersion > 10);
    _alreadyComputedOS = YES;
}

BOOL leopardOrGreater(void)
{
    if (!_alreadyComputedOS) {
        computeOS();
    }
    return _leopardOrGreater;
}

BOOL yosemiteOrGreater(void)
{
    if (!_alreadyComputedOS) {
        computeOS();
    }
    return _yosemiteOrGreater;
}

NSString* unitStringFromBytes(double bytes)
{
    return unitStringFromBytes2(bytes, kUnitStringOSNativeUnits | kUnitStringLocalizedFormat);
}

NSString* unitStringFromBytes2(double bytes, uint8_t flags)
{
    static const char units[] = { '\0', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y' };
    static int maxUnits = sizeof units - 1;
    
    int multiplier = ((flags & kUnitStringOSNativeUnits && !leopardOrGreater()) || flags & kUnitStringBinaryUnits) ? 1024 : 1000;
    int exponent = 0;
    
    while (bytes >= multiplier && exponent < maxUnits) {
        bytes /= multiplier;
        exponent++;
    }
    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setMaximumFractionDigits:2];
    if (flags & kUnitStringLocalizedFormat) {
        [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    }
    // Beware of reusing this format string. -[NSString stringWithFormat] ignores \0, *printf does not.
    return [NSString stringWithFormat:@"%@ %cB", [formatter stringFromNumber: [NSNumber numberWithDouble: bytes]], units[exponent]];
}

NSString* unitStringFromSeconds(NSTimeInterval interval)
{
    interval = fabs(interval);
    static NSArray *unitsSingular;
    static NSArray *unitsPlural;
    if(!unitsSingular){
        unitsSingular = @[
                          NSLocalizedString(@"second", nil),
                          NSLocalizedString(@"minute", nil),
                          NSLocalizedString(@"hour", nil),
                          NSLocalizedString(@"day", nil)
                          ];
        unitsPlural = @[
                        NSLocalizedString(@"seconds", nil),
                        NSLocalizedString(@"minutes", nil),
                        NSLocalizedString(@"hours", nil),
                        NSLocalizedString(@"days", nil)
                        ];
    }
    static double multipliers[4];
    multipliers[0] = 1.0f;
    multipliers[1] = 60.0f;
    multipliers[2] = 60.0f * 60.0f;
    multipliers[3] = 60.0f * 60.0f * 24.0f;
    NSString *result = @"";
    for(int i = 3; i >= 0; i--){
        int value = (int)floor(interval / multipliers[i]);
        if(value > 0){
            if(i < 3 && i > 0){
                value %= (int)multipliers[i];
            }
            result = [result stringByAppendingFormat:@"%i %@ ", value, (value == 1 ? unitsSingular[i] : unitsPlural[i])];
            if(i == 1)
                break;
        }
    }
    return result;
}
