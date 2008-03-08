//
//  CSLReftypeXMLModel.m
//  CSL Editor
//
//  Created by Johan Kool on 10-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "CSLReftypeXMLModel.h"
#import "CSLCiteEntryXMLModel.h"

@implementation CSLReftypeXMLModel
- (id)initWithXMLElement:(NSXMLElement *)aXMLElement
{
    self = [super init];
    if (self) {		
		[self setLayout:[[NSMutableArray alloc] init]];
		
		[aXMLElement retain];
		reftypeXMLElement = aXMLElement;
		
		NSArray *children = [reftypeXMLElement children];
		int i, count = [children count];
		for (i=0; i < count; i++) {
			NSXMLElement *child = [children objectAtIndex:i];
			// handle child by adding to layout
			CSLCiteEntryXMLModel *citeEntry = [[CSLCiteEntryXMLModel alloc] initWithXMLElement:child];
			//NSLog(@"citentry: %@", [child name]);
			[[self layout] insertObject:citeEntry atIndex:i];
			[citeEntry release];
		}
    }
    return self;
}

- (id)valueForUndefinedKey:(NSString *)key {
	NSLog(@"CSLReftypeXMLModel: key '%@' not defined, returning nil", key);
	return nil;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	NSLog(@"CSLReftypeXMLModel: key '%@' not defined, value ignored", key);
}

-(NSString *)name {
	return [[reftypeXMLElement attributeForName:@"name"] stringValue];
}

-(void)setName:(NSString *)inValue {
	[[reftypeXMLElement attributeForName:@"name"] setStringValue:inValue];
}

-(int)count {
	return [[self layout] count];
}

idAccessor(layout, setLayout);

@end
