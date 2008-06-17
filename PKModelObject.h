//
//  JKModelObject.h
//  Peacock
//
//  Created by Johan Kool on 22-3-07.
//  Copyright 2007-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>


@interface PKModelObject : NSObject <NSCoding> {
    id container;
}

#pragma mark Undo
- (NSUndoManager *)undoManager;
#pragma mark -

#pragma mark Document
- (NSDocument *)document;
#pragma mark -

#pragma mark Accessors
#pragma mark (weak referenced)
- (id) container;
- (void) setContainer:(id)aContainer;

@property (assign,getter=container,setter=setContainer:) id container;
@end
