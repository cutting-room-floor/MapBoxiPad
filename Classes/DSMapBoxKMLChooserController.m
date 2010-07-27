//
//  DSMapBoxKMLChooserController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 7/22/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxKMLChooserController.h"
#import "DSMapBoxDataOverlayManager.h"
#import "UIApplication_Additions.h"
#import "SimpleKML.h"

@interface DSMapBoxKMLChooserController (DSMapBoxKMLChooserControllerPrivate)

- (void)reloadDocuments;

@end

#pragma mark -

@implementation DSMapBoxKMLChooserController

@synthesize overlayManager;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    entities = [[NSMutableArray array] retain];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self reloadDocuments];
}

- (void)dealloc
{
    [overlayManager release];
    [entities release];
    
    [super dealloc];
}

#pragma mark -

- (void)reloadDocuments
{
    NSArray *docs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[UIApplication sharedApplication] documentsFolderPathString] error:NULL];
    
    for (NSString *path in docs)
    {
        path = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] documentsFolderPathString], path];
        
        if ([[path pathExtension] isEqualToString:@"kml"] && ! [[entities valueForKeyPath:@"path"] containsObject:path])
        {            
            NSMutableDictionary *entity = [NSMutableDictionary dictionaryWithObjectsAndKeys:path,                         @"path", 
                                                                                            [path lastPathComponent],     @"name",
                                                                                            [NSNumber numberWithBool:NO], @"selected",
                                                                                            nil];
                                    
            [entities addObject:entity];
        }
    }
    
    [entities sortUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease]]];
    
    [self.tableView reloadData];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [entities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ( ! cell)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    
    NSMutableDictionary *entity = [entities objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [entity valueForKeyPath:@"name"];

    if ([[entity valueForKeyPath:@"selected"] boolValue])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableDictionary *entity = [entities objectAtIndex:indexPath.row];

    if ([[entity valueForKeyPath:@"selected"] boolValue])
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;

        [entity setObject:[NSNumber numberWithBool:NO] forKey:@"selected"];
        
        [overlayManager removeOverlayWithSource:[entity objectForKey:@"source"]];
    }
    else
    {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        
        [entity setObject:[NSNumber numberWithBool:YES] forKey:@"selected"];
        
        SimpleKML *kml = [SimpleKML KMLWithContentsOfFile:[entity objectForKey:@"path"] error:NULL];
        
        [overlayManager addOverlayForKML:kml];

        if ( ! [entity objectForKey:@"source"])
        {
            NSString *source = [NSString stringWithContentsOfFile:[entity objectForKey:@"path"] encoding:NSUTF8StringEncoding error:NULL];
            
            [entity setObject:source forKey:@"source"];
        }
    }
}

@end