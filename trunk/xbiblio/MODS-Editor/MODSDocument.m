// submit access test
//  MODSDocument.m
//  MODS Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright __MyCompanyName__ 2005 . All rights reserved.
//

#import "MODSDocument.h"
#import "MODSWindowController.h"
#import "MODSEntryXMLModel.h"
#import "AccessorMacros.h"

@implementation MODSDocument

- (id)init
{
    self = [super init];
    if (self) {
		NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"modsCollection"];
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setValue:@"http://www.loc.gov/mods/v3" forKey:@"xmlns"];
		[mutDict setValue:@"http://www.w3.org/1999/xlink" forKey:@"xmlns:xlink"];
		[mutDict setValue:@"en" forKey:@"xml:lang"];
		[root setAttributesAsDictionary:mutDict];
		
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
		[xmlDoc setVersion:@"1.0"];
		[xmlDoc setCharacterEncoding:@"UTF-8"];
		[xmlDoc insertChild:[NSXMLNode processingInstructionWithName:@"oxygen" stringValue:@"RNGSchema=\"../schemas/mods-tight.rnc\" type=\"compact\""] atIndex:0];
		[xmlDoc insertChild:[NSXMLNode commentWithStringValue:@" This file is created using MODS Editor 0.1 (Mac OS X), written by Johan Kool. "] atIndex:1];

		entries = [[NSMutableArray alloc] init];
		
		[self readXML];
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		theMODSWindowController = [[MODSWindowController alloc] init];
    }
    return self;
}

-(void)readXML {
	NSArray *children = [[xmlDoc rootElement] children];
	int i, count = [children count];
	for (i=0; i < count; i++) {
		NSXMLElement *child = [children objectAtIndex:i];
		if ([[child name] isEqualToString:@"mods"]) {
			[[self entries] addObject:[[MODSEntryXMLModel alloc] initWithXMLElement:child]];
		} 
	}
}

-(void)makeWindowControllers {
	[self addWindowController:theMODSWindowController];
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:theMODSWindowController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type {
    NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    if (![xmlData writeToFile:fileName atomically:YES]) {
        NSBeep();
        NSLog(@"Could not write document out...");
        return NO;
    }
    return YES;
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
    NSError *err=nil;
    NSURL *furl = [NSURL fileURLWithPath:fileName];
    if (!furl) {
        NSLog(@"Can't create an URL from file %@.", fileName);
        return NO; 
    }
    xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
												  options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
													error:&err];
    if (xmlDoc == nil) {
        xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
													  options:NSXMLDocumentTidyXML
														error:&err];
    }
    if (xmlDoc == nil)  {
        if (err) {
//            [self handleError:err];
        }
        return NO;
    }
    if (err) {
//        [self handleError:err];
    }
	[self readXML];

	return YES;
}
	

-(NSString *)language {
	return [[[xmlDoc rootElement] attributeForName:@"xml:lang"] stringValue];
}

-(void)setLanguage:(NSString *)inValue {
	[[[xmlDoc rootElement] attributeForName:@"xml:lang"] setStringValue:inValue];
}

idAccessor(entries, setEntries);

@end
