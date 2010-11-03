//
//  MapBoxMainViewController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 6/17/10.
//  Copyright Code Sorcery Workshop 2010. All rights reserved.
//

#import "MapBoxMainViewController.h"

#import "DSMapBoxSQLiteTileSource.h"
#import "DSMapBoxTileSetManager.h"
#import "DSMapBoxDataOverlayManager.h"
#import "DSMapContents.h"
#import "DSMapBoxLayerController.h"
#import "DSMapBoxDocumentSaveController.h"
#import "DSMapBoxMarkerManager.h"

#import "UIApplication_Additions.h"

#import "SimpleKML.h"

#import "RMMapView.h"
#import "RMTileSource.h"
#import "RMOpenStreetMapSource.h"

#import "TouchXML.h"

#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

#import "Reachability.h"

#define KSupportEmail @"ipad@mapbox.com"
#define kStartingLat   14.37292766571045f
#define kStartingLon  -16.428955078125
#define kStartingZoom   2.5f

@interface MapBoxMainViewController (MapBoxiPadDemoViewControllerPrivate)

void MapBoxiPadDemoViewController_SoundCompletionProc (SystemSoundID sound, void *clientData);
- (void)offlineAlert;
- (UIImage *)mapSnapshot;

@end

#pragma mark -

@implementation MapBoxMainViewController

@synthesize badParsePath;

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
    mapView.deceleration = NO;
    
    mapView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"linen.png"]];

    mapView.contents.zoom = kStartingZoom;

    // data overlay & layer managers
    //
    dataOverlayManager = [[DSMapBoxDataOverlayManager alloc] initWithMapView:mapView];
    dataOverlayManager.mapView = mapView;
    mapView.delegate = dataOverlayManager;
    layerManager = [[DSMapBoxLayerManager alloc] initWithDataOverlayManager:dataOverlayManager overBaseMapView:mapView];
    layerManager.delegate = self;
    
    // watch for tile changes
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tileSetDidChange:)
                                                 name:DSMapBoxTileSetChangedNotification
                                               object:nil];
    
    // watch for net changes
    //
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityDidChange:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    reachability = [[Reachability reachabilityForInternetConnection] retain];
    [reachability startNotifer];
    
    // restore app state
    //
    [self restoreState:self];
    
    // warn about any zipped mbtiles
    //
    BOOL showedZipAlert = NO;
    
    NSPredicate *zippedPredicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.mbtiles.zip'"];
    
    NSArray *zippedTiles = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPathString]
                                                                                error:NULL] filteredArrayUsingPredicate:zippedPredicate];
    
    NSMutableSet *seenZips = [NSMutableSet set];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"seenZippedTiles"])
        [seenZips addObjectsFromArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"seenZippedTiles"]];
    
    for (NSString *zippedTile in zippedTiles)
    {
        if ( ! [seenZips containsObject:zippedTile] && ! showedZipAlert)
        {
            NSString *appName = [[NSProcessInfo processInfo] processName];
            
            [seenZips addObject:zippedTile];
            
            UIAlertView *zipAlert = [[[UIAlertView alloc] initWithTitle:@"Zipped Tiles Found"
                                                                message:[NSString stringWithFormat:@"Your %@ documents contain zipped tiles. Please unzip these tiles first in order to use them in %@.", appName, appName] 
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil] autorelease];
            
            [zipAlert show];
            
            showedZipAlert = YES;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[seenZips allObjects] forKey:@"seenZippedTiles"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification   object:nil];
    
    [reachability stopNotifer];
    [reachability release];
    
    [layersPopover release];
    [layerManager release];
    [dataOverlayManager release];
    [badParsePath release];
    [documentsActionSheet release];

    [super dealloc];
}

#pragma mark -

- (void)restoreState:(id)sender
{
    NSDictionary *baseMapState;
    NSArray *tileOverlayState;
    NSArray *dataOverlayState;
    
    // determine if document or global restore
    //
    if ([sender isKindOfClass:[NSString class]])
    {
        NSString *saveFile = [NSString stringWithFormat:@"%@/%@/%@.plist", [[UIApplication sharedApplication] preferencesFolderPathString], kDSSaveFolderName, sender];
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:saveFile];
        
        baseMapState = [data objectForKey:@"baseMapState"];
        tileOverlayState  = [data objectForKey:@"tileOverlayState"];
        dataOverlayState  = [data objectForKey:@"dataOverlayState"];
    }
    else
    {
        baseMapState = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"baseMapState"];
        tileOverlayState  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"tileOverlayState"];
        dataOverlayState  = [[NSUserDefaults standardUserDefaults] arrayForKey:@"dataOverlayState"];
    }
    
    // load it up
    //
    if (baseMapState)
    {
        CLLocationCoordinate2D mapCenter = {
            .latitude  = [[baseMapState objectForKey:@"centerLatitude"]  floatValue],
            .longitude = [[baseMapState objectForKey:@"centerLongitude"] floatValue],
        };
        
        mapView.contents.mapCenter = mapCenter;
        
        mapView.contents.zoom = [[baseMapState objectForKey:@"zoomLevel"] floatValue];
        
        NSString *restoreTileSetURLString = [baseMapState objectForKey:@"tileSetURL"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:restoreTileSetURLString] || [restoreTileSetURLString isEqual:kDSOpenStreetMapURL])
        {        
            NSString *restoreTileSetName = [[DSMapBoxTileSetManager defaultManager] displayNameForTileSetAtURL:[NSURL fileURLWithPath:restoreTileSetURLString]];
            
            if ([restoreTileSetName isEqualToString:kDSOpenStreetMapURL] && [reachability currentReachabilityStatus] == NotReachable)
                [self offlineAlert];
            
            else
                [[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:restoreTileSetName animated:NO];
        }
    }
    
    // load tile overlay state(s)
    //
    if (tileOverlayState)
    {
        // remove current layers
        //
        NSArray *activeTileLayers = [layerManager.tileLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]];
        for (NSDictionary *tileLayer in activeTileLayers)
            [layerManager toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[layerManager.tileLayers indexOfObject:tileLayer]
                                                                    inSection:DSMapBoxLayerSectionTile]];
        
        // toggle new ones
        //
        for (NSString *tileOverlayPath in tileOverlayState)
            for (NSDictionary *tileLayer in layerManager.tileLayers)
                if ([[[tileLayer objectForKey:@"path"] relativePath] isEqualToString:tileOverlayPath] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:tileOverlayPath])
                    [layerManager toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[layerManager.tileLayers indexOfObject:tileLayer] 
                                                                            inSection:DSMapBoxLayerSectionTile]];
    }
    
    // load data overlay state(s)
    //
    if (dataOverlayState)
    {
        // remove current layers
        //
        NSArray *activeDataLayers = [layerManager.dataLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]];
        for (NSDictionary *dataLayer in activeDataLayers)
            [layerManager toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[layerManager.dataLayers indexOfObject:dataLayer]
                                                                    inSection:DSMapBoxLayerSectionData]];

        // toggle new ones
        //
        for (NSString *dataOverlayPath in dataOverlayState)
            for (NSDictionary *dataLayer in layerManager.dataLayers)
                if ([[dataLayer objectForKey:@"path"] isEqualToString:dataOverlayPath] &&
                    [[NSFileManager defaultManager] fileExistsAtPath:dataOverlayPath])
                    [layerManager toggleLayerAtIndexPath:[NSIndexPath indexPathForRow:[layerManager.dataLayers indexOfObject:dataLayer] 
                                                                            inSection:DSMapBoxLayerSectionData]];
    }

    if ([sender isKindOfClass:[NSString class]])
        [self dismissModalViewControllerAnimated:YES];
}

- (void)saveState:(id)sender
{
    // get snapshot
    //
    NSData *mapSnapshot = UIImageJPEGRepresentation([self mapSnapshot], 1.0);
    
    // get base map state
    //
    NSString *tileSetURLString;
    
    if ([[[DSMapBoxTileSetManager defaultManager] activeTileSetURL] isEqual:kDSOpenStreetMapURL])
        tileSetURLString = [NSString stringWithFormat:@"%@", [[DSMapBoxTileSetManager defaultManager] activeTileSetURL]];
    
    else
        tileSetURLString = [[[DSMapBoxTileSetManager defaultManager] activeTileSetURL] relativePath];
    
    NSDictionary *baseMapState = [NSDictionary dictionaryWithObjectsAndKeys:
                                     tileSetURLString,                                                @"tileSetURL",
                                     [NSNumber numberWithFloat:mapView.contents.mapCenter.latitude],  @"centerLatitude",
                                     [NSNumber numberWithFloat:mapView.contents.mapCenter.longitude], @"centerLongitude",
                                     [NSNumber numberWithFloat:mapView.contents.zoom],                @"zoomLevel",
                                     nil];
    
    // get tile overlay state(s)
    //
    NSArray *tileOverlayState = [[((DSMapContents *)mapView.contents).layerMapViews valueForKeyPath:@"tileSetURL"] valueForKeyPath:@"relativePath"];
    
    // get data overlay state(s)
    //
    NSArray *dataOverlayState = [[layerManager.dataLayers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"selected = YES"]]valueForKeyPath:@"path"];

    // determine if document or global save
    //
    if ([sender isKindOfClass:[UIBarButtonItem class]] || [sender isKindOfClass:[NSString class]])
    {
        NSString *saveFolderPath = [DSMapBoxDocumentLoadController saveFolderPath];
        
        BOOL isDirectory = NO;
        
        if ( ! [[NSFileManager defaultManager] fileExistsAtPath:saveFolderPath isDirectory:&isDirectory] || ! isDirectory)
            [[NSFileManager defaultManager] createDirectoryAtPath:saveFolderPath 
                                      withIntermediateDirectories:YES 
                                                       attributes:nil
                                                            error:NULL];
        
        NSString *stateName;
        
        if ([sender isKindOfClass:[UIBarButtonItem class]]) // button save
            stateName = saveController.name;
        
        else if ([sender isKindOfClass:[NSString class]]) // load controller save
            stateName = sender;
        
        if ([stateName length] && [[stateName componentsSeparatedByString:@"/"] count] < 2) // no slashes
        {
            NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:mapSnapshot,      @"mapSnapshot", 
                                                                             baseMapState,     @"baseMapState", 
                                                                             tileOverlayState, @"tileOverlayState", 
                                                                             dataOverlayState, @"dataOverlayState", 
                                                                             nil];
            
            NSString *savePath = [NSString stringWithFormat:@"%@/%@.plist", saveFolderPath, stateName];
            
            [state writeToFile:savePath atomically:YES];
            
            if (self.modalViewController.modalPresentationStyle == UIModalPresentationFormSheet) // save panel
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
    if (layersPopover.popoverVisible)
        [layersPopover dismissPopoverAnimated:NO];

    if ( ! documentsActionSheet || ! documentsActionSheet.visible)
    {
        documentsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Load Map", @"Save Map", nil];
        
        [documentsActionSheet showFromBarButtonItem:sender animated:YES];
    }

    else
        [documentsActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
}

- (void)openKMLFile:(NSURL *)fileURL
{
    NSError *error = nil;
    
    SimpleKML *newKML = [SimpleKML KMLWithContentsOfURL:fileURL error:&error];

    if (error)
        [self dataLayerHandler:self didFailToHandleDataLayerAtPath:[fileURL relativePath]];

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
            
            layersPopover = [[UIPopoverController alloc] initWithContentViewController:wrapper];
            
            layersPopover.passthroughViews = nil;
        }
        
        [layersPopover presentPopoverFromBarButtonItem:layersButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (IBAction)tappedClusteringButton:(id)sender
{
    DSMapBoxMarkerManager *markerManager = (DSMapBoxMarkerManager *)mapView.contents.markerManager;
    
    markerManager.clusteringEnabled = ! markerManager.clusteringEnabled;
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
    
    // replace map with image to animate away
    //
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
    
    // force switch to new tile source to update tiles
    //
    NSURL *newTileSetURL = [[DSMapBoxTileSetManager defaultManager] activeTileSetURL];
    
    if ([newTileSetURL isEqual:kDSOpenStreetMapURL])
        mapView.contents.tileSource = [[[RMOpenStreetMapSource alloc] init] autorelease];
    
    else
        mapView.contents.tileSource = [[[DSMapBoxSQLiteTileSource alloc] initWithTileSetAtURL:newTileSetURL] autorelease];

    // perform image to map animated swap back
    //
    if (animated)
    {
        // start up page turn sound effect
        //
        NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"page_flip" ofType:@"wav"]];
        SystemSoundID sound;
        AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &sound);
        AudioServicesAddSystemSoundCompletion(sound, NULL, NULL, MapBoxiPadDemoViewController_SoundCompletionProc, self);
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

void MapBoxiPadDemoViewController_SoundCompletionProc (SystemSoundID sound, void *clientData)
{
    AudioServicesDisposeSystemSoundID(sound);
}

- (void)reachabilityDidChange:(NSNotification *)notification
{
    if ([[[DSMapBoxTileSetManager defaultManager] activeTileSetURL] isEqual:kDSOpenStreetMapURL] && [(Reachability *)[notification object] currentReachabilityStatus] == NotReachable)
        [self offlineAlert];
}

- (void)offlineAlert
{
    [[DSMapBoxTileSetManager defaultManager] makeTileSetWithNameActive:[[DSMapBoxTileSetManager defaultManager] defaultTileSetName] animated:NO];
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Now Offline"
                                                     message:[NSString stringWithFormat:@"You are now offline. %@ tiles require an active internet connection, so %@ was activated instead.", kDSOpenStreetMapURL, [[DSMapBoxTileSetManager defaultManager] defaultTileSetName]]
                                                    delegate:nil
                                           cancelButtonTitle:nil
                                           otherButtonTitles:@"OK", nil] autorelease];
    
    [alert performSelector:@selector(show) withObject:nil afterDelay:0.0];
}

- (UIImage *)mapSnapshot
{
    // zoom to even zoom level to avoid artifacts
    //
    CGFloat oldZoom = mapView.contents.zoom;
    CGPoint center  = CGPointMake(mapView.frame.size.width / 2, mapView.frame.size.height / 2);
    
    if ((CGFloat)ceil(oldZoom) - oldZoom < 0.5)    
        [mapView.contents zoomInToNextNativeZoomAt:center];
    
    else
        [mapView.contents zoomOutToNextNativeZoomAt:center];
    
    // get full screen snapshot
    //
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *full = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // restore previous zoom
    //
    float factor = exp2f(oldZoom - [mapView.contents zoom]);
    [mapView.contents zoomByFactor:factor near:center];
    
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
        
        loadController.delegate = self;
        
        wrapper.modalPresentationStyle = UIModalPresentationFullScreen;
        wrapper.modalTransitionStyle   = UIModalTransitionStyleFlipHorizontal;

        [self presentModalViewController:wrapper animated:YES];
    }
    else if (buttonIndex > -1)
    {
        saveController = [[[DSMapBoxDocumentSaveController alloc] initWithNibName:nil bundle:nil] autorelease];
        
        saveController.snapshot = [self mapSnapshot];
        
        NSUInteger i = 1;
        
        NSString *docName = nil;
        
        while ( ! docName)
        {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@%@.plist", [DSMapBoxDocumentLoadController saveFolderPath], kDSSaveFileName, (i == 1 ? @"" : [NSString stringWithFormat:@" %i", i])]])
                i++;
            
            else
                docName = [NSString stringWithFormat:@"%@%@", kDSSaveFileName, (i == 1 ? @"" : [NSString stringWithFormat:@" %i", i])];
        }
        
        saveController.name = docName;
        
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

#pragma mark -

- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller didLoadDocumentWithName:(NSString *)name
{
    [self restoreState:name];
}

- (void)documentLoadController:(DSMapBoxDocumentLoadController *)controller wantsToSaveDocumentWithName:(NSString *)name
{
    [self saveState:name];
}

#pragma mark -

- (void)dataLayerHandler:(id)handler didFailToHandleDataLayerAtPath:(NSString *)path
{
    self.badParsePath = path;
    
    NSString *message = [NSString stringWithFormat:@"%@ was unable to handle the %@ file. Please contact us with a copy of the file in order to request support for it.", [[NSProcessInfo processInfo] processName], ([path hasSuffix:@".kml"] ? @"KML" : @"KMZ")];
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Layer Problem"
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Send Mail", nil] autorelease];
    
    [alert show];
}

#pragma mark -

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex)
    {
        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController *mailer = [[[MFMailComposeViewController alloc] init] autorelease];
            
            mailer.mailComposeDelegate = self;
            
            [mailer setToRecipients:[NSArray arrayWithObject:KSupportEmail]];
            [mailer setMessageBody:@"<em>Please provide any additional details about this file or about the error you encountered here.</em>" isHTML:YES];
            
            if ([self.badParsePath hasSuffix:@".kml"])
            {
                [mailer setSubject:@"Problem KML file"];
                
                [mailer addAttachmentData:[NSData dataWithContentsOfFile:self.badParsePath]                       
                                 mimeType:@"application/vnd.google-earth.kml+xml" 
                                 fileName:[self.badParsePath lastPathComponent]];
            }
            else if ([self.badParsePath hasSuffix:@".kmz"])
            {
                [mailer setSubject:@"Problem KMZ file"];
                
                [mailer addAttachmentData:[NSData dataWithContentsOfFile:self.badParsePath]                       
                                 mimeType:@"application/vnd.google-earth.kmz" 
                                 fileName:[self.badParsePath lastPathComponent]];
            }
            
            mailer.modalPresentationStyle = UIModalPresentationFormSheet;
            
            [self presentModalViewController:mailer animated:YES];
        }
        else
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Mail Not Setup"
                                                             message:@"Please setup Mail first."
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil] autorelease];
            
            [alert show];
        }
    }
}

#pragma mark -

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultFailed:
            
            [self dismissModalViewControllerAnimated:NO];
            
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Mail Failed"
                                                             message:@"There was a problem sending the mail."
                                                            delegate:nil
                                                   cancelButtonTitle:nil
                                                   otherButtonTitles:@"OK", nil] autorelease];
            
            [alert show];
            
            break;
            
        default:
            
            [self dismissModalViewControllerAnimated:YES];
    }
}

@end