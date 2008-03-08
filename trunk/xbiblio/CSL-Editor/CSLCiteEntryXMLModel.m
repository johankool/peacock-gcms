//
//  CSLCiteEntryXMLModel.m
//  CSL Editor
//
//  Created by Johan Kool on 10-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "CSLCiteEntryXMLModel.h"


@implementation CSLCiteEntryXMLModel
- (id)initWithXMLElement:(NSXMLElement *)aXMLElement
{
    self = [super init];
    if (self) {		
		[self setChildren:[[NSMutableArray alloc] init]];

		[aXMLElement retain];
		citeEntryXMLElement = aXMLElement;
		
		NSArray *children2 = [citeEntryXMLElement children];
		int i, count = [children2 count];
		for (i=0; i < count; i++) {
			NSXMLElement *child = [children2 objectAtIndex:i];
			if ([[child name] isEqualToString:@"prefix"]) {
				[child retain];
				prefixElement = child;
			} else if ([[child name] isEqualToString:@"suffix"]) {
				[child retain];
				suffixElement = child;
			} else {
				// handle child by adding to layout
				CSLCiteEntryXMLModel *citeEntry = [[CSLCiteEntryXMLModel alloc] initWithXMLElement:child];
				// NSLog(@"citentry: %@", [child name]);
				[[self children] addObject:citeEntry];				
				[citeEntry release];
			}
			
		}
		// NSLog(@"CiteEntry %@ holds %d children.", [citeEntryXMLElement name], [children count]);
    }
    return self;
}

- (id)valueForUndefinedKey:(NSString *)key {
	NSLog(@"CSLCiteEntryXMLModel: key '%@' not defined, returning nil", key);
	return nil;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	NSLog(@"CSLCiteEntryXMLModel: key '%@' not defined, value ignored", key);
}

-(NSString *)label {
//	NSLog(@"citentry: name called: %@", [citeEntryXMLElement name]);

	return [citeEntryXMLElement name];
}

-(void)setLabel:(NSString *)inValue {
	[citeEntryXMLElement setName:inValue];		
}

-(NSString *)prefix {
	if (!prefixElement) {
		return nil;
	}
	return [prefixElement objectValue];
}

-(void)setPrefix:(NSString *)inValue {
	if (!prefixElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"prefix" stringValue:inValue];
		[citeEntryXMLElement addChild:newElement];
		prefixElement = newElement;
	} else {
		[prefixElement setObjectValue:inValue];		
	}
}

-(NSString *)suffix {
	if (!suffixElement) {
		return nil;
	}
	return [suffixElement objectValue];
}

-(void)setSuffix:(NSString *)inValue {
	if (!suffixElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"suffix" stringValue:inValue];
		[citeEntryXMLElement addChild:newElement];
		suffixElement = newElement;
	} else {
		[suffixElement setObjectValue:inValue];		
	}
}

-(int)fontStyle {
	//NSLog([[[xmlDoc rootElement] attributeForName:@"class"] stringValue]);
	NSString *string = [[citeEntryXMLElement attributeForName:@"font-style"] stringValue];
	if ([string isEqualToString:@"normal"]) {
		return 0;
	} else if ([string isEqualToString:@"italic"]) {
		return 1;
	}  else if ([string isEqualToString:@"small caps"]) {
		return 2;
	} 
	return 0;
}

-(void)setFontStyle:(int)inValue {
	switch (inValue) {
		case 0:
			[[citeEntryXMLElement attributeForName:@"font-style"] setStringValue:@"normal"];
			break;
		case 1:
			[[citeEntryXMLElement attributeForName:@"font-style"] setStringValue:@"italic"];
			break;
		case 2:
			[[citeEntryXMLElement attributeForName:@"font-style"] setStringValue:@"small caps"];
			break;
		default:
			break;
	}
}

-(int)fontWeight {
	//NSLog([[[xmlDoc rootElement] attributeForName:@"class"] stringValue]);
	NSString *string = [[citeEntryXMLElement attributeForName:@"font-weight"] stringValue];
	if ([string isEqualToString:@"normal"]) {
		return 0;
	} else if ([string isEqualToString:@"bold"]) {
		return 1;
	}  else if ([string isEqualToString:@"light"]) {
		return 2;
	} 
	return 0;
}

-(void)setFontWeight:(int)inValue {
	switch (inValue) {
		case 0:
			[[citeEntryXMLElement attributeForName:@"font-weight"] setStringValue:@"normal"];
			break;
		case 1:
			[[citeEntryXMLElement attributeForName:@"font-weight"] setStringValue:@"bold"];
			break;
		case 2:
			[[citeEntryXMLElement attributeForName:@"font-weight"] setStringValue:@"light"];
			break;
		default:
			break;
	}
}

-(NSString *)fontFamily {
	return [[citeEntryXMLElement attributeForName:@"font-family"] stringValue];
}

-(void)setFontFamily:(NSString *)inValue {
	[[citeEntryXMLElement attributeForName:@"font-family"] setStringValue:inValue];
}

-(int)count {
	return [[self children] count];
}

idAccessor(children, setChildren);

@end
