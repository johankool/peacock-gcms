//
//  MODSInfoXMLModel.h
//  MODS Editor
//
//  Created by Johan Kool on 8-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessorMacros.h"

@interface MODSEntryXMLModel : NSObject {
	NSXMLElement *entryXMLElement;
	
	NSXMLElement *genreElement;
	NSXMLElement *subjectElement;
	NSXMLElement *typeOfResourceElement;
	NSXMLElement *partElement;
	NSXMLElement *identifierElement;
	NSXMLElement *titleInfoElement;
	NSXMLElement *recordInfoElement;
	NSXMLElement *originInfoElement;	
	NSXMLElement *relatedItemElement;
	NSXMLElement *relatedItemTitleElement;
	
	NSMutableArray *nameElements;
}
- (id)initWithXMLElement:(NSXMLElement *)aXMLElement;

idAccessor_h(nameElements, setNameElements);
@end
