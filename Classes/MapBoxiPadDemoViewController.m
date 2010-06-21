//
//  MapBoxiPadDemoViewController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxiPadDemoViewController.h"
#import "DSMapBoxSQLiteTileSource.h"
#import "RMMapContents.h"

@implementation MapBoxiPadDemoViewController


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"wood-walnut-background-tile.jpg"]];
    
    CLLocationCoordinate2D here;
    
	here.latitude = 18.533333;
	here.longitude = -72.333333;
    
	[[[RMMapContents alloc] initWithView:mapView 
                              tilesource:[[[DSMapBoxSQLiteTileSource alloc] init] autorelease]
                            centerLatLon:here
                               zoomLevel:8
                            maxZoomLevel:10
                            minZoomLevel:0
                         backgroundImage:nil] autorelease];

    mapView.enableRotate = YES;
    mapView.deceleration = YES;

    mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"404803.jpg"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(expensive:)
                                                 name:RMSuspendExpensiveOperations
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(expensive:)
                                                 name:RMResumeExpensiveOperations
                                               object:nil];
}

- (void)expensive:(NSNotification *)notification
{
    NSLog(@"%@", [notification name]);
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
