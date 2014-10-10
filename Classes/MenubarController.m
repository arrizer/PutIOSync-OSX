#import "MenubarController.h"
#import "StatusItemView.h"
#import "Utilities.h"

@implementation MenubarController

@synthesize statusItemView = _statusItemView;

#pragma mark -

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        NSImage *icon = [NSImage imageNamed:@"Status"];
        NSImage *iconHighlighted = [NSImage imageNamed:@"StatusHighlighted"];
        if (yosemiteOrGreater()) {
            icon = iconHighlighted;
            [icon setTemplate:YES];
            iconHighlighted = icon;
        }
        
        // Install status item into the menu bar
        NSStatusItem *statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:STATUS_ITEM_VIEW_WIDTH];
        _statusItemView = [[StatusItemView alloc] initWithStatusItem:statusItem];
        _statusItemView.image = icon;
        _statusItemView.alternateImage = icon;
        _statusItemView.alternateImage = iconHighlighted;
        _statusItemView.action = NSSelectorFromString(@"togglePanel:");
    }
    return self;
}

- (void)dealloc
{
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
}

#pragma mark -
#pragma mark Getters/Setters

- (NSStatusItem *)statusItem
{
    return self.statusItemView.statusItem;
}

- (BOOL)hasActiveIcon
{
    return self.statusItemView.isHighlighted;
}

- (void)setHasActiveIcon:(BOOL)flag
{
    self.statusItemView.isHighlighted = flag;
}

@end
