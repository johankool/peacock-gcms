//
//  CSLInfoXMLModel.m
//  CSL Editor
//
//  Created by Johan Kool on 8-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "CSLInfoXMLModel.h"

@implementation CSLInfoXMLModel

- (id)initWithXMLElement:(NSXMLElement *)aXMLElement
{
    self = [super init];
    if (self) {		
		[aXMLElement retain];
		infoXMLElement = aXMLElement;
		
		NSArray *children = [infoXMLElement children];
		int i, count = [children count];
		for (i=0; i < count; i++) {
			NSXMLElement *child = [children objectAtIndex:i];
			if ([[child name] isEqualToString:@"title"]) {
				[child retain];
				titleElement = child;
			} else if ([[child name] isEqualToString:@"title-short"]) {
				[child retain];
				shortTitleElement = child;
			} else if ([[child name] isEqualToString:@"version"]) {
				[child retain];
				versionElement = child;
			} else if ([[child name] isEqualToString:@"edition"]) {
				[child retain];
				editionElement = child;
			} else if ([[child name] isEqualToString:@"dateCreated"]) {
				[child retain];
				dateCreatedElement = child;
			} else if ([[child name] isEqualToString:@"dateModified"]) {
				[child retain];
				dateModifiedElement = child;
			} else if ([[child name] isEqualToString:@"field"]) {
				[child retain];
				fieldElement = child;
			} else if ([[child name] isEqualToString:@"description"]) {
				[child retain];
				descriptionElement = child;
			} else if ([[child name] isEqualToString:@"basedOnTitle"]) {
				[child retain];
				basedOnTitleElement = child;
			} else if ([[child name] isEqualToString:@"basedOnVersion"]) {
				[child retain];
				basedOnVersionElement = child;
			} 
			
		}
		
    }
    return self;
}

- (id)valueForUndefinedKey:(NSString *)key {
	NSLog(@"CSLInfoXMLModel: key '%@' not defined, returning nil", key);
	return nil;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	NSLog(@"CSLInfoXMLModel: key '%@' not defined, value ignored", key);
}


-(NSString *)title {
	if (!titleElement) {
		return nil;
	}
	return [titleElement objectValue];
}

-(void)setTitle:(NSString *)inValue {
	if (!titleElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"title" stringValue:inValue];
		[infoXMLElement addChild:newElement];
		titleElement = newElement;
	} else {
		[titleElement setObjectValue:inValue];		
	}
}

-(NSString *)shortTitle {
	if (!shortTitleElement) {
		return nil;
	}
	return [shortTitleElement objectValue];
}

-(void)setShortTitle:(NSString *)inValue {
	if (!shortTitleElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"title-short" stringValue:inValue];
		[infoXMLElement addChild:newElement];
		shortTitleElement = newElement;
	} else {
		[shortTitleElement setObjectValue:inValue];		
	}
}

-(int)version {
	if (!versionElement) {
		return nil;
	}
	return [[versionElement objectValue] intValue];
}

-(void)setVersion:(int)inValue {
	if (!versionElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"version" stringValue:[[NSNumber numberWithInt:inValue] stringValue]];
		[infoXMLElement addChild:newElement];
		versionElement = newElement;
	} else {
		[versionElement setObjectValue:[[NSNumber numberWithInt:inValue] stringValue]];			
	}
}

-(int)edition {
	if (!editionElement) {
		return nil;
	}
	return [[editionElement objectValue] intValue];
}

-(void)setEdition:(int)inValue {
	if (!editionElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"edition" stringValue:[[NSNumber numberWithInt:inValue] stringValue]];
		[infoXMLElement addChild:newElement];
		editionElement = newElement;
	} else {
		[editionElement setObjectValue:[[NSNumber numberWithInt:inValue] stringValue]];			
	}
}

-(NSString *)dateCreated {
	if (!dateCreatedElement) {
		return nil;
	}
	return [dateCreatedElement objectValue];
}

-(void)setDateCreated:(NSString *)inValue {
	if (!dateCreatedElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"dateCreated" stringValue:inValue];
		[infoXMLElement addChild:newElement];
		dateCreatedElement = newElement;
	} else {
		[dateCreatedElement setObjectValue:inValue];		
	}
}
-(NSString *)dateModified {
	if (!dateModifiedElement) {
		return nil;
	}
	return [dateModifiedElement objectValue];
}

-(void)setDateModified:(NSString *)inValue {
	if (!dateModifiedElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"dateModified" stringValue:inValue];
		[infoXMLElement addChild:newElement];
		dateModifiedElement = newElement;
	} else {
		[dateModifiedElement setObjectValue:inValue];		
	}
}
-(NSString *)field {
	if (!fieldElement) {
		return nil;
	}
	return [fieldElement objectValue];
}

-(void)setField:(NSString *)inValue {
	if (!fieldElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"field" stringValue:inValue];
		[infoXMLElement addChild:newElement];
		fieldElement = newElement;
	} else {
		[fieldElement setObjectValue:inValue];		
	}
}

-(NSString *)description {
	if (!descriptionElement) {
		return nil;
	}
	return [descriptionElement objectValue];
}

-(void)setDescription:(NSString *)inValue {
	if (!descriptionElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"description" stringValue:inValue];
		[infoXMLElement addChild:newElement];
		descriptionElement = newElement;
	} else {
		[descriptionElement setObjectValue:inValue];		
	}
}

-(NSString *)basedOnTitle {
	if (!basedOnTitleElement) {
		return nil;
	}
	return [basedOnTitleElement objectValue];
}

-(void)setBasedOnTitle:(NSString *)inValue {
	if (!basedOnTitleElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"basedOnTitle" stringValue:inValue];
		[infoXMLElement addChild:newElement];
		basedOnTitleElement = newElement;
	} else {
		[basedOnTitleElement setObjectValue:inValue];		
	}
}

-(int)basedOnVersion {
	if (!basedOnVersionElement) {
		return nil;
	}
	return [[basedOnVersionElement objectValue] intValue];
}

-(void)setBasedOnVersion:(int)inValue {
	if (!basedOnVersionElement) {
		//NSLog(@"inserting new xmlelement");
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"basedOnVersion" stringValue:[[NSNumber numberWithInt:inValue] stringValue]];
		[infoXMLElement addChild:newElement];
		basedOnVersionElement = newElement;
	} else {
		[basedOnVersionElement setObjectValue:[[NSNumber numberWithInt:inValue] stringValue]];			
	}
}

@end
