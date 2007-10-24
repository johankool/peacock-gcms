//
//  AMRemovableColumnsTableView.m
//  HebX
//
//  Created by Andreas on 26.08.05.
//  Copyright 2005 Andreas Mayer. All rights reserved.
//

#import "AMRemovableColumnsTableView.h"
#import "AMRemovableTableColumn.h"
#import "DisplayOptionsWindowController.h"

@interface NSTableView (ApplePrivate)
- (void)_readPersistentTableColumns;
- (void)_writePersistentTableColumns;
@end


@interface AMRemovableColumnsTableView (Private)
- (NSString *)columnVisibilitySaveName;
- (void)setAllTableColumns:(NSSet *)newAllTableColumns;
- (void)am_hideTableColumn:(NSTableColumn *)column;
- (void)am_showTableColumn:(NSTableColumn *)column;
- (void)readPersistentTableColumns;
- (void)writePersistentTableColumns;
- (void)am_readPersistentTableColumns;
- (void)am_writePersistentTableColumns;
@end


@implementation AMRemovableColumnsTableView

static BOOL AMRemovableColumnsTableView_readPersistentTableColumnsIsPublic = NO;

+ (void)initialize
{
	// should the framework support readPersistentTableColumns/writePersistentTableColumns, use the public methods
	AMRemovableColumnsTableView_readPersistentTableColumnsIsPublic = [NSTableColumn instancesRespondToSelector:@selector(readPersistentTableColumns)];
}

- (void)awakeFromNib
{
	am_respondsToControlDidBecomeFirstResponder = [[self delegate] respondsToSelector:@selector(controlDidBecomeFirstResponder:)];

	[self setAllTableColumns:[NSSet setWithArray:[self tableColumns]]];
	
	// set main table view for columns
	NSEnumerator *enumerator = [[self tableColumns] objectEnumerator];
	AMRemovableTableColumn *column;
	while ((column = [enumerator nextObject])) {
		[column setMainTableView:self];
	}
	
	// if there's an array of the names of obligatory columns, update the obligatoryTableColumns set
	if (obligatoryColumnIdentifiers) {
		NSMutableSet *columns = (NSMutableSet *)[NSMutableSet setWithSet:[self allTableColumns]];
		NSEnumerator *enumerator = [columns objectEnumerator];
		NSTableColumn *column;
		while (column = [enumerator nextObject]) {
			if (![(NSArray *)obligatoryColumnIdentifiers containsObject:[column identifier]]) {
				[columns removeObject:column];
			}
		}
		[self setObligatoryTableColumns:columns];
	}
	am_hasAwokenFromNib = YES;
	if (!AMRemovableColumnsTableView_readPersistentTableColumnsIsPublic) {
		[self _readPersistentTableColumns];
	} else {
		[(id)self readPersistentTableColumns];
	}
	[self performSelector:@selector(am_readPersistentTableColumns)];
}

- (void)dealloc
{
	[obligatoryColumnIdentifiers release];
	[super dealloc];
}


- (NSSet *)allTableColumns
{
	return allTableColumns; 
}

- (void)setAllTableColumns:(NSSet *)newAllTableColumns
{
	if (allTableColumns != newAllTableColumns) {
		[newAllTableColumns retain];
		[allTableColumns release];
		allTableColumns = newAllTableColumns;
	}
}

- (NSSet *)visibleTableColumns
{
	NSMutableSet *result = [NSMutableSet set];
	[result addObjectsFromArray:[self tableColumns]];
	return result;
}

- (NSSet *)hiddenTableColumns
{
	NSMutableSet *result = [NSMutableSet setWithSet:[self allTableColumns]];
	[result minusSet:[self visibleTableColumns]];
	return result;
}

- (NSSet *)obligatoryTableColumns
{
	return obligatoryTableColumns; 
}

- (void)setObligatoryTableColumns:(NSSet *)newObligatoryTableColumns
{
	if (obligatoryTableColumns != newObligatoryTableColumns) {
		[newObligatoryTableColumns retain];
		[obligatoryTableColumns release];
		obligatoryTableColumns = newObligatoryTableColumns;
	}
}

- (BOOL)hideTableColumn:(NSTableColumn *)column
{
	//JKLogDebug(@"hideTableColumn: %@", [column identifier]);
	BOOL result = NO;
	if (![(AMRemovableTableColumn *)column isHidden] && ![self isObligatoryColumn:column]) {
		[(AMRemovableTableColumn *)column setHidden:YES];
		result = YES;
	}
	return result;
}

- (BOOL)showTableColumn:(NSTableColumn *)column
{
	BOOL result = NO;
	if ([(AMRemovableTableColumn *)column isHidden]) {
		[(AMRemovableTableColumn *)column setHidden:NO];
		result = YES;
	}
	return result;
}

- (BOOL)isObligatoryColumn:(NSTableColumn *)column
{
	return [(NSArray *)obligatoryColumnIdentifiers containsObject:[column identifier]]	;
}


// ============================================================
#pragma mark -
#pragma mark ━ table view methods ━
// ============================================================

- (NSTableColumn *)tableColumnWithIdentifier:(id)identifier
{
	NSTableColumn *result = nil;
	NSEnumerator *enumerator = [[self allTableColumns] objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject]) {
		if ([[column identifier] isEqualToString:identifier]) {
			result = column;
			break;
		}
	}
	return result;
}

- (void)setDelegate:(id)anObject
{
	am_respondsToControlDidBecomeFirstResponder = [anObject respondsToSelector:@selector(controlDidBecomeFirstResponder:)];
	[super setDelegate:anObject];
}


// ============================================================
#pragma mark -
#pragma mark ━ responder methods ━
// ============================================================

- (BOOL)becomeFirstResponder
{
	BOOL result = [super becomeFirstResponder];
	if (result && am_respondsToControlDidBecomeFirstResponder) {
		[[self delegate] performSelector:@selector(controlDidBecomeFirstResponder:) withObject:self];
	}
	return result;
}


// ============================================================
#pragma mark -
#pragma mark ━ private table view methods ━
// ============================================================

- (void)_readPersistentTableColumns
{
	// we need to hold this off until *after* the table view is fully loaded!
	if (am_hasAwokenFromNib) {
		if (!AMRemovableColumnsTableView_readPersistentTableColumnsIsPublic) {
			[super _readPersistentTableColumns];
		} // else  readPersistentTableColumns will be used
	}
}

- (void)_writePersistentTableColumns
{
	[super _writePersistentTableColumns];
	// save visible columns
	if (!AMRemovableColumnsTableView_readPersistentTableColumnsIsPublic) {
		[self am_writePersistentTableColumns];
	} // else  writePersistentTableColumns will be used
}

// just in case these methods should become public:
- (void)readPersistentTableColumns
{
	if (am_hasAwokenFromNib) {
		[self setAllTableColumns:[NSSet setWithArray:[self tableColumns]]];
		// restore visible columns
		[(id)super readPersistentTableColumns]; // cast to avoid compiler warning
	}
}

- (void)writePersistentTableColumns
{
	[(id)super writePersistentTableColumns]; // cast to avoid compiler warning
	// save visible columns
	[self am_writePersistentTableColumns];
}


// ============================================================
#pragma mark -
#pragma mark ━ private methods ━
// ============================================================

- (NSString *)columnVisibilitySaveName
{
	NSString *autosaveName = [self autosaveName];
	if (!autosaveName) {
		JKLogError(@"AMRemovableColumnsTableView: autosave name missing for table view: %@", self);
		autosaveName = @"no-autosave-name-set";
	}
	return [@"AMRemovableColumnsTableView VisibleColumns " stringByAppendingString:autosaveName];
}

- (void)am_readPersistentTableColumns
{
	// restore visible columns
	NSArray *visibleColumnIdentifiers = [[NSUserDefaults standardUserDefaults] objectForKey:[self columnVisibilitySaveName]];
	if (visibleColumnIdentifiers) {
		NSSet *allColumns = [self allTableColumns];
		NSEnumerator *enumerator = [allColumns objectEnumerator];
		NSTableColumn *column;
		while (column = [enumerator nextObject]) {
			if ([visibleColumnIdentifiers containsObject:[column identifier]]) {
				[self showTableColumn:column];
			} else {
				[self hideTableColumn:column];
			}
		}
	}
}

- (void)am_writePersistentTableColumns
{
	NSMutableArray *visibleColumnIdentifiers = [NSMutableArray array];
	NSEnumerator *enumerator = [[self visibleTableColumns] objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject]) {
		[visibleColumnIdentifiers addObject:[column identifier]];
	}
	[[NSUserDefaults standardUserDefaults] setObject:visibleColumnIdentifiers forKey:[self columnVisibilitySaveName]];
}

- (void)am_hideTableColumn:(NSTableColumn *)column
{
	[(AMRemovableTableColumn *)column setMainTableView:self];
	[self removeTableColumn:column];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(am_writePersistentTableColumns) object:nil];
	[self performSelector:@selector(am_writePersistentTableColumns) withObject:nil afterDelay:0.0];
}

- (void)am_showTableColumn:(NSTableColumn *)column
{
	[self addTableColumn:column];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(am_writePersistentTableColumns) object:nil];
	[self performSelector:@selector(am_writePersistentTableColumns) withObject:nil afterDelay:0.0];
}

#pragma mark JOhan

- (IBAction)viewOptions:(id)sender
{
	DisplayOptionsWindowController *controller = [[[DisplayOptionsWindowController alloc] init] autorelease];
	[controller setDelegate:self];
	[controller setIcon:[NSImage imageNamed:@"table"]];
	[controller setHeading:NSLocalizedString([self autosaveName],@"")];
	NSSet *allColumns = [self allTableColumns];
	NSSet *visibleColumns = [self visibleTableColumns];
	NSSet *obligatoryColumns = [self obligatoryTableColumns];
	NSMutableArray *options = [NSMutableArray array];
	NSMutableDictionary *option = nil;
	NSEnumerator *enumerator = [allColumns objectEnumerator];
	NSTableColumn *column;
	while (column = [enumerator nextObject]) {
		option = [NSMutableDictionary dictionaryWithCapacity:3];
		[option setObject:[column identifier] forKey:@"identifier"];
		[option setObject:[NSNumber numberWithBool:[visibleColumns containsObject:column]] forKey:@"selected"];
		[option setObject:[NSNumber numberWithBool:![obligatoryColumns containsObject:column]] forKey:@"enabled"];
		NSString *title = [[column headerCell] stringValue];
		[option setObject:title forKey:@"title"];
		[options addObject:option];
	}
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES] autorelease];
	[controller setOptions:[options sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]]];
	[controller showWindow:self];
}

- (void)setViewOptions:(NSArray *)options
{
	NSTableColumn *column;
	NSEnumerator *enumerator = [options objectEnumerator];
	NSDictionary *option;
	while (option = [enumerator nextObject]) {
		column = [self tableColumnWithIdentifier:[option objectForKey:@"identifier"]];
		NSAssert2((column != nil), @"unknown column: %@ for table: %@", [option objectForKey:@"identifier"], [self autosaveName]);
		if ([[option objectForKey:@"selected"] boolValue]) {
			[(AMRemovableColumnsTableView *)self showTableColumn:column];
		} else {
			[(AMRemovableColumnsTableView *)self hideTableColumn:column];
		}
	}
}


@end
