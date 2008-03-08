//
//  MODSWindowController.m
//  MODS Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "MODSWindowController.h"
#import "MODSEntryXMLModel.h"
#import "CTGradientView.h"

NSString *CiteEntryType = @"CiteEntryType";

enum MODSEntryTypes {
	MODSArticleInJournalType,
	MODSOtherType
};

enum MODSDetailViewTypes {
	MODSAuthorDetailView,
	MODSAuthorExtendedDetailView,
	MODSTitleDetailView,
	MODSGenreCitekeyDetailView,
	MODSJournalDetailView,
	MODSDateDetailView,
	MODSUrlsDetailView,
	MODSAbstractDetailView,
	MODSDividerDetailView,

};

@implementation MODSWindowController

-(id)init {
    if (self = [super initWithWindowNibName:@"MODSDocument"]) {
    }
    return self;
}

-(void)windowDidLoad {
//	[self setupToolbar];
//	[bibliographyOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:CiteEntryType,nil]];
	[entriesController addObserver:self forKeyPath:@"selection" options:nil context:nil];
	if ([[entriesController selectedObjects] count] > 0) {
		[detailedView setHidden:NO];
		[self setupDetailedViewForEntry:[[entriesController selectedObjects] objectAtIndex:0]];		
	} else {
		[detailedView setHidden:YES];
	}
	
}


-(id)info {
	return [[self document] info];
}

-(void)setupDetailedViewForEntry:(MODSEntryXMLModel *)entry {
	NSRect theFrame;
	float summedHeight = 0.0;
	int entryType = MODSArticleInJournalType;
	NSView *aView;
	
	// Remove current subviews
	unsigned int i, count = [[detailedView subviews] count];
	if (count > 0) {
		for (i = count; i > 0; i--) {
			aView = [[detailedView subviews] objectAtIndex:i-1];
			//[aView retain];
			[aView removeFromSuperview];
		}		
	}
//	NSAssert([[detailedView subviews] count] == 0, @"Still subviews around");
	
	switch (entryType) {
	case MODSArticleInJournalType:
		aView = [self detailViewOfType:MODSUrlsDetailView];
		theFrame = [aView frame];
		theFrame.origin.y = summedHeight;
		[aView setFrame:theFrame];
		[detailedView addSubview:aView];
		summedHeight = summedHeight + theFrame.size.height;

		aView = [self detailViewOfType:MODSAbstractDetailView];
		theFrame = [aView frame];
		theFrame.origin.y = summedHeight;
		[aView setFrame:theFrame];
		[detailedView addSubview:aView];
		summedHeight = summedHeight + theFrame.size.height;

		aView = [self detailViewOfType:MODSDateDetailView];
		theFrame = [aView frame];
		theFrame.origin.y = summedHeight;
		[aView setFrame:theFrame];
		[detailedView addSubview:aView];
		summedHeight = summedHeight + theFrame.size.height;
		
		aView = [self detailViewOfType:MODSJournalDetailView];
		theFrame = [aView frame];
		theFrame.origin.y = summedHeight;
		[aView setFrame:theFrame];
		[detailedView addSubview:aView];
		summedHeight = summedHeight + theFrame.size.height;

		aView = [self detailViewOfType:MODSDividerDetailView];
		theFrame = [aView frame];
		theFrame.origin.y = summedHeight;
		[aView setFrame:theFrame];
		[detailedView addSubview:aView];
		summedHeight = summedHeight + theFrame.size.height;
		
		int namesCount = [[entry nameElements] count];
		for (i = 0; i < namesCount; i++) {
			aView = [self detailViewOfType:MODSAuthorDetailView forElement:[[entry nameElements] objectAtIndex:i]];
			theFrame = [aView frame];
			theFrame.origin.y = summedHeight;
			[aView setFrame:theFrame];
			[detailedView addSubview:aView];
			summedHeight = summedHeight + theFrame.size.height;
		}
		
		aView = [self detailViewOfType:MODSTitleDetailView];
		theFrame = [aView frame];
		theFrame.origin.y = summedHeight;
		[aView setFrame:theFrame];
		[detailedView addSubview:aView];
		summedHeight = summedHeight + theFrame.size.height;
		
		break;
	default:
		break;
	}

	aView = [self detailViewOfType:MODSGenreCitekeyDetailView];
	theFrame = [aView frame];
	theFrame.origin.y = summedHeight;
	[aView setFrame:theFrame];
	[detailedView addSubview:aView];
	summedHeight = summedHeight + theFrame.size.height;
	
	theFrame = [detailedView frame];
	theFrame.size.height = summedHeight;
	[detailedView setFrame:theFrame];
	
//	[detailedView scrollClipView:detailedView toPoint:NSMakePoint(0,summedHeight)];
//	[[detailedView superview] scrollToPoint:NSMakePoint(0,summedHeight)];
}

-(NSView *)detailViewOfType:(int)viewType forElement:(id)element {
	NSView *detailView = [[[NSView alloc] initWithFrame:NSMakeRect(0,0,438,60)] autorelease];
	
	switch (viewType) {
	case MODSAuthorDetailView:
		[detailView setHidden:NO]; // Weird! Can't alloc object in switch statement if it is on the first line.
		NSTextField *authorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,32,114,17)];
		[authorLabel setStringValue:NSLocalizedString(@"Author:",@"Author:")];
		[authorLabel setEditable:NO];
		[authorLabel setBordered:NO];
		[authorLabel setDrawsBackground:NO];
		[authorLabel setAlignment:NSRightTextAlignment];
		[authorLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:authorLabel];
		
		NSTextField *authorEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,30,302,22)];
		[authorEdit setEditable:YES];
		[authorEdit setFont:[NSFont systemFontOfSize:13.0]];
		[authorEdit bind:@"value" toObject:element withKeyPath:@"objectValue" options:nil];
		[detailView addSubview:authorEdit];
		
		NSButton *moreOptions = [[NSButton alloc] initWithFrame:NSMakeRect(337,6,82,16)];
		[moreOptions setButtonType:NSMomentaryPushInButton];
		[moreOptions setBezelStyle:NSRoundedBezelStyle];
		[moreOptions setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[moreOptions cell] setControlSize:NSMiniControlSize];
		[moreOptions setTitle:NSLocalizedString(@"More Options",@"More Options")];
		[detailView addSubview:moreOptions];
		
		NSPopUpButton *typePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(116,6,82,16) pullsDown:NO];
		[typePopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[typePopUp cell] setControlSize:NSMiniControlSize];
		[typePopUp addItemWithTitle:NSLocalizedString(@"Person",@"Person")];
		[typePopUp addItemWithTitle:NSLocalizedString(@"Organisation",@"Organisation")];
		[detailView addSubview:typePopUp];
		
		NSPopUpButton *rolePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(202,6,82,16) pullsDown:NO];
		[rolePopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[rolePopUp cell] setControlSize:NSMiniControlSize];
		[rolePopUp addItemWithTitle:NSLocalizedString(@"Author",@"Author")];
		[rolePopUp addItemWithTitle:NSLocalizedString(@"Editor",@"Editor")];
		[detailView addSubview:rolePopUp];
		
		break;
//	case MODSAuthorExtendedDetailView:
//		[detailView setHidden:NO]; // Weird! Can't alloc object in switch statement if it is on the first line.
//		NSTextField *authorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,32,114,17)];
//		[authorLabel setStringValue:NSLocalizedString(@"Author:",@"Author:")];
//		[authorLabel setEditable:NO];
//		[authorLabel setBordered:NO];
//		[authorLabel setDrawsBackground:NO];
//		[authorLabel setAlignment:NSRightTextAlignment];
//		[authorLabel setFont:[NSFont systemFontOfSize:13.0]];
//		[detailView addSubview:authorLabel];
//		
//		NSTextField *authorEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,30,302,22)];
//		[authorEdit setEditable:YES];
//		[authorEdit setFont:[NSFont systemFontOfSize:13.0]];
//		[authorEdit bind:@"value" toObject:element withKeyPath:@"objectValue" options:nil];
//		[detailView addSubview:authorEdit];
//		
//		NSButton *moreOptions = [[NSButton alloc] initWithFrame:NSMakeRect(337,6,82,16)];
//		[moreOptions setButtonType:NSMomentaryPushInButton];
//		[moreOptions setBezelStyle:NSRoundedBezelStyle];
//		[moreOptions setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
//		[[moreOptions cell] setControlSize:NSMiniControlSize];
//		[moreOptions setTitle:NSLocalizedString(@"More Options",@"More Options")];
//		[detailView addSubview:moreOptions];
//		
//		NSPopUpButton *typePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(116,6,82,16) pullsDown:NO];
//		[typePopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
//		[[typePopUp cell] setControlSize:NSMiniControlSize];
//		[typePopUp addItemWithTitle:NSLocalizedString(@"Person",@"Person")];
//		[typePopUp addItemWithTitle:NSLocalizedString(@"Organisation",@"Organisation")];
//		[detailView addSubview:typePopUp];
//		
//		NSPopUpButton *rolePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(202,6,82,16) pullsDown:NO];
//		[rolePopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
//		[[rolePopUp cell] setControlSize:NSMiniControlSize];
//		[rolePopUp addItemWithTitle:NSLocalizedString(@"Author",@"Author")];
//		[rolePopUp addItemWithTitle:NSLocalizedString(@"Editor",@"Editor")];
//		[detailView addSubview:rolePopUp];
		
		break;
	}
	return detailView;
}		
-(NSView *)detailViewOfType:(int)viewType {
	NSView *detailView = [[[NSView alloc] initWithFrame:NSMakeRect(0,0,438,60)] autorelease];
	
	switch (viewType) {
	case MODSGenreCitekeyDetailView:
		[detailView setFrame:NSMakeRect(0,0,438,66)];
		NSTextField *typeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,40,114,17)];
		[typeLabel setStringValue:NSLocalizedString(@"Type:",@"Type:")];
		[typeLabel setEditable:NO];
		[typeLabel setBordered:NO];
		[typeLabel setDrawsBackground:NO];
		[typeLabel setAlignment:NSRightTextAlignment];
		[typeLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:typeLabel];
		
		NSPopUpButton *genrePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(116,34,202,26) pullsDown:NO];
		[genrePopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
		[[genrePopUp cell] setControlSize:NSRegularControlSize];
		[genrePopUp addItemWithTitle:NSLocalizedString(@"Article",@"Article")];
		[genrePopUp addItemWithTitle:NSLocalizedString(@"Book",@"Book")];
		[genrePopUp addItemWithTitle:NSLocalizedString(@"Etc.",@"Etc.")];
		[detailView addSubview:genrePopUp];

		NSTextField *citekeyLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,10,114,17)];
		[citekeyLabel setStringValue:NSLocalizedString(@"Citekey:",@"Citekey:")];
		[citekeyLabel setEditable:NO];
		[citekeyLabel setBordered:NO];
		[citekeyLabel setDrawsBackground:NO];
		[citekeyLabel setAlignment:NSRightTextAlignment];
		[citekeyLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:citekeyLabel];
		
		NSTextField *citekeyEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,8,302,22)];
		[citekeyEdit setEditable:YES];
		[citekeyEdit setFont:[NSFont systemFontOfSize:13.0]];
		[citekeyEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.citekey" options:nil];
		[detailView addSubview:citekeyEdit];
			
						
		break;
	case MODSAuthorDetailView:
		[detailView setHidden:NO]; // Weird! Can't alloc object in switch statement if it is on the first line.
		NSTextField *authorLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,32,114,17)];
		[authorLabel setStringValue:NSLocalizedString(@"Author:",@"Author:")];
		[authorLabel setEditable:NO];
		[authorLabel setBordered:NO];
		[authorLabel setDrawsBackground:NO];
		[authorLabel setAlignment:NSRightTextAlignment];
		[authorLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:authorLabel];
		
		NSTextField *authorEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,30,302,22)];
		[authorEdit setEditable:YES];
		[authorEdit setFont:[NSFont systemFontOfSize:13.0]];
		[authorEdit bind:@"value" toObject:entriesController withKeyPath:@"arrangedObjects.name" options:nil];
		[detailView addSubview:authorEdit];
		
		NSButton *moreOptions = [[NSButton alloc] initWithFrame:NSMakeRect(337,6,82,16)];
		[moreOptions setButtonType:NSMomentaryPushInButton];
		[moreOptions setBezelStyle:NSRoundedBezelStyle];
		[moreOptions setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[moreOptions cell] setControlSize:NSMiniControlSize];
		[moreOptions setTitle:NSLocalizedString(@"More Options",@"More Options")];
		[detailView addSubview:moreOptions];
		
		NSPopUpButton *typePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(116,6,82,16) pullsDown:NO];
		[typePopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[typePopUp cell] setControlSize:NSMiniControlSize];
		[typePopUp addItemWithTitle:NSLocalizedString(@"Person",@"Person")];
		[typePopUp addItemWithTitle:NSLocalizedString(@"Organisation",@"Organisation")];
		[detailView addSubview:typePopUp];

		NSPopUpButton *rolePopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(202,6,82,16) pullsDown:NO];
		[rolePopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[rolePopUp cell] setControlSize:NSMiniControlSize];
		[rolePopUp addItemWithTitle:NSLocalizedString(@"Author",@"Author")];
		[rolePopUp addItemWithTitle:NSLocalizedString(@"Editor",@"Editor")];
		[detailView addSubview:rolePopUp];
		
		break;
	case MODSTitleDetailView:
		[detailView setHidden:NO]; // Weird! Can't alloc object in switch statement if it is on the first line.
		NSTextField *titleLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,32,114,17)];
		[titleLabel setStringValue:NSLocalizedString(@"Title:",@"Title:")];
		[titleLabel setEditable:NO];
		[titleLabel setBordered:NO];
		[titleLabel setDrawsBackground:NO];
		[titleLabel setAlignment:NSRightTextAlignment];
		[titleLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:titleLabel];
		
		NSTextField *titleEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,30,302,22)];
		[titleEdit setEditable:YES];
		[titleEdit setFont:[NSFont systemFontOfSize:13.0]];
		[titleEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.title" options:nil];
		[detailView addSubview:titleEdit];
		
		NSButton *moreOptionsTitle = [[NSButton alloc] initWithFrame:NSMakeRect(337,6,82,16)];
		[moreOptionsTitle setButtonType:NSMomentaryPushInButton];
		[moreOptionsTitle setBezelStyle:NSRoundedBezelStyle];
		[moreOptionsTitle setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[moreOptionsTitle cell] setControlSize:NSMiniControlSize];
		[moreOptionsTitle setTitle:NSLocalizedString(@"More Options",@"More Options")];
		[detailView addSubview:moreOptionsTitle];
		
		break;
	case MODSDateDetailView:
		[detailView setHidden:NO]; // Weird! Can't alloc object in switch statement if it is on the first line.
		NSTextField *dateLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,32,114,17)];
		[dateLabel setStringValue:NSLocalizedString(@"Date:",@"Date:")];
		[dateLabel setEditable:NO];
		[dateLabel setBordered:NO];
		[dateLabel setDrawsBackground:NO];
		[dateLabel setAlignment:NSRightTextAlignment];
		[dateLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:dateLabel];
		
		NSTextField *dateEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,30,302,22)];
		[dateEdit setEditable:YES];
		[dateEdit setFont:[NSFont systemFontOfSize:13.0]];
		[dateEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.date" options:nil];
		[detailView addSubview:dateEdit];
		
		NSButton *moreOptionsDate = [[NSButton alloc] initWithFrame:NSMakeRect(337,6,82,16)];
		[moreOptionsDate setButtonType:NSMomentaryPushInButton];
		[moreOptionsDate setBezelStyle:NSRoundedBezelStyle];
		[moreOptionsDate setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[moreOptionsDate cell] setControlSize:NSMiniControlSize];
		[moreOptionsDate setTitle:NSLocalizedString(@"More Options",@"More Options")];
		[detailView addSubview:moreOptionsDate];
		
		break;
	case MODSJournalDetailView:
		[detailView setFrame:NSMakeRect(0,0,438,98)];

		NSTextField *journalLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,70,114,17)];
		[journalLabel setStringValue:NSLocalizedString(@"Journal:",@"Journal:")];
		[journalLabel setEditable:NO];
		[journalLabel setBordered:NO];
		[journalLabel setDrawsBackground:NO];
		[journalLabel setAlignment:NSRightTextAlignment];
		[journalLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:journalLabel];
		
		NSTextField *journalEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,68,302,22)];
		[journalEdit setEditable:YES];
		[journalEdit setFont:[NSFont systemFontOfSize:13.0]];
		[journalEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.journal" options:nil];
		[detailView addSubview:journalEdit];

		NSTextField *volumeLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,40,114,17)];
		[volumeLabel setStringValue:NSLocalizedString(@"Volume:",@"Volume:")];
		[volumeLabel setEditable:NO];
		[volumeLabel setBordered:NO];
		[volumeLabel setDrawsBackground:NO];
		[volumeLabel setAlignment:NSRightTextAlignment];
		[volumeLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:volumeLabel];
		
		NSTextField *volumeEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,38,110,22)];
		[volumeEdit setEditable:YES];
		[volumeEdit setFont:[NSFont systemFontOfSize:13.0]];
		[volumeEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.volume" options:nil];
		[detailView addSubview:volumeEdit];

		NSTextField *issueLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(237,40,66,17)];
		[issueLabel setStringValue:NSLocalizedString(@"Issue:",@"Issue:")];
		[issueLabel setEditable:NO];
		[issueLabel setBordered:NO];
		[issueLabel setDrawsBackground:NO];
		[issueLabel setAlignment:NSRightTextAlignment];
		[issueLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:issueLabel];
		
		NSTextField *issueEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(308,38,110,22)];
		[issueEdit setEditable:YES];
		[issueEdit setFont:[NSFont systemFontOfSize:13.0]];
		[issueEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.issue" options:nil];
		[detailView addSubview:issueEdit];

		NSTextField *startLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,10,114,17)];
		[startLabel setStringValue:NSLocalizedString(@"Start Page:",@"Start Page:")];
		[startLabel setEditable:NO];
		[startLabel setBordered:NO];
		[startLabel setDrawsBackground:NO];
		[startLabel setAlignment:NSRightTextAlignment];
		[startLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:startLabel];
		
		NSTextField *startEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,8,110,22)];
		[startEdit setEditable:YES];
		[startEdit setFont:[NSFont systemFontOfSize:13.0]];
		[startEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.startPage" options:nil];
		[detailView addSubview:startEdit];

		NSTextField *endLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(237,10,66,17)];
		[endLabel setStringValue:NSLocalizedString(@"End Page:",@"End Page:")];
		[endLabel setEditable:NO];
		[endLabel setBordered:NO];
		[endLabel setDrawsBackground:NO];
		[endLabel setAlignment:NSRightTextAlignment];
		[endLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:endLabel];
		
		NSTextField *endEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(308,8,110,22)];
		[endEdit setEditable:YES];
		[endEdit setFont:[NSFont systemFontOfSize:13.0]];
		[endEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.endPage" options:nil];
		[detailView addSubview:endEdit];
		
		break;
	case MODSUrlsDetailView:
		[detailView setFrame:NSMakeRect(0,0,438,164)];

		NSTextField *doiLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,136,114,17)];
		[doiLabel setStringValue:NSLocalizedString(@"DOI:",@"DOI:")];
		[doiLabel setEditable:NO];
		[doiLabel setBordered:NO];
		[doiLabel setDrawsBackground:NO];
		[doiLabel setAlignment:NSRightTextAlignment];
		[doiLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:doiLabel];
		
		NSTextField *doiEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,134,302,22)];
		[doiEdit setEditable:YES];
		[doiEdit setFont:[NSFont systemFontOfSize:13.0]];
		[doiEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.doi" options:nil];
		[detailView addSubview:doiEdit];

		NSButton *openDoi = [[NSButton alloc] initWithFrame:NSMakeRect(337,110,82,16)];
		[openDoi setButtonType:NSMomentaryPushInButton];
		[openDoi setBezelStyle:NSRoundedBezelStyle];
		[openDoi setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[openDoi cell] setControlSize:NSMiniControlSize];
		[openDoi setTitle:NSLocalizedString(@"Open",@"Open")];
		[detailView addSubview:openDoi];
		
		NSTextField *urlLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,84,114,17)];
		[urlLabel setStringValue:NSLocalizedString(@"URL:",@"URL:")];
		[urlLabel setEditable:NO];
		[urlLabel setBordered:NO];
		[urlLabel setDrawsBackground:NO];
		[urlLabel setAlignment:NSRightTextAlignment];
		[urlLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:urlLabel];
		
		NSTextField *urlEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,82,302,22)];
		[urlEdit setEditable:YES];
		[urlEdit setFont:[NSFont systemFontOfSize:13.0]];
		[urlEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.url" options:nil];
		[detailView addSubview:urlEdit];

		NSButton *openURL = [[NSButton alloc] initWithFrame:NSMakeRect(337,58,82,16)];
		[openURL setButtonType:NSMomentaryPushInButton];
		[openURL setBezelStyle:NSRoundedBezelStyle];
		[openURL setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[openURL cell] setControlSize:NSMiniControlSize];
		[openURL setTitle:NSLocalizedString(@"Open",@"Open")];
		[detailView addSubview:openURL];
		
		NSTextField *fileLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,32,114,17)];
		[fileLabel setStringValue:NSLocalizedString(@"File:",@"File:")];
		[fileLabel setEditable:NO];
		[fileLabel setBordered:NO];
		[fileLabel setDrawsBackground:NO];
		[fileLabel setAlignment:NSRightTextAlignment];
		[fileLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:fileLabel];
		
		NSTextField *fileEdit = [[NSTextField alloc] initWithFrame:NSMakeRect(116,30,302,22)];
		[fileEdit setEditable:YES];
		[fileEdit setFont:[NSFont systemFontOfSize:13.0]];
		[fileEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.file" options:nil];
		[detailView addSubview:fileEdit];
		
		NSButton *openFile = [[NSButton alloc] initWithFrame:NSMakeRect(337,6,82,16)];
		[openFile setButtonType:NSMomentaryPushInButton];
		[openFile setBezelStyle:NSRoundedBezelStyle];
		[openFile setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[openFile cell] setControlSize:NSMiniControlSize];
		[openFile setTitle:NSLocalizedString(@"Open",@"Open")];
		[detailView addSubview:openFile];

		NSButton *browseFile = [[NSButton alloc] initWithFrame:NSMakeRect(247,6,82,16)];
		[browseFile setButtonType:NSMomentaryPushInButton];
		[browseFile setBezelStyle:NSRoundedBezelStyle];
		[browseFile setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[browseFile cell] setControlSize:NSMiniControlSize];
		[browseFile setTitle:NSLocalizedString(@"Browse",@"Browse")];
		[detailView addSubview:browseFile];

		NSButton *revealFile = [[NSButton alloc] initWithFrame:NSMakeRect(157,6,82,16)];
		[revealFile setButtonType:NSMomentaryPushInButton];
		[revealFile setBezelStyle:NSRoundedBezelStyle];
		[revealFile setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		[[revealFile cell] setControlSize:NSMiniControlSize];
		[revealFile setTitle:NSLocalizedString(@"Reveal",@"Reveal")];
		[detailView addSubview:revealFile];
		
		break;
	case MODSAbstractDetailView:
		[detailView setFrame:NSMakeRect(0,0,438,200)];
		
		NSTextField *abstractLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,200-17-8,114,17)];
		[abstractLabel setStringValue:NSLocalizedString(@"Abstract:",@"Abstract:")];
		[abstractLabel setEditable:NO];
		[abstractLabel setBordered:NO];
		[abstractLabel setDrawsBackground:NO];
		[abstractLabel setAlignment:NSRightTextAlignment];
		[abstractLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:abstractLabel];
		
		NSScrollView *abstractScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(116,8,302,184)];
		NSTextView *abstractEdit = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,286,184)];
		[abstractEdit setEditable:YES];
		[abstractEdit setRichText:NO];
		[abstractEdit setFont:[NSFont systemFontOfSize:11.0]];
		[abstractEdit bind:@"value" toObject:entriesController withKeyPath:@"selection.abstract" options:nil];
		[abstractScroll setDocumentView:abstractEdit];
		[abstractScroll setHasVerticalScroller:YES];
		[abstractScroll setBorderType:NSBezelBorder];
		[detailView addSubview:abstractScroll];
				
		break;
	case MODSDividerDetailView:
		[detailView setFrame:NSMakeRect(0,0,438,26)];
		NSTextField *divPublishLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(-3,5,114,17)];
		CTGradientView *backgroundView = [[CTGradientView alloc] initWithFrame:NSMakeRect(0,0,438,26)];
		[divPublishLabel setStringValue:NSLocalizedString(@"Published in:",@"Published in:")];
		[divPublishLabel setEditable:NO];
		[divPublishLabel setBordered:NO];
		[divPublishLabel setDrawsBackground:NO];
		[divPublishLabel setAlignment:NSRightTextAlignment];
		[divPublishLabel setFont:[NSFont systemFontOfSize:13.0]];
		[detailView addSubview:backgroundView];
		[detailView addSubview:divPublishLabel];

		NSPopUpButton *hostPopUp = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(116,0,202,26) pullsDown:NO];
		[hostPopUp setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
		[[hostPopUp cell] setControlSize:NSRegularControlSize];
		[hostPopUp setBordered:YES];
		//[hostPopUp setBezelStyle:NSRoundRectBezelStyle];
		[hostPopUp addItemWithTitle:NSLocalizedString(@"Journal",@"Journal")];
		[hostPopUp addItemWithTitle:NSLocalizedString(@"Conference",@"Conference")];
		[hostPopUp addItemWithTitle:NSLocalizedString(@"Etc.",@"Etc.")];
		[detailView addSubview:hostPopUp];
		
	default:
		break;
	}
	
	return detailView;
}
#pragma mark KEY VALUE OBSERVING MANAGEMENT
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([[entriesController selectedObjects] count] > 0) {
		[detailedView setHidden:NO];
		[self setupDetailedViewForEntry:[[entriesController selectedObjects] objectAtIndex:0]];		
	} else {
		[detailedView setHidden:YES];
	}
}
	
#pragma mark NSTOOLBAR MANAGEMENT

-(void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"MODSToolbar"] autorelease];
    
    // Set up toolbar properties: disallow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: NO];
	[toolbar setVisible:YES];
	
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[toolbar setSelectedItemIdentifier:@"Show Info Item Identifier"];
}

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqual: @"Show Info Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Info"];
		[toolbarItem setPaletteLabel: @"Show Info"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Info"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showInfo:)];
	}   else if ([itemIdent isEqual: @"Show Content Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Content"];
		[toolbarItem setPaletteLabel: @"Show Content"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Content"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showContent:)];
	}   else     if ([itemIdent isEqual: @"Show Citation Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Citation"];
		[toolbarItem setPaletteLabel: @"Show Citation"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Citation"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showCitation:)];
	}   else     if ([itemIdent isEqual: @"Show Bibliography Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Bibliography"];
		[toolbarItem setPaletteLabel: @"Show Bibliography"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Bibliography"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showBibliography:)];
	}   else  {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
    return toolbarItem;
}

-(NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	@"Show Info Item Identifier",@"Show Content Item Identifier",@"Show Citation Item Identifier",@"Show Bibliography Item Identifier", nil];
}

-(NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects:	@"Show Info Item Identifier",@"Show Content Item Identifier",@"Show Citation Item Identifier",@"Show Bibliography Item Identifier", nil];
}

-(NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:	@"Show Info Item Identifier",@"Show Content Item Identifier",@"Show Citation Item Identifier",@"Show Bibliography Item Identifier", nil];
}

// The below still needs to get implemented

#pragma mark -
#pragma mark NSOutlineView Hacks for Drag and Drop

- (BOOL) outlineView: (NSOutlineView *)ov
	isItemExpandable: (id)item { return NO; }

- (int)  outlineView: (NSOutlineView *)ov
         numberOfChildrenOfItem:(id)item { return 0; }

- (id)   outlineView: (NSOutlineView *)ov
			   child:(int)index
			  ofItem:(id)item { return nil; }

- (id)   outlineView: (NSOutlineView *)ov
         objectValueForTableColumn:(NSTableColumn*)col
			  byItem:(id)item { return nil; }


- (BOOL) outlineView: (NSOutlineView *)ov
          acceptDrop: (id )info
                item: (id)item
          childIndex: (int)index
{
//    item = [item observedObject];
	NSLog([info description]);

//	NSLog([[item observedObject] label]);
	
    // do whatever you would normally do with the item
	NSLog(@"acceptDrop?");
	return YES;
}
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
	return NSDragOperationAll;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	[pboard declareTypes:[NSArray arrayWithObjects:CiteEntryType,nil] owner:self];

//	[pboard setPropertyList:items forType:"CiteEntryType"];
	return YES;
}
@end
