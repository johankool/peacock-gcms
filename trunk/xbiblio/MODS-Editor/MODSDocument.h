//
//  MODSDocument.h
//  MODS Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MODSWindowController.h"
#import "MODSEntryXMLModel.h"
#import "AccessorMacros.h"

@interface MODSDocument : NSDocument
{
	NSXMLDocument *xmlDoc;
	
	MODSWindowController *theMODSWindowController;
	NSMutableArray *entries;
}

-(void)readXML;

idAccessor_h(entries, setEntries);
@end
