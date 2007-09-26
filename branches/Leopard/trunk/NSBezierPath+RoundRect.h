// From cocoa-dev mail list quoted to be from Reducer sample

#import <Cocoa/Cocoa.h>

@interface NSBezierPath (RoundRect)

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;
- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;

@end
