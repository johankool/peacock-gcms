//
//  CSLInfoXMLModel.h
//  CSL Editor
//
//  Created by Johan Kool on 8-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CSLInfoXMLModel : NSObject {
	NSXMLElement *infoXMLElement;
	
	NSXMLElement *citationStyleElement;
	NSXMLElement *languageElement;
	NSXMLElement *titleElement;
	NSXMLElement *shortTitleElement;
	NSXMLElement *versionElement;
	NSXMLElement *editionElement;
	NSXMLElement *dateCreatedElement;
	NSXMLElement *dateModifiedElement;
	NSXMLElement *fieldElement;
	NSXMLElement *descriptionElement;
	NSXMLElement *basedOnTitleElement;
	NSXMLElement *basedOnVersionElement;
}
- (id)initWithXMLElement:(NSXMLElement *)aXMLElement;
@end
