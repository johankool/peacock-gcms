//
//  CSLDocument.m
//  CSL Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright Johan Kool 2005-2006. All rights reserved.
//

#import "CSLDocument.h"
#import "CSLWindowController.h"
#import "CSLInfoXMLModel.h"
#import "AccessorMacros.h"

@implementation CSLDocument

- (id)init
{
    self = [super init];
    if (self) {
		NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"citationstyle"];
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setValue:@"http://purl.org/NET/xbiblio/csl" forKey:@"xmlns"];
		[mutDict setValue:@"author-year" forKey:@"class"];
		[mutDict setValue:@"en" forKey:@"xml:lang"];
		[root setAttributesAsDictionary:mutDict];
		
		xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
		[xmlDoc setVersion:@"1.0"];
		[xmlDoc setCharacterEncoding:@"UTF-8"];
		[xmlDoc insertChild:[NSXMLNode processingInstructionWithName:@"oxygen" stringValue:@"RNGSchema=\"../schemas/citationstyle.rnc\" type=\"compact\""] atIndex:0];
		[xmlDoc insertChild:[NSXMLNode commentWithStringValue:@" This file is created using CSL Editor 0.1 (Mac OS X), written by Johan Kool. "] atIndex:1];
		[root addChild:[[NSXMLElement alloc] initWithName:@"info"]];
		[root addChild:[[NSXMLElement alloc] initWithName:@"general"]];
		[root addChild:[[NSXMLElement alloc] initWithName:@"citation"]];
		[root addChild:[[NSXMLElement alloc] initWithName:@"bibliography"]];
		
		[self readXML];
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		cslWindowController = [[CSLWindowController alloc] init];
    }
    return self;
}

-(void)readXML {
	NSArray *children = [[xmlDoc rootElement] children];
	int i, count = [children count];
	for (i=0; i < count; i++) {
		NSXMLElement *child = [children objectAtIndex:i];
		if ([[child name] isEqualToString:@"info"]) {
			[self setInfo:[[CSLInfoXMLModel alloc] initWithXMLElement:child]];
		} else if ([[child name] isEqualToString:@"general"]) {

		} else if ([[child name] isEqualToString:@"citation"]) {
			
		} else if ([[child2 name] isEqualToString:@"bibliography"]) {
			[self setBibliography:[[CSLBibliographyXMLModel alloc] initWithXMLElement:child]];
		}
	}
}

-(void)makeWindowControllers {
	[self addWindowController:cslWindowController];
}


- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
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
	

-(int)citationStyle {
	//NSLog([[[xmlDoc rootElement] attributeForName:@"class"] stringValue]);
	NSString *string = [[[xmlDoc rootElement] attributeForName:@"class"] stringValue];
	if ([string isEqualToString:@"author-year"]) {
		return 0;
	} else if ([string isEqualToString:@"note-bib"]) {
		return 1;
	}  else if ([string isEqualToString:@"note-nobib"]) {
		return 2;
	}  else if ([string isEqualToString:@"number"]) {
		return 3;
	} else if  ([string isEqualToString:@"citekey"]) {
		return 4;
	}
	return 0;
}

-(void)setCitationStyle:(int)inValue {
	switch (inValue) {
		case 0:
			[[[xmlDoc rootElement] attributeForName:@"class"] setStringValue:@"author-year"];
			break;
		case 1:
			[[[xmlDoc rootElement] attributeForName:@"class"] setStringValue:@"note-bib"];
			break;
		case 2:
			[[[xmlDoc rootElement] attributeForName:@"class"] setStringValue:@"note-nobib"];
			break;
		case 3:
			[[[xmlDoc rootElement] attributeForName:@"class"] setStringValue:@"number"];
			break;
		case 4:
			[[[xmlDoc rootElement] attributeForName:@"class"] setStringValue:@"citekey"];
			break;
		default:
			break;
	}
}

-(NSString *)language {
	return [[[xmlDoc rootElement] attributeForName:@"xml:lang"] stringValue];
}

-(void)setLanguage:(NSString *)inValue {
	[[[xmlDoc rootElement] attributeForName:@"xml:lang"] setStringValue:inValue];
}


idAccessor(info, setInfo);
idAccessor(bibliography, setBibliography);

@end
