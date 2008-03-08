//
//  MODSInfoXMLModel.m
//  MODS Editor
//
//  Created by Johan Kool on 8-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MODSEntryXMLModel.h"

@implementation MODSEntryXMLModel

- (id)initWithXMLElement:(NSXMLElement *)aXMLElement
{
    self = [super init];
    if (self) {		
		[aXMLElement retain];
		entryXMLElement = aXMLElement;
		
		nameElements = [[NSMutableArray alloc] init];
		
		NSArray *children = [entryXMLElement children];
		int i, count = [children count];
		for (i=0; i < count; i++) {
			NSXMLElement *child = [children objectAtIndex:i];
			if ([[child name] isEqualToString:@"genre"]) {
				[child retain];
				genreElement = child;
			} else if ([[child name] isEqualToString:@"subject"]) {
				[child retain];
				subjectElement = child;
			} else if ([[child name] isEqualToString:@"typeOfResource"]) {
				[child retain];
				typeOfResourceElement = child;
			} else if ([[child name] isEqualToString:@"part"]) {
				[child retain];
				partElement = child;
			} else if ([[child name] isEqualToString:@"identifier"]) {
				[child retain];
				identifierElement = child;
			} else if ([[child name] isEqualToString:@"titleInfo"]) {
				[child retain];
				titleInfoElement = child;
			} else if ([[child name] isEqualToString:@"recordInfo"]) {
				[child retain];
				recordInfoElement = child;
			} else if ([[child name] isEqualToString:@"originInfo"]) {
				[child retain];
				originInfoElement = child;
			} else if ([[child name] isEqualToString:@"relatedItem"]) {
				[child retain];
				relatedItemElement = child;
			} else if ([[child name] isEqualToString:@"name"]) {
				[nameElements addObject:child];
			} 
			
		}
		
    }
    return self;
}

- (id)valueForUndefinedKey:(NSString *)key {
	NSLog(@"MODSEntryXMLModel: key '%@' not defined, returning nil", key);
	return nil;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	NSLog(@"MODSEntryXMLModel: key '%@' not defined, value ignored", key);
}

-(NSString *)citekey {
	return [[entryXMLElement attributeForName:@"ID"] stringValue];
}

-(void)setCitekey:(NSString *)inValue {
	[[entryXMLElement attributeForName:@"ID"] setStringValue:inValue];
}

-(NSString *)genre {
	if (!genreElement) {
		return nil;
	}
	return [genreElement objectValue];
}

-(void)setGenre:(NSString *)inValue {
	if (!genreElement) {
		// inserting new xmlelement
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"genre" stringValue:inValue];
		[entryXMLElement addChild:newElement];
		genreElement = newElement;
	} else {
		[genreElement setObjectValue:inValue];		
	}
}

-(NSString *)title {
	if (!titleInfoElement) {
		return nil;
	} else {
		NSArray *titles = [titleInfoElement elementsForName:@"title"];
		if ([titles count] > 0) {
			return [[titles objectAtIndex:0] objectValue];			
		} else {
			return nil;
		}
	}
}

-(void)setTitle:(NSString *)inValue {
	if (!titleInfoElement) {
		// inserting new xmlelement
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"titleInfo" stringValue:@""];
		[entryXMLElement addChild:newElement];
		titleInfoElement = newElement;
	} 
	
	NSArray *titles = [titleInfoElement elementsForName:@"title"];
	if ([titles count] > 0) {
		[[titles objectAtIndex:0] setObjectValue:inValue];			
	} else {
		// inserting new xmlelement
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"title" stringValue:inValue];
		[titleInfoElement addChild:newElement];
	}
}

-(NSString *)subTitle {
	if (!titleInfoElement) {
		return nil;
	} else {
		NSArray *titles = [titleInfoElement elementsForName:@"subTitle"];
		if ([titles count] > 0) {
			return [[titles objectAtIndex:0] objectValue];			
		} else {
			return nil;
		}
	}
}

-(void)setSubTitle:(NSString *)inValue {
	if (!titleInfoElement) {
		// inserting new xmlelement
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"titleInfo" stringValue:@""];
		[entryXMLElement addChild:newElement];
		titleInfoElement = newElement;
	} 
	
	NSArray *titles = [titleInfoElement elementsForName:@"subTitle"];
	if ([titles count] > 0) {
		[[titles objectAtIndex:0] setObjectValue:inValue];			
	} else {
		// inserting new xmlelement
		NSXMLElement *newElement = [[NSXMLElement alloc] initWithName:@"subTitle" stringValue:inValue];
		[titleInfoElement addChild:newElement];
	}
}

-(NSString *)journal {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./relatedItem/titleInfo/title"  error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setJournal:(NSString *)inValue {
	NSError *err = nil;
	NSXMLElement *relatedItemTitleInfoElement;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./relatedItem/titleInfo/title"  error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		if (!relatedItemElement) {
			relatedItemElement = [NSXMLElement elementWithName:@"relatedItem"];
			[entryXMLElement addChild:relatedItemElement];
		}
		if ([[relatedItemElement elementsForName:@"titleInfo"] count] < 1) {
			relatedItemTitleInfoElement = [NSXMLElement elementWithName:@"titleInfo"];
			[relatedItemElement addChild:relatedItemTitleInfoElement];
		}
		relatedItemTitleInfoElement = [[relatedItemElement elementsForName:@"titleInfo"] objectAtIndex:0];
		if ([[relatedItemElement elementsForName:@"title"] count] < 1) {
			relatedItemTitleElement = [NSXMLElement elementWithName:@"title"];
			[relatedItemElement addChild:relatedItemTitleInfoElement];
		}
		
		
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)volume {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part//detail[@type='volume']/number" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setVolume:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part//detail[@type='volume']/number" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)issue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part//detail[@type='issue']/number" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setIssue:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part//detail[@type='issue']/number" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)startPage {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part/extent/start" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setStartPage:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part/extent/start" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)endPage {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part/extent/end" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setEndPage:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@"./part/extent/end" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)date {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//originInfo/dateIssued" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setDate:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//originInfo/dateIssued" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)abstract {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//abstract" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setAbstract:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//abstract" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}
-(NSString *)file {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//location/file" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setFile:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//location/file" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)doi {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//location/doi" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setDoi:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//location/doi" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}

-(NSString *)url {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//location/url" error:&err];
	if ([nodes count] > 0 ) {
		return [[nodes objectAtIndex:0] objectValue];
	} else {
		return nil;
	}
}

-(void)setUrl:(NSString *)inValue {
	NSError *err = nil;
	NSArray *nodes = [entryXMLElement nodesForXPath:@".//location/url" error:&err];
	if ([nodes count] > 0 ) {
		[[nodes objectAtIndex:0] setObjectValue:inValue];
		return;
	} else {
#warning Incomplete implementation
		[NSException raise:@"Incomplete implementation" format:@"Incomplete implementation"];
		return ;
	}
}


idAccessor(nameElements, setNameElements);

@end
