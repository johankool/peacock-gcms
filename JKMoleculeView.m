//
//  JKMoleculeView.m
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "JKMoleculeView.h"
#import "AccessorMacros.h"
#import "JKMoleculeModel.h"
//#import <LinkBack/LinkBack.h>

@implementation JKMoleculeView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self setBondColor:[NSColor blackColor]];
        [self setBackgroundColor:[NSColor windowBackgroundColor]];
        [self setTextColor:[NSColor blackColor]];
		[self setMargin:10];
		[self setFitToView:YES];
    }
    return self;
}

- (void) dealloc {
    [super dealloc];
}


- (void)drawRect:(NSRect)rect {
	if (![self model] | ([[[self model] atoms] count] == 0)) {
		NSString *noModelString = @"Structure data not available";
        NSSize noModelStringSize = [noModelString sizeWithAttributes:nil];
		[noModelString drawAtPoint:NSMakePoint([self bounds].size.width/2-noModelStringSize.width/2,[self bounds].size.height/2) withAttributes:nil];
		return;
	}
    if ([[[self model] atoms] count] > 0) {
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

		[self setBondDistance:[[self model] estimateLengthOfBonds]*0.7*[self yScaleFactor]/20];
		[self setTextHeight:[[self model] estimateLengthOfBonds]*0.7*[self yScaleFactor]/2];
		
		
    // Drawing code here.
    [self drawMolecule];
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
    for (i=0; i<[[[self model] bonds] count]; i++) {
        [bondsPath removeAllPoints];
        fromPoint = NSMakePoint([[[[[self model] bonds] objectAtIndex:i] fromAtom] x]*[self xScaleFactor]+[self xOffSet], [[[[[self model] bonds] objectAtIndex:i] fromAtom] y]*[self yScaleFactor]+[self yOffSet]);
         
        // Determine if this atom draws a label, switch to appropiate drawing type
        //
        // Find out what other bonds start or end at this bond
        // Add relevant bonds to arrays: single, double, triple
        // Count bonds and switch to case for it
        // Determine the start point(s) for this bond only!
        
        toPoint = NSMakePoint([[[[[self model] bonds] objectAtIndex:i] toAtom] x]*[self xScaleFactor]+[self xOffSet], [[[[[self model] bonds] objectAtIndex:i] toAtom] y]*[self yScaleFactor]+[self yOffSet]); 
        
        switch ([[[[self model] bonds] objectAtIndex:i] bondKind]) {
            case 1:
            default:
                // Draw a single bond
				 switch ([[[[self model] bonds] objectAtIndex:i] bondStereo]) {
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
    for (i=0; i<[[[self model] atoms] count]; i++) {
        name = [[[[self model] atoms] objectAtIndex:i] name];
        if (![name isEqualToString:@"C"]) {
            size = [name sizeWithAttributes:attrs];
			
			// Draw background
            background.origin = NSMakePoint([[[[self model] atoms] objectAtIndex:i] x]*[self xScaleFactor]+[self xOffSet], [[[[self model] atoms] objectAtIndex:i] y]*[self yScaleFactor]+[self yOffSet]);
            background.origin.x = background.origin.x - size.width/2 ;
            background.origin.y = background.origin.y - size.height/2 ;
            background.size.width = size.width ;
            background.size.height = size.height ;
			
			[[self backgroundColor] set];
			NSRectFill(background);
			
            // Center
            drawPoint = NSMakePoint([[[[self model] atoms] objectAtIndex:i] x]*[self xScaleFactor]+[self xOffSet], [[[[self model]  atoms] objectAtIndex:i] y]*[self yScaleFactor]+[self yOffSet]);
            drawPoint.x = drawPoint.x - size.width/2;
            drawPoint.y = drawPoint.y - size.height/2;
            
            [[self textColor] set];
            [name drawAtPoint:drawPoint withAttributes:attrs];
        }
    }
	
	
    
}
-(BOOL)canBecomeKeyView {
	return YES;
}
-(BOOL) acceptsFirstResponder{
    return YES;
}
-(BOOL) resignFirstResponder{
    return YES;
}
-(BOOL) becomeFirstResponder{
    return YES;
}

-(BOOL)isFlipped {
    return YES;
}
- (void)changeFont:(id)sender
{
    /*
     This is the message the font panel sends when a new font is selected
     */
	NSFont *oldFont = [self font]; 
    NSFont *newFont = [sender convertFont:oldFont]; 
	[self setFont:newFont]; 
    
    // Get and store details of selected font
    // Note: use fontName, not displayName.  The font name identifies the font to
    // the system, we use a value transformer to show the user the display name    
//    [[NSUserDefaults standardUserDefaults] setValue:[newFont fontName] forKey:@"fontName"];
	[self setNeedsDisplay:YES];
}

-(void)copy:(id)sender {
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    //Declare types of data you'll be putting onto the pasteboard
    myPboardTypes = [NSArray arrayWithObjects:NSPDFPboardType,nil];//LinkBackPboardType,nil];
    [pb declareTypes:myPboardTypes owner:self];
    //Copy the data to the pastboard
    data = [self dataWithPDFInsideRect:[self bounds]];
    [pb setData:data forType:NSPDFPboardType];
	
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

	//------
	
//	NSData *linkbackData = [NSKeyedArchiver archivedDataWithRootObject:[[self window] document]];
//	[pb setPropertyList:[NSDictionary linkBackDataWithServerName:@"Mole" appData:linkbackData] forType:LinkBackPboardType];
	
}


- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeInt:1 forKey:@"version"];
	[coder encodeFloat:margin forKey:@"margin"];
	[coder encodeFloat:scaleFactor forKey:@"scaleFactor"];
	[coder encodeObject:model forKey:@"model"];
	[coder encodeObject:backgroundColor forKey:@"backgroundColor"];
	[coder encodeObject:textColor forKey:@"textColor"];
	[coder encodeObject:bondColor forKey:@"bondColor"];
	[coder encodeObject:font forKey:@"font"];
	[coder encodeBool:fitToView forKey:@"fitToView"];

    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	margin = [coder decodeFloatForKey:@"margin"];
	scaleFactor = [coder decodeFloatForKey:@"scaleFactor"];
	model = [[coder decodeObjectForKey:@"model"] retain];
	backgroundColor = [[coder decodeObjectForKey:@"backgroundColor"] retain];
	textColor = [[coder decodeObjectForKey:@"textColor"] retain];
	bondColor = [[coder decodeObjectForKey:@"bondColor"] retain];
	font = [[coder decodeObjectForKey:@"font"] retain];
	fitToView = [coder decodeBoolForKey:@"fitToView"];
	
    return self;
}


-(void)startObserving {
	// Register to observe each of the new datapoints, and each of their observable properties
	NSEnumerator *dataEnumerator = [[[self model] atoms] objectEnumerator];
	JKAtom *newDataPoint;
	while ((newDataPoint = [dataEnumerator nextObject])) {		
		[newDataPoint addObserver:self forKeyPath:@"x" options:nil context:nil];
		[newDataPoint addObserver:self forKeyPath:@"y" options:nil context:nil];
		[newDataPoint addObserver:self forKeyPath:@"name" options:nil context:nil];
	}
	NSEnumerator *dataEnumerator2 = [[[self model] bonds] objectEnumerator];
	JKBond *newDataPoint2;
	while ((newDataPoint2 = [dataEnumerator2 nextObject])) {		
		[newDataPoint2 addObserver:self forKeyPath:@"fromAtom" options:nil context:nil];
		[newDataPoint2 addObserver:self forKeyPath:@"toAtom" options:nil context:nil];
		[newDataPoint2 addObserver:self forKeyPath:@"bondKind" options:nil context:nil];
		[newDataPoint2 addObserver:self forKeyPath:@"bondStereo" options:nil context:nil];
	}
	
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([keyPath isEqualToString:@"model"] | [keyPath isEqualToString:@"model.atoms"] |[keyPath isEqualToString:@"model.bonds"]){
		[self startObserving];
		[self setNeedsDisplay:YES];		
	} else {
		[self setNeedsDisplay:YES];		
	}
}
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

@end
