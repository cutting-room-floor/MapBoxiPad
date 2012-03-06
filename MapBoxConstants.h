//
// Global constants, macros, and preprocessor directives.
//

//
// Constants
//
#define KSupportEmail              @"ipad@mapbox.com"
#define kSupportURL                @"http://support.mapbox.com/discussions/mapbox-for-ipad#new_topic_form"
#define kReleaseNotesURL           @"http://mapbox.com/ipad/release-notes/"
#define kTileStreamHostingPrefix   @"http://tiles.mapbox.com"
#define kTileStreamDefaultAccount  @"mapbox"
#define kTileStreamAlbumAPIPath    @"/api/v1/Album"
#define kTileStreamTilesetAPIPath  @"/api/v1/Tileset"
#define kTileStreamMapAPIPath      @"/api/v1/Map"
#define kTileStreamFolderName      @"Online Layers"
#define kDownloadsFolderName       @"Downloads"
#define kMBTilesURLSchemePrefix    @"mbhttp"
#define kPartialDownloadExtension  @"mbdownload"
#define kTestFlightTeamToken       @"e801c1913c6812d34c0c7764f6bf406a_OTIwOA"
#define kMapBoxBlue                [UIColor colorWithRed:0.116 green:0.550 blue:0.670 alpha:1.000]
#define kDSOpenStreetMapURL        [NSURL URLWithString:@"file://localhost/tmp/OpenStreetMap"]
#define kDSOpenStreetMapName       @"OpenStreetMap"
#define kDSMapQuestOSMURL          [NSURL URLWithString:@"file://localhost/tmp/MapQuestOSM"]
#define kDSMapQuestOSMName         @"MapQuest Open"
#define kStartingLat               14.37292766571045f
#define kStartingLon              -16.428955078125
#define kStartingZoom               2.5f
#define kLowerZoomBounds            2.5f
#define kUpperZoomBounds           22.0f
#define kUpperLatitudeBounds       85.0511f
#define kLowerLatitudeBounds      -85.0511f

//
// Macros
//
#define SYSTEM_VERSION_EQUAL_TO(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)             ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)    ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)