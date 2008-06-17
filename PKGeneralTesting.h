//
//  JKGeneralTesting.h
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006-2008 Johan Kool.
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

// -------------------------------------------
//
// TESTS THAT NEED TO BE WRITTEN:
//
// CDF files can be opened
// CDF files can be saved as Peacock files
// Peacock files can be opened
// Peacock files can be saved
// JCAMP-DX files can be opened
// JCAMP-DX files can be saved
// JCAMP-DX files can be saved as Peacock-library files
// HP-JCAMP-DX files can be opened
// HP-JCAMP-DX files can be saved as JCAMP-DX files
// Peacock-library files can be opened
// Peacock-library files can be saved
// Baseline detection can be run
// Peak detection can be run
// Forward search can be run
// Backward search can be run
// 


#import <SenTestingKit/SenTestingKit.h>

#import "AccessorMacros.h"
#import "PKLog.h"

@class PKGCMSDocument;

@interface PKGeneralTesting : SenTestCase {
	PKGCMSDocument *CDFDocument;
	PKGCMSDocument *PeacockDocument;
}

@end
