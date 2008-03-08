//
//  CSLDocument.h
//  CSL Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "CSLWindowController.h"
#import "CSLInfoXMLModel.h"
#import "CSLBibliographyXMLModel.h"
#import "AccessorMacros.h"

@interface CSLDocument : NSDocument
{
	NSXMLDocument *xmlDoc;
	
	CSLWindowController *cslWindowController;
	CSLInfoXMLModel *info;
	CSLBibliographyXMLModel *bibliography;
}

-(void)readXML;

idAccessor_h(info, setInfo);
idAccessor_h(bibliography, setBibliography);
@end
