//
//  DSMapBoxDocumentLoadController.m
//  MapBoxiPadDemo
//
//  Created by Justin R. Miller on 8/9/10.
//  Copyright 2010 Code Sorcery Workshop. All rights reserved.
//

#import "DSMapBoxDocumentLoadController.h"

#import "UIApplication_Additions.h"

@implementation DSMapBoxDocumentLoadController

@synthesize delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *saveFolderPath = [NSString stringWithFormat:@"%@/%@", [[UIApplication sharedApplication] preferencesFolderPathString], kDSSaveFolderName];
    
    NSArray *saveFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:saveFolderPath error:NULL];
    
    NSUInteger count = 0;
    
    for (NSString *saveFile in saveFiles)
    {
        // get snapshot
        //
        NSDictionary *data = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", saveFolderPath, saveFile]];
        UIImage *snapshot  = [UIImage imageWithData:[data objectForKey:@"mapSnapshot"]];
        
        // add image view
        //
        UIImageView *imageView = [[[UIImageView alloc] initWithImage:snapshot] autorelease];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:imageView];
        imageView.frame = CGRectMake(20, 20 + count * 60, 50, 50);
        
        // strip extension
        //
        saveFile = [saveFile stringByReplacingOccurrencesOfString:@".plist" withString:@""];
                                                                         
        // add button
        //
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [button addTarget:self action:@selector(tappedFileButton:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:saveFile forState:UIControlStateNormal];
        [self.view addSubview:button];
        button.frame = CGRectMake(90, 20 + count * 60, 200, 50);
        
        count++;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark -

- (void)tappedFileButton:(id)sender
{
    [self.delegate documentLoadController:self didLoadDocumentWithName:((UIButton *)sender).titleLabel.text];
}

@end