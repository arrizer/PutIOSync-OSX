
#import "PanelRowView.h"

@implementation PanelRowView

-(void)drawSelectionInRect:(NSRect)dirtyRect
{
    NSRect selectionRect = NSInsetRect(self.bounds, 4.0f, 0.0f);
    [[NSColor alternateSelectedControlColor] setFill];
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:selectionRect xRadius:4.0f yRadius:5.0f];
    [path fill];
}

@end