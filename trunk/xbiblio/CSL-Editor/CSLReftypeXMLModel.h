//
//  CSLReftypeXMLModel.h
//  CSL Editor
//
//  Created by Johan Kool on 10-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessorMacros.h"

@interface CSLReftypeXMLModel : NSObject <NSCoding> {
	NSXMLElement *reftypeXMLElement;
	
	NSMutableArray *layout;
	
}

idAccessor_h(layout, setLayout);

@end
