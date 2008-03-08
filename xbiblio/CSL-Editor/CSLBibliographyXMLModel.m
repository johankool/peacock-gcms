//
//  CSLBibliographyXMLModel.m
//  CSL Editor
//
//  Created by Johan Kool on 8-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "CSLBibliographyXMLModel.h"
#import "CSLReftypeXMLModel.h"

@implementation CSLBibliographyXMLModel

- (id)initWithXMLElement:(NSXMLElement *)aXMLElement
{
    self = [super init];
    if (self) {		
		[self setReftypes:[[NSMutableArray alloc] init]];

		[aXMLElement retain];
		bibliographyXMLElement = aXMLElement;
		
		NSArray *children = [bibliographyXMLElement children];
		int i, count = [children count];
		for (i=0; i < count; i++) {
			NSXMLElement *child = [children objectAtIndex:i];
			if ([[child name] isEqualToString:@"multiple-authors"]) {
				[child retain];
				multipleAuthorsElement = child;
			} else if ([[child name] isEqualToString:@"layout"]) {
				// handle child
				NSLog(@"dsfgdfgF");
				[self readReftypesFromXML:child];
			}			
		}
		
    }
    return self;
}

-(void)readReftypesFromXML:(NSXMLElement *)aXMLElement {
	NSArray *children = [aXMLElement children];
	int i, count = [children count];
	for (i=0; i < count; i++) {
		NSXMLElement *child = [children objectAtIndex:i];
		if ([[child name] isEqualToString:@"reftype"]) {
			NSLog(@"reftype %@", [child name]);
			CSLReftypeXMLModel *reftype = [[CSLReftypeXMLModel alloc] initWithXMLElement:child];
			[[self reftypes] addObject:reftype];
			[reftype release];
		}			
	}
	
}

- (id)valueForUndefinedKey:(NSString *)key {
	NSLog(@"CSLBibliographyXMLModel: key '%@' not defined, returning nil", key);
	return nil;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	NSLog(@"CSLBibliographyXMLModel: key '%@' not defined, value ignored", key);
}

-(int)minAuthors {
	return [[[multipleAuthorsElement attributeForName:@"min-authors"] objectValue] intValue];
}

-(void)setMinAuthors:(int)inValue {
	[[multipleAuthorsElement attributeForName:@"min-authors"] setStringValue:[[NSNumber numberWithInt:inValue] stringValue]];
}

-(int)useFirst {
	return [[[multipleAuthorsElement attributeForName:@"use-first"] objectValue] intValue];
}

-(void)setUseFirst:(int)inValue {
	[[multipleAuthorsElement attributeForName:@"use-first"] setStringValue:[[NSNumber numberWithInt:inValue] stringValue]];
}

-(NSString *)multipleAuthors {
	if (!multipleAuthorsElement) {
		return nil;
	}
	return [multipleAuthorsElement objectValue];
}

-(void)setMultipleAuthors:(NSString *)inValue {
	if (!multipleAuthorsElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"multiple-authors" stringValue:inValue];
		[bibliographyXMLElement addChild:newElement];
		multipleAuthorsElement = newElement;
	} else {
		[multipleAuthorsElement setObjectValue:inValue];		
	}
}

-(int)sortOrder {
	NSString *string = [[bibliographyXMLElement attributeForName:@"author-as-sort-order"] stringValue];
	if ([string isEqualToString:@"no"]) {
		return 0;
	} else if ([string isEqualToString:@"first-author"]) {
		return 1;
	}  else if ([string isEqualToString:@"all"]) {
		return 2;
	} 
	return 0;
}

-(void)setSortOrder:(int)inValue {
	switch (inValue) {
		case 0:
			[[bibliographyXMLElement attributeForName:@"author-as-sort-order"] setStringValue:@"no"];
			break;
		case 1:
			[[bibliographyXMLElement attributeForName:@"author-as-sort-order"] setStringValue:@"first-author"];
			break;
		case 2:
			[[bibliographyXMLElement attributeForName:@"author-as-sort-order"] setStringValue:@"all"];
			break;
		default:
			break;
	}
}

-(int)shortAuthor {
	NSString *string = [[bibliographyXMLElement attributeForName:@"author-shorten"] stringValue];
	if ([string isEqualToString:@"no"]) {
		return 0;
	} else if ([string isEqualToString:@"yes"]) {
		return 1;
	} 
	return 0;
}

-(void)setShortAuthor:(int)inValue {
	switch (inValue) {
		case 0:
			[[bibliographyXMLElement attributeForName:@"author-shorten"] setStringValue:@"no"];
			break;
		case 1:
			[[bibliographyXMLElement attributeForName:@"author-shorten"] setStringValue:@"yes"];
			break;
		default:
			break;
	}
}


-(int)fontStyle {
	//NSLog([[[xmlDoc rootElement] attributeForName:@"class"] stringValue]);
	NSString *string = [[multipleAuthorsElement attributeForName:@"font-style"] stringValue];
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
			[[multipleAuthorsElement attributeForName:@"font-style"] setStringValue:@"normal"];
			break;
		case 1:
			[[multipleAuthorsElement attributeForName:@"font-style"] setStringValue:@"italic"];
			break;
		case 2:
			[[multipleAuthorsElement attributeForName:@"font-style"] setStringValue:@"small caps"];
			break;
		default:
			break;
	}
}

-(int)fontWeight {
	//NSLog([[[xmlDoc rootElement] attributeForName:@"class"] stringValue]);
	NSString *string = [[multipleAuthorsElement attributeForName:@"font-weight"] stringValue];
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
			[[multipleAuthorsElement attributeForName:@"font-weight"] setStringValue:@"normal"];
			break;
		case 1:
			[[multipleAuthorsElement attributeForName:@"font-weight"] setStringValue:@"bold"];
			break;
		case 2:
			[[multipleAuthorsElement attributeForName:@"font-weight"] setStringValue:@"light"];
			break;
		default:
			break;
	}
}

-(NSString *)fontFamily {
	return [[multipleAuthorsElement attributeForName:@"font-family"] stringValue];
}

-(void)setFontFamily:(NSString *)inValue {
	[[multipleAuthorsElement attributeForName:@"font-family"] setStringValue:inValue];
}


idAccessor(reftypes, setReftypes);

@end
