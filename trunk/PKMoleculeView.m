//
//  JKMoleculeView.m
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKMoleculeView.h"
#import "AccessorMacros.h"
#import "PKMoleculeModel.h"
#import "NSBezierPath+RoundRect.h"

//#import <LinkBack/LinkBack.h>

@implementation PKMoleculeView

#pragma mark Initialization & deallocation
+ (void)initialize {
	// Bindings support
	[self exposeBinding:@"moleculeString"];
}

- (NSArray *)exposedBindings
{
	return [NSArray arrayWithObjects:@"moleculeString", nil];	
}

- (Class)valueClassForBinding:(NSString *)binding
{
	if ([binding isEqualToString:@"moleculeString"]) {
		return [NSString class];
	}
	return nil;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        bondColor = [[NSColor blackColor] retain];
        backgroundColor = [[NSColor windowBackgroundColor] retain];
        textColor = [[NSColor blackColor] retain];
        margin = 10;
        fitToView = YES;
        xOffSet = 0.0f;
        yOffSet = 0.0f;
        scaleFactor = 1.0f;
        xScaleFactor = 1.0f;
        yScaleFactor = 1.0f;
        bondDistance = 1.0f;
        textHeight = 12.0f;;

        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
    }
    return self;
}

- (void) dealloc {
    [self unbind:@"moleculeString"];
    
    [bondColor release];
    [backgroundColor release];
    [textColor release];
 
    [super dealloc];
}

- (void)awakeFromNib {
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]]; 
}
#pragma mark -

#pragma mark NSView drawing
- (void)drawRect:(NSRect)rect {
	if (!model | ([[model atoms] count] == 0)) {
		NSString *noModelString = @"Structure data not available\nDrag-'n-drop a mol-file here";
        NSSize noModelStringSize = [noModelString sizeWithAttributes:nil];
		[noModelString drawAtPoint:NSMakePoint([self bounds].size.width/2-noModelStringSize.width/2,[self bounds].size.height/2-noModelStringSize.height/2) withAttributes:nil];
	}
    if ([[model atoms] count] > 0) {
		NSRect rectForBounds = [model rectForBounds];
		if (fitToView) {
			//[self setFrameSize:[[self superview] frame].size];

			[self setXScaleFactor:([self bounds].size.width-2*[self margin])/rectForBounds.size.width]; // margins are a weak implementation!
			[self setYScaleFactor:([self bounds].size.height-2*[self margin])/rectForBounds.size.height];
			// Proportional scaling:
			if ([self xScaleFactor] > [self yScaleFactor]) {
				[self setXScaleFactor:[self yScaleFactor]];
				[self setScaleFactor:[self yScaleFactor]];
			} else {
				[self setYScaleFactor:[self xScaleFactor]];
				[self setScaleFactor:[self xScaleFactor]];
			}
		} else {
			[self setXScaleFactor:[self scaleFactor]];
			[self setYScaleFactor:[self scaleFactor]];
			//[self setFrameSize:NSMakeSize([model rectForBounds].size.width*scaleFactor+2*margin,[model rectForBounds].size.height*scaleFactor+2*margin)];
			
		}
		[self setXOffSet:-rectForBounds.origin.x*[self xScaleFactor]+[self margin]];
		[self setYOffSet:-rectForBounds.origin.y*[self yScaleFactor]+[self margin]];			

		[self setBondDistance:[model estimateLengthOfBonds]*0.7*[self yScaleFactor]/20];
		[self setTextHeight:[model estimateLengthOfBonds]*0.7*[self yScaleFactor]/2];
		
        // Drawing code here.
        [self drawMolecule];
    }    
    if (_isTargettedForDrop) {
        NSRect insetRect = NSInsetRect([self frame], 10.0f, 10.0f);
        NSBezierPath *roundedRect = [NSBezierPath bezierPathWithRoundedRect:insetRect cornerRadius:10.0];
        
        [[NSColor alternateSelectedControlColor] set];
        [roundedRect setLineWidth:3.0];
        [roundedRect stroke];
    }
	if (([[self window] isKeyWindow]) && ([[self window] firstResponder] == self) && ([[NSGraphicsContext currentContext] isDrawingToScreen])) {
        [[NSColor keyboardFocusIndicatorColor] set]; 	    
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle (NSFocusRingOnly);
        
        // You need to *fill* the path (see the docs for NSSetFocusRingStyle())
        [[NSBezierPath bezierPathWithRect:NSInsetRect([self bounds],3.0f,3.0f)] fill];

        [NSGraphicsContext restoreGraphicsState];
    }    
}

- (void)drawMolecule {
    unsigned i;
    float alpha, beta, deltax, deltay, distance;

    NSPoint fromPoint, toPoint, drawPoint;
    NSBezierPath *bondsPath = [NSBezierPath bezierPath];
    NSSize size;
    NSRect background;
    NSString *name;
    NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	
	[[self backgroundColor] set];
	NSRectFill([self bounds]);

    // Setup for labels
    // Create font from name and size; initialize font panel
	font = [NSFont fontWithName:[[self font] fontName] size:[self textHeight]];
    if (font == nil)
    {
        font = [NSFont systemFontOfSize:[self textHeight]];
    }
	[attrs setObject:font forKey:NSFontAttributeName];
    [attrs setObject:[self textColor] forKey:NSForegroundColorAttributeName];

    // Draw bonds first
    for (i=0; i<[[model bonds] count]; i++) {
        [bondsPath removeAllPoints];
        fromPoint = NSMakePoint([[[[model bonds] objectAtIndex:i] fromAtom] x]*[self xScaleFactor]+[self xOffSet], [[[[model bonds] objectAtIndex:i] fromAtom] y]*[self yScaleFactor]+[self yOffSet]);
         
        // Determine if this atom draws a label, switch to appropiate drawing type
        //
        // Find out what other bonds start or end at this bond
        // Add relevant bonds to arrays: single, double, triple
        // Count bonds and switch to case for it
        // Determine the start point(s) for this bond only!
        
        toPoint = NSMakePoint([[[[model bonds] objectAtIndex:i] toAtom] x]*[self xScaleFactor]+[self xOffSet], [[[[model bonds] objectAtIndex:i] toAtom] y]*[self yScaleFactor]+[self yOffSet]); 
        
        switch ([[[model bonds] objectAtIndex:i] bondKind]) {
            case 1:
            default:
                // Draw a single bond
				 switch ([[[model bonds] objectAtIndex:i] bondStereo]) {
					 case 0:
					 case 4:
					 default:	 
						// No stereo
						[bondsPath moveToPoint:fromPoint];
						[bondsPath lineToPoint:toPoint];
						[[self bondColor] set];
						[bondsPath setLineWidth:1.0];
						[bondsPath stroke];
						 break;
					 case 1:
						 // Up
						 distance = [self bondDistance]*2.0;
						 alpha = atan((toPoint.y-fromPoint.y)/(toPoint.x-fromPoint.x));
						 beta = acos(-1)/2-alpha;
						 
						 deltax = distance * cos(beta);
						 deltay = distance * sin(beta);
						 
						 [bondsPath moveToPoint:fromPoint];
						 [bondsPath lineToPoint:NSMakePoint(toPoint.x-deltax, toPoint.y+deltay)];
						 [bondsPath lineToPoint:NSMakePoint(toPoint.x+deltax, toPoint.y-deltay)];
						 [bondsPath lineToPoint:fromPoint];
						 
						 [[self bondColor] set];
						 [bondsPath setLineWidth:1.0];
						 [bondsPath fill];
						 
						 break;
					 case 6:
						 // Down
						 distance = [self bondDistance]*2.0;
						 alpha = atan((toPoint.y-fromPoint.y)/(toPoint.x-fromPoint.x));
						 beta = acos(-1)/2-alpha;
						 
						 deltax = distance * cos(beta);
						 deltay = distance * sin(beta);
						 
						 [bondsPath moveToPoint:fromPoint];
						 [bondsPath lineToPoint:NSMakePoint(toPoint.x-deltax, toPoint.y+deltay)];
						 [bondsPath lineToPoint:NSMakePoint(toPoint.x+deltax, toPoint.y-deltay)];
						 [bondsPath lineToPoint:fromPoint];
						 
						 [[self bondColor] set];
						 [bondsPath setLineWidth:1.0];
						 [bondsPath stroke];
						 
						 break;
				 }
							 
				
                break;
            case 2:
                // Draw a double bond
                distance = [self bondDistance];
                alpha = atan((toPoint.y-fromPoint.y)/(toPoint.x-fromPoint.x));
                beta = acos(-1)/2-alpha;
                
                deltax = distance * cos(beta);
                deltay = distance * sin(beta);
                
                [bondsPath moveToPoint:NSMakePoint(fromPoint.x-deltax, fromPoint.y+deltay)];
                [bondsPath lineToPoint:NSMakePoint(toPoint.x-deltax, toPoint.y+deltay)];

                [bondsPath moveToPoint:NSMakePoint(fromPoint.x+deltax, fromPoint.y-deltay)];
                [bondsPath lineToPoint:NSMakePoint(toPoint.x+deltax, toPoint.y-deltay)];
				[[self bondColor] set];
				[bondsPath setLineWidth:1.0];
				[bondsPath stroke];
                
                break;
            case 3:
                // Draw a triple bond
                 distance = [self bondDistance]*2.0;
                alpha = atan((toPoint.y-fromPoint.y)/(toPoint.x-fromPoint.x));
                beta = acos(-1)/2-alpha; // acos(-1) = pi = 180 - 90 degrees
               
                deltax = distance * cos(beta);
                deltay = distance * sin(beta);
                
                [bondsPath moveToPoint:NSMakePoint(fromPoint.x-deltax, fromPoint.y+deltay)];
                [bondsPath lineToPoint:NSMakePoint(toPoint.x-deltax, toPoint.y+deltay)];
                
                [bondsPath moveToPoint:fromPoint];
                [bondsPath lineToPoint:toPoint];
                
                [bondsPath moveToPoint:NSMakePoint(fromPoint.x+deltax, fromPoint.y-deltay)];
                [bondsPath lineToPoint:NSMakePoint(toPoint.x+deltax, toPoint.y-deltay)];
				[[self bondColor] set];
				[bondsPath setLineWidth:1.0];
				[bondsPath stroke];
                
                break;
            case 4 :
                // Draw a benzene ring
                [bondsPath moveToPoint:fromPoint];
                [bondsPath lineToPoint:toPoint];
				[[self bondColor] set];
				[bondsPath setLineWidth:1.0];
				[bondsPath stroke];
				
                break;
         }
    }
	// Draw atoms now
    for (i=0; i<[[model atoms] count]; i++) {
        name = [[[model atoms] objectAtIndex:i] name];
        if (![name isEqualToString:@"C"]) {
            size = [name sizeWithAttributes:attrs];
			
			// Draw background
            background.origin = NSMakePoint([[[model atoms] objectAtIndex:i] x]*[self xScaleFactor]+[self xOffSet], [[[model atoms] objectAtIndex:i] y]*[self yScaleFactor]+[self yOffSet]);
            background.origin.x = background.origin.x - size.width/2 ;
            background.origin.y = background.origin.y - size.height/2 ;
            background.size.width = size.width ;
            background.size.height = size.height ;
			
			[[self backgroundColor] set];
			NSRectFill(background);
			
            // Center
            drawPoint = NSMakePoint([[[model atoms] objectAtIndex:i] x]*[self xScaleFactor]+[self xOffSet], [[[model  atoms] objectAtIndex:i] y]*[self yScaleFactor]+[self yOffSet]);
            drawPoint.x = drawPoint.x - size.width/2;
            drawPoint.y = drawPoint.y - size.height/2;
            
            [[self textColor] set];
            [name drawAtPoint:drawPoint withAttributes:attrs];
        }
    }
}

- (BOOL)canBecomeKeyView {
	return YES;
}
- (BOOL)acceptsFirstResponder{
    return YES;
}
- (BOOL)resignFirstResponder{
    [self setNeedsDisplay:YES];
    return YES;
}
- (BOOL)becomeFirstResponder{
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)isFlipped {
    return YES;
}
#pragma mark -

#pragma mark IBActions
- (void)changeFont:(id)sender
{
    /*
     This is the message the font panel sends when a new font is selected
     */
	NSFont *oldFont = [self font]; 
    NSFont *newFont = [sender convertFont:oldFont]; 
	[self setFont:newFont]; 
    
	[self setNeedsDisplay:YES];
}

- (void)copy:(id)sender 
{
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    //Declare types of data you'll be putting onto the pasteboard
    myPboardTypes = [NSArray arrayWithObjects:NSPDFPboardType,NSStringPboardType,nil];//LinkBackPboardType,nil];
    [pb declareTypes:myPboardTypes owner:self];
    //Copy the data to the pastboard
    data = [self dataWithPDFInsideRect:[self bounds]];
    [pb setData:data forType:NSPDFPboardType];
    if ([self moleculeString])
        [pb setString:[self moleculeString] forType:NSStringPboardType];
	

	//------
//	NSMutableData *appData = [[NSMutableData alloc] init];
//	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:appData]; 
//	[archiver encodeInt:1 forKey:@"version"];
//	[archiver encodeObject:model forKey:@"model"];
////	[archiver encodeFloat:margin forKey:@"margin"];
////	[archiver encodeFloat:scaleFactor forKey:@"scaleFactor"];
////	[archiver encodeObject:backgroundColor forKey:@"backgroundColor"];
////	[archiver encodeObject:textColor forKey:@"textColor"];
////	[archiver encodeObject:bondColor forKey:@"bondColor"];
////	[archiver encodeObject:font forKey:@"font"];
////	[archiver encodeBool:fitToView forKey:@"fitToView"];
////	[archiver encodeRect:[self frame] forKey:@"frame"];
//	[archiver finishEncoding];
//	[archiver release];
//	[pb setPropertyList:[NSDictionary linkBackDataWithServerName:@"Mole" appData:appData] forType:LinkBackPboardType];
	
}

- (void)delete:(id)sender 
{
    [moleculeStringContainer setValue:nil forKeyPath:moleculeStringKeyPath];
}

- (void)cut:(id)sender
{
    [self copy:self];
    [self delete:self];
}

- (void)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *pasteTypes = [NSArray arrayWithObjects:NSStringPboardType, nil];
    NSString *bestType = [pb availableTypeFromArray:pasteTypes];
    if (bestType != nil) {
        // pasteboard has data we can deal with
        [self setMoleculeString:[pb stringForType:NSStringPboardType]];
    }
}
#pragma mark -

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder{
	[super encodeWithCoder:coder];
	[coder encodeInt:1 forKey:@"version"];
	[coder encodeFloat:margin forKey:@"margin"];
	[coder encodeFloat:scaleFactor forKey:@"scaleFactor"];
	[coder encodeObject:backgroundColor forKey:@"backgroundColor"];
	[coder encodeObject:textColor forKey:@"textColor"];
	[coder encodeObject:bondColor forKey:@"bondColor"];
	[coder encodeObject:font forKey:@"font"];
	[coder encodeBool:fitToView forKey:@"fitToView"];

    return;
}

- (id)initWithCoder:(NSCoder *)coder{
	self = [super initWithCoder:coder];
	margin = [coder decodeFloatForKey:@"margin"];
	scaleFactor = [coder decodeFloatForKey:@"scaleFactor"];
	backgroundColor = [[coder decodeObjectForKey:@"backgroundColor"] retain];
	textColor = [[coder decodeObjectForKey:@"textColor"] retain];
	bondColor = [[coder decodeObjectForKey:@"bondColor"] retain];
	font = [[coder decodeObjectForKey:@"font"] retain];
	fitToView = [coder decodeBoolForKey:@"fitToView"];
	
    return self;
}
#pragma mark -

#pragma mark Key Value Observing
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([keyPath isEqualToString:[self moleculeStringKeyPath]]){
        [self updateModel];
		[self setNeedsDisplay:YES];		
	}
}
#pragma mark -

#pragma mark Bindings
- (void)bind:(NSString *)bindingName
    toObject:(id)observableObject
 withKeyPath:(NSString *)observableKeyPath
     options:(NSDictionary *)options{
	
    if ([bindingName isEqualToString:@"moleculeString"]) {		
		[self setMoleculeStringContainer:observableObject];
		[self setMoleculeStringKeyPath:observableKeyPath];
		[moleculeStringContainer addObserver:self
							  forKeyPath:moleculeStringKeyPath
								 options:(NSKeyValueObservingOptionNew |
										  NSKeyValueObservingOptionOld)
								 context:nil];		
        [self updateModel];
    }
    
	[super bind:bindingName
	   toObject:observableObject
	withKeyPath:observableKeyPath
		options:options];
    
    [self setNeedsDisplay:YES];
}


- (void)unbind:(NSString *)bindingName {
    if ([bindingName isEqualToString:@"moleculeString"])
	{
        [moleculeStringContainer removeObserver:self forKeyPath:moleculeStringKeyPath];            
		[self setMoleculeStringContainer:nil];
		[self setMoleculeStringKeyPath:nil];
        [self setModel:nil];
    }
	
	[super unbind:bindingName];
}

#pragma mark moleculeString bindings
- (NSString *)moleculeString {	
    if (!moleculeStringContainer) {
        return nil;
    }
    if (!moleculeStringKeyPath) {
        return nil;
    }
    return [moleculeStringContainer valueForKeyPath:moleculeStringKeyPath];	
}

- (void)setMoleculeString:(NSString *)aMoleculeString
{
    if (!aMoleculeString) {
        return;
    }
    if (moleculeStringContainer == (id)self) {
        return;
    }
    if (moleculeStringContainer && moleculeStringKeyPath) {
        [moleculeStringContainer setValue:aMoleculeString forKeyPath:moleculeStringKeyPath];
    }
}

//- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
//    PKLogDebug(@"%@: %@", key, value);
//}

- (NSObjectController *)moleculeStringContainer{
    return moleculeStringContainer; 
}
- (void)setMoleculeStringContainer:(NSArrayController *)aMoleculeStringContainer{
    if (moleculeStringContainer != aMoleculeStringContainer) {
        [moleculeStringContainer release];
        moleculeStringContainer = [aMoleculeStringContainer retain];
    }
}
- (NSString *)moleculeStringKeyPath{
    return moleculeStringKeyPath; 
}
- (void)setMoleculeStringKeyPath:(NSString *)aMoleculeStringKeyPath{
    if (moleculeStringKeyPath != aMoleculeStringKeyPath) {
        [moleculeStringKeyPath release];
        moleculeStringKeyPath = [aMoleculeStringKeyPath copy];
    }
}

- (void)updateModel
{
    if ([self moleculeString] == NSNoSelectionMarker) {
        
    } else if ([self moleculeString] == NSMultipleValuesMarker) {
        
    }
    if (![self moleculeString]) {
        [self setModel:nil];
        return;
    }
    if ([[self moleculeString] isKindOfClass:[NSString class]]) {
        PKMoleculeModel *newModel = [[[PKMoleculeModel alloc] initWithMoleculeString:[self moleculeString]] autorelease];
        [self setModel:newModel];
    } 
}
#pragma mark -

#pragma mark Accessors
#pragma mark (macrostyle)
floatAccessor(margin, setMargin)
floatAccessor(scaleFactor, setScaleFactor)
idAccessor(model, setModel)
idAccessor(backgroundColor, setBackgroundColor)
idAccessor(textColor, setTextColor)
idAccessor(bondColor, setBondColor)
idAccessor(font, setFont)
boolAccessor(fitToView, setFitToView)

// Not encoded:
floatAccessor(xOffSet, setXOffSet)
floatAccessor(yOffSet, setYOffSet)
floatAccessor(xScaleFactor, setXScaleFactor)
floatAccessor(yScaleFactor, setYScaleFactor)
floatAccessor(bondDistance, setBondDistance)
floatAccessor(textHeight, setTextHeight)
#pragma mark -

#pragma mark Drop Support (NSDraggingDestination)
// Before releasing image/mouse button
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    _isTargettedForDrop = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationGeneric;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    _isTargettedForDrop = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationGeneric;    
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
    _isTargettedForDrop = NO;
    [self setNeedsDisplay:YES];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
    _isTargettedForDrop = NO;
    [self setNeedsDisplay:YES];    
}

// After the image is released
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	BOOL isDirectory;
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
	if ([[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *filesComingIn = [pboard propertyListForType:NSFilenamesPboardType];
        // Do we get a real file?
        if ([[NSFileManager defaultManager] fileExistsAtPath:[filesComingIn objectAtIndex:0] isDirectory:&isDirectory]) {
            // Is it a folder? Do we accept it?
            if (isDirectory) {
                return NO;
            }
            NSString *molString = [NSString stringWithContentsOfFile:[filesComingIn objectAtIndex:0]];
            PKMoleculeModel *newModel = [[PKMoleculeModel alloc] initWithMoleculeString:molString];
            if (!newModel) {
                _isTargettedForDrop = NO;
                return NO;
            }
            if (moleculeStringContainer) {
                [moleculeStringContainer setValue:molString forKeyPath:moleculeStringKeyPath];
            }
        }
    } else if ([[pboard types] containsObject:NSStringPboardType] ) {
        NSString *molString = [pboard stringForType:NSStringPboardType];
        PKMoleculeModel *newModel = [[PKMoleculeModel alloc] initWithMoleculeString:molString];
        if (!newModel) {
            _isTargettedForDrop = NO;
            return NO;
        }
        if (moleculeStringContainer) {
            [moleculeStringContainer setValue:molString forKeyPath:moleculeStringKeyPath];
        }
    }

    _isTargettedForDrop = NO;
    [self setNeedsDisplay:YES];
    return YES;    
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
    _isTargettedForDrop = NO;
    [self setNeedsDisplay:YES];    
}

@synthesize _isTargettedForDrop;
@end
