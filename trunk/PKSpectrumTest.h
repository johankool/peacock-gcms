//
//  PKSpectrumTest.h
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

#import <SenTestingKit/SenTestingKit.h>

#import "AccessorMacros.h"
#import "PKLog.h"
#import "PKSpectrum.h"

@interface PKSpectrumTest : SenTestCase {
    PKSpectrum *testSpectrum1;
    PKSpectrum *testSpectrum2;
    PKSpectrum *testSpectrum3;
    PKSpectrum *testSpectrum4;
    PKSpectrum *testSpectrum5;
}

@property (retain) PKSpectrum *testSpectrum2;
@property (retain) PKSpectrum *testSpectrum4;
@property (retain) PKSpectrum *testSpectrum1;
@property (retain) PKSpectrum *testSpectrum5;
@property (retain) PKSpectrum *testSpectrum3;
@end
