//
//  CSLBibliographyXMLModel.h
//  CSL Editor
//
//  Created by Johan Kool on 8-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessorMacros.h"

@interface CSLBibliographyXMLModel : NSObject {
	NSXMLElement *bibliographyXMLElement;
	
	NSXMLElement *multipleAuthorsElement;
	NSMutableArray *reftypes;
}

-(void)readReftypesFromXML:(NSXMLElement *)aXMLElement;

idAccessor_h(reftypes, setReftypes);

@end
