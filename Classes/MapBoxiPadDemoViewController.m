//
//  MapBoxiPadDemoViewController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxiPadDemoViewController.h"

#import "DSMapBoxSQLiteTileSource.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxDataOverlayManager.h"
#import "DSMapContents.h"
#import "DSMapBoxLayerController.h"
#import "DSMapBoxLayerManager.h"
#import "DSMapBoxDocumentSaveController.h"
#import "DSMapBoxDocumentLoadController.h"

#import "UIApplication_Additions.h"

#import "SimpleKML.h"

#import "RMMapView.h"
#import "RMTileSource.h"

#import "TouchXML.h"

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#define kStartingLat  33.919241123962202f
#define kStartingLon  66.074245801675474f
#define kStartingZoom  6.0f

@interface MapBoxiPadDemoViewController (MapBoxiPadDemoViewControllerPrivate)

void SoundCompletionProc (SystemSoundID sound, void *clientData);
- (UIImage *)mapSnapshot;

@end

#pragma mark -

@implementation MapBoxiPadDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // starting setup info
    //
    CLLocationCoordinate2D startingPoint;
    
    startingPoint.latitude  = kStartingLat;
    startingPoint.longitude = kStartingLon;
    
    // base map view
    //
    DSMapBoxSQLiteTileSource *source = [[[DSMapBoxSQLiteTileSource alloc] init] autorelease];
    
	[[[DSMapContents alloc] initWithView:mapView 
                              tilesource:source
                            centerLatLon:startingPoint
                               zoomLevel:kStartingZoom
                            maxZoomLevel:[source maxZoom]
                            minZoomLevel:[source minZoom]
                         backgroundImage:nil] autorelease];
    
    mapView.enableRotate = NO;
    mapView.deceleration = YES;

    mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.jpg"]];
    
    // data overlay & layer managers
    //
    dataOverlayManager = [[DSMapBoxDataOverlayManager alloc] initWithMapView:mapView];
    dataOverlayManager.mapView = mapView;
    mapView.delegate = dataOverlayManager;
    layerManager = [[DSMapBoxLayerManager alloc] initWithDataOverlayManager:dataOverlayManager overBaseMapView:mapView];
    
    // watch for tile changes
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tileSetDidChange:)
                                                 name:DSMapBoxTileSetChangedNotification
                                               object:nil];
    
    // restore app state
    //
    [self restoreState:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    postRotationMapCenter = mapView.contents.mapCenter;
    
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    mapView.contents.mapCenter = postRotationMapCenter;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DSMapBoxTileSetChangedNotification object:nil];
    
    [layersPopover release];
    [layerManager release];
    [dataOverlayManager release];

    [super dealloc];
}

#pragma mark -

- (void)restoreState:(id)sender
{
    if ([sender isKindOfClass:[UIBarButtonItem class]])
    {
        NSLog(@"restore from user action");
    }
    else
    {
        // load base map state
        //
        NSDictionary *baseMapState = [[NSUserDefaults standardUserDefaults] objectForKey:@"baseMapState"];
        
        if (baseMapState)
        {
            CLLocationCoordinate2D mapCenter = {
                .latitude  = [[baseMapState objectForKey:@"centerLatitude"]  floatValue],
                .longitude = [[baseMapState objectForKey:@"centerLongitude"] floatValue],
            };
            
            mapView.contents.mapCenter = mapCenter;
            
            mapView.contents.zoom = [[baseMapState objectForKey:@"zoomLevel"] floatValue];
            
            NSString *restoreTileSetURLString = [baseMapState objectForKey:@"tileSetURL"];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:restoreTileSetURLString])
            {        
                NSString *restoreTileSetName = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:[NSURL fileURLWithPath:restoreTileSetURLString]];
                
                [[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:restoreTileSetName animated:NO];
            }
        }
        
        // load tile overlay state(s)
        //
        for (NSString *tileOverlayPath in [[NSUserDefaults standardUserDefaults] arrayForKey:@"tileOverlayState"])
            for (NSDictionary *tileLayer in layerManager.tileLayers)
                if ([[[tileLayer objectForKey:@"path"] relativePath] isEqualToString:tileOverlayPath] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:tileOverlayPath])
                    [layerManager toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[layerManager.tileLayers indexOfObject:tileLayer] 
                                                                            inSection:DSMapBoxLayerSectionTile]];
        
        // load data overlay state(s)
        //
        for (NSString *dataOverlayPath in [[NSUserDefaults standardUserDefaults] arrayForKey:@"dataOverlayState"])
            for (NSDictionary *dataLayer in layerManager.dataLayers)
                if ([[dataLayer objectForKey:@"path"] isEqualToString:dataOverlayPath] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:dataOverlayPath])
                    [layerManager toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[layerManager.dataLayers indexOfObject:dataLayer] 
                                                                            inSection:DSMapBoxLayerSectionData]];
    }
}

- (void)saveState:(id)sender
{
    // get snapshot
    //
    NSData *mapSnapshot = UIImagePNGRepresentation([self mapSnapshot]);
    
    // get base map state
    //
    NSDictionary *baseMapState = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [[[DSMapBoxTileSetManager defaultManager] activeTileSetURL] relativePath], @"tileSetURL",
                                     [NSNumber numberWithFloat:mapView.contents.mapCenter.latitude],            @"centerLatitude",
                                     [NSNumber numberWithFloat:mapView.contents.mapCenter.longitude],           @"centerLongitude",
                                     [NSNumber numberWithFloat:mapView.contents.zoom],                          @"zoomLevel",
                                     nil];
    
    // get tile overlay state(s)
    //
    NSArray *tileOverlayState = [[((DSMapContents *)mapView.contents).layerMapViews valueForKeyPath:@"tileSetURL"] valueForKeyPath:@"relativePath"];
    
    // get data overlay state(s)
    //
    NSArray *dataOverlayState = [[layerManager.dataLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]]valueForKeyPath:@"path"];

    // determine if document or global save
    //
    if ([sender isKindOfClass:[UIBarButtonItem class]])
    {
        NSString *saveFolderPath = [NSString stringWithFormat:@"%@/Saved Maps", [[UIApplication sharedApplication] preferencesFolderPathString]];
        
        BOOL isDirectory = NO;
        
        if ( ! [[NSFileManager defaultManager] fileExistsAtPath:saveFolderPath isDirectory:&isDirectory] || ! isDirectory)
            [[NSFileManager defaultManager] createDirectoryAtPath:saveFolderPath attributes:nil];
        
        NSString *stateName = saveController.name;
        
        if ([stateName length] && [[stateName componentsSeparatedByString:@"/"] count] < 2) // no slashes
        {
            NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:mapSnapshot,      @"mapSnapshot", 
                                                                             baseMapState,     @"baseMapState", 
                                                                             tileOverlayState, @"tileOverlayState", 
                                                                             dataOverlayState, @"dataOverlayState", 
                                                                             nil];
            
            NSString *savePath = [NSString stringWithFormat:@"%@/%@.plist", saveFolderPath, stateName];
            
            [state writeToFile:savePath atomically:YES];
            
            [self dismissModalViewControllerAnimated:YES];
        }
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setObject:mapSnapshot      forKey:@"mapSnapshot"];
        [[NSUserDefaults standardUserDefaults] setObject:baseMapState     forKey:@"baseMapState"];
        [[NSUserDefaults standardUserDefaults] setObject:tileOverlayState forKey:@"tileOverlayState"];
        [[NSUserDefaults standardUserDefaults] setObject:dataOverlayState forKey:@"dataOverlayState"];

        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (IBAction)tappedDocumentsButton:(id)sender
{
    UIActionSheet *documentsSheet = [[[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Load Map", @"Save Map", nil] autorelease];
    
    [documentsSheet showFromBarButtonItem:sender animated:YES];
}

- (IBAction)tappedRecenterButton:(id)sender
{
    CLLocationCoordinate2D center;
    
    center.latitude  = kStartingLat;
    center.longitude = kStartingLon;
    
    [mapView moveToLatLong:center];
    
    mapView.contents.zoom = kStartingZoom;

    [mapView setRotation:0.0];
    
    [mapView setNeedsDisplay];
}

- (void)openKMLFile:(NSURL *)fileURL
{
    NSError *error = nil;
    
    SimpleKML *newKML = [SimpleKML KMLWithContentsofURL:fileURL error:&error];

    if (error)
    {
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Unable to parse KML file"
                                                         message:[NSString stringWithFormat:@"Unable to parse the given KML file. The parser reported: %@", error] 
                                                        delegate:nil
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"OK", nil] autorelease];
        
        [alert show];
    }
    else if (newKML)
    {
        NSString *source      = [fileURL relativePath];
        NSString *filename    = [[fileURL relativePath] lastPathComponent];
        NSString *destination = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], filename];
        
        [[NSFileManager defaultManager] copyItemAtPath:source toPath:destination error:NULL];
        
        [self tappedLayersButton:self];
    }
}

- (IBAction)tappedLayersButton:(id)sender
{
    if (layersPopover.popoverVisible)
        [layersPopover dismissPopoverAnimated:YES];
    
    else
    {
        if ( ! layersPopover)
        {
            DSMapBoxLayerController *layerController = [[[DSMapBoxLayerController alloc] initWithNibName:nil bundle:nil] autorelease];
            
            layerController.layerManager = layerManager;
            
            UINavigationController *wrapper = [[[UINavigationController alloc] initWithRootViewController:layerController] autorelease];
            
            layerController.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Library" 
                                                                                                 style:UIBarButtonItemStylePlain 
                                                                                                target:self
                                                                                                action:@selector(tappedLibraryButton:)] autorelease];
            
            layersPopover = [[UIPopoverController alloc] initWithContentViewController:wrapper];
            
            layersPopover.passthroughViews = nil;
        }
        
        [layersPopover presentPopoverFromBarButtonItem:layersButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (IBAction)tappedLibraryButton:(id)sender
{
    NSLog(@"show library");
}

#pragma mark -

- (void)tileSetDidChange:(NSNotification *)notification
{
    // hide layers popover
    //
    [layersPopover dismissPopoverAnimated:NO];
    
    // determine if we should animate
    //
    BOOL animated = [[notification object] boolValue];

    UIImageView *snapshotView = nil;
    
    if (animated)
    {
        // get an image of the current map
        //
        UIImage *snapshot = [self mapSnapshot];
        
        // swap map view with image view
        //
        snapshotView = [[[UIImageView alloc] initWithFrame:mapView.frame] autorelease];
        snapshotView.image = snapshot;
        [self.view insertSubview:snapshotView atIndex:0];
        [mapView removeFromSuperview];
    }
    
    // adjust map view to new auto-reloaded tile source settings
    //
    DSMapBoxSQLiteTileSource *tileSource = mapView.contents.tileSource;
    
    float newZoom = -1;
    
    if (mapView.contents.zoom < [tileSource minZoom])
        newZoom = [tileSource minZoom];
    
    else if (mapView.contents.zoom > [tileSource maxZoom])
        newZoom = [tileSource maxZoom];
    
    if (newZoom >= 0)
        mapView.contents.zoom = newZoom;

    mapView.contents.minZoom = [tileSource minZoom];
    mapView.contents.maxZoom = [tileSource maxZoom];

    // jiggle the map a bit to reload
    //
    float currentZoom = mapView.contents.zoom;
    
    if (currentZoom < [tileSource maxZoom])
        mapView.contents.zoom = currentZoom + 1.0;
    
    else if (currentZoom > [tileSource minZoom])
        mapView.contents.zoom = currentZoom - 1.0;
    
    mapView.contents.zoom = currentZoom;
    
    if (animated)
    {
        // start up page turn sound effect
        //
        NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"page_flip" ofType:@"wav"]];
        SystemSoundID sound;
        AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &sound);
        AudioServicesAddSystemSoundCompletion(sound, NULL, NULL, SoundCompletionProc, self);
        AudioServicesPlaySystemSound(sound);
        
        // animate swap from old snapshot to new map
        //
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
        [UIView setAnimationDuration:0.8];
        [snapshotView removeFromSuperview];
        [self.view insertSubview:mapView atIndex:0];
        [UIView commitAnimations];
    }
}

void SoundCompletionProc (SystemSoundID sound, void *clientData)
{
    AudioServicesDisposeSystemSoundID(sound);
}

- (UIImage *)mapSnapshot
{
    // get full screen
    //
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *full = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // crop out top toolbar
    //
    CGImageRef cropped = CGImageCreateWithImageInRect(full.CGImage, CGRectMake(0, 
                                                                               toolbar.frame.size.height, 
                                                                               full.size.width, 
                                                                               full.size.height - toolbar.frame.size.height));
    
    // convert & clean up
    //
    UIImage *snapshot = [UIImage imageWithCGImage:cropped];
    CGImageRelease(cropped);

    return snapshot;
}

#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.firstOtherButtonIndex)
    {
        loadController = [[[DSMapBoxDocumentLoadController alloc] initWithNibName:nil bundle:nil] autorelease];

        UINavigationController *wrapper = [[[UINavigationController alloc] initWithRootViewController:loadController] autorelease];
        
        wrapper.navigationBar.barStyle = UIBarStyleBlack;
        
        loadController.navigationItem.leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                             style:UIBarButtonItemStylePlain
                                                                                            target:self
                                                                                            action:@selector(dismissModalViewControllerAnimated:)] autorelease];
        
        wrapper.modalPresentationStyle = UIModalPresentationFullScreen;
        wrapper.modalTransitionStyle   = UIModalTransitionStyleFlipHorizontal;

        [self presentModalViewController:wrapper animated:YES];
    }
    else
    {
        saveController = [[[DSMapBoxDocumentSaveController alloc] initWithNibName:nil bundle:nil] autorelease];
        
        saveController.snapshot = [self mapSnapshot];
        saveController.name     = [[NSDate date] description];

        UINavigationController *wrapper = [[[UINavigationController alloc] initWithRootViewController:saveController] autorelease];
        
        wrapper.navigationBar.barStyle = UIBarStyleBlack;
        
        saveController.navigationItem.leftBarButtonItem  = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                             style:UIBarButtonItemStylePlain
                                                                                            target:self
                                                                                            action:@selector(dismissModalViewControllerAnimated:)] autorelease];
        
        saveController.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Save" 
                                                                                             style:UIBarButtonItemStyleDone 
                                                                                            target:self
                                                                                            action:@selector(saveState:)] autorelease];
        
        wrapper.modalPresentationStyle = UIModalPresentationFormSheet;

        [self presentModalViewController:wrapper animated:YES];
    }
}

@end