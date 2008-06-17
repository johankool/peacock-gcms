//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
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


#import "PKMassWeightController.h"
#include "MolTypes.h"
#include "CFragment.h"

@implementation PKMassWeightController

/*
 -(id)init {
    self = [super initWithWindowNibName:@"PKMolWeight"];
        PKLogDebug(@"init MW panel");
    return self;
}
*/

- (IBAction)calculate:(id)sender{
    CFragment*	atom;
    [self showError:NO];
    
    if (CreateSymbolTable([[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/periodic.table"] cStringUsingEncoding:NSASCIIStringEncoding]) != 0) {
        printf("Unable to read periodic table.\n");
        return;
    }
    if(![[formula stringValue] isEqualToString:@""]) {
        if ((atom = [[CFragment alloc] initFromString:[[formula stringValue] cStringUsingEncoding:NSASCIIStringEncoding]:NULL])) {
            //       [text replaceOccurrencesOfString:@"­ " withString:@"Ð" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [text length])];
            
            [formula setStringValue:[atom writeToString]];
            if(![[formula stringValue] isEqualToString:@""]) {
                [weight setStringValue:[NSString localizedStringWithFormat:@"%f", [atom calculateWeight]]];
            } else {
                [self showError:YES]; 
            }
        } else {
            printf("Unable to create fragment.");
            [self showError:YES];
            
        }
        [atom free];
    } else {
        // No entry so not output too
        [weight setStringValue:@""];
    }
    
}

- (IBAction)clear:(id)sender{
    [self showError:NO];
    [formula setStringValue:@""];
    [weight setStringValue:@""];
    [contents setStringValue:@""];
}

- (void)showError:(BOOL)input {
    if (input) {
        [status setStringValue:NSLocalizedString(@"Incorrect formula", @"Error message for wrong formula")];
        [statusIcon setHidden:NO];
        [weight setStringValue:@""];
        //NSBeep();
    } else {
        [status setStringValue:@""];
        [statusIcon setHidden:YES];
    }

}

- (IBAction)openPanel:(id)sender {
    if ([panelWindow isVisible] == NO) {
        [panelWindow orderFront:self];
     } else {
        [panelWindow orderOut:self];
     }
}
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
	if ([anItem action] == @selector(openPanel:)) {
		if ([[self window] isVisible] == YES) {
			[anItem setTitle:NSLocalizedString(@"Hide Molecular Weight Calculator",@"")];
		} else {
			[anItem setTitle:NSLocalizedString(@"Show Molecular Weight Calculator",@"")];
		}
		return YES;
	} else if ([self respondsToSelector:[anItem action]]) {
		return YES;
	} else {
		return NO;
	}
}

@synthesize panelWindow;
@synthesize lowerCase;
@synthesize weight;
@synthesize status;
@synthesize statusIcon;
@synthesize contents;
@synthesize formula;
@end
