// Objects conforming to this protocol can be used to calculate matching scores, e.g. JKSpectrum and JKLibraryEntry

@protocol JKComparableProtocol
- (int)numberOfPoints;
- (float *)masses;
- (float *)intensities;
- (float)maxIntensity;
- (NSString *)model;
- (NSString *)legendEntry;
- (BOOL)hasScannedMassRange;
- (float)minScannedMassRange;
- (float)maxScannedMassRange;
@end

