#import "JKTrace.h"

#import "MyGraphDataSerie.h"
#import "ChromatogramGraphDataSerie.h"
#import "SpectrumGraphDataSerie.h"

@implementation JKTrace

// Custom logic goes here.
- (MyGraphDataSerie *)graphDataSerie {
    MyGraphDataSerie *graphDataSerie;
    if ([[self technique] isEqualToString:@"CHROM"]) {
        graphDataSerie = [[ChromatogramGraphDataSerie alloc] init];
    } else if ([[self technique] isEqualToString:@"MS"]) {
        graphDataSerie = [[SpectrumGraphDataSerie alloc] init];        
    }
    
//      [graphDataSerie loadDataPoints:<#(int)npts#> withXValues:<#(float *)xpts#> andYValues:<#(float *)ypts#>];
    return [graphDataSerie autorelease];
}
@end
