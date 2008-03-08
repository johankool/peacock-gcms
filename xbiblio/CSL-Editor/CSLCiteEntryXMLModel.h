//
//  CSLCiteEntryXMLModel.h
//  CSL Editor
//
//  Created by Johan Kool on 10-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessorMacros.h"

@interface CSLCiteEntryXMLModel : NSObject <NSCoding> {
	NSXMLElement *citeEntryXMLElement;
	
	NSXMLElement *prefixElement;
	NSXMLElement *suffixElement;
	NSMutableArray *children;
}

idAccessor_h(children, setChildren);

@end
