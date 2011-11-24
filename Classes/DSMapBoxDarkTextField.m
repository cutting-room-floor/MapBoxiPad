//
//  DSMapBoxDarkTextField.m
//  MapBoxiPad
//
//  Created by Justin Miller on 11/23/11.
//  Copyright (c) 2011 Development Seed. All rights reserved.
//

#import "DSMapBoxDarkTextField.h"

#import <QuartzCore/QuartzCore.h>

@interface DSMapBoxDarkTextField ()

@property (nonatomic, retain) UIView *backgroundView;

- (void)DSMapBoxDarkTextField_commonInit;

@end

#pragma mark -

@implementation DSMapBoxDarkTextField

@synthesize backgroundView;

- (id)initWithCoder:(NSCoder *)decoder
{
    // This covers NIB-loaded text fields.
    //
    self = [super initWithCoder:decoder];
    
    if (self != nil)
        [self DSMapBoxDarkTextField_commonInit];
    
    return self;
}

- (id)initWithFrame:(CGRect)rect
{
    // This covers programmatically-created text fields.
    //
    self = [super initWithFrame:rect];
    
    if (self != nil)
        [self DSMapBoxDarkTextField_commonInit];
    
    return self;
}

- (void)DSMapBoxDarkTextField_commonInit
{
    // setup styling
    //
    self.textColor       = [UIColor colorWithWhite:1.0 alpha:0.75];
    self.backgroundColor = [UIColor clearColor];
    self.borderStyle     = UITextBorderStyleNone;
    
    // disable normal clear button (since it's dark)
    //
    self.clearButtonMode = UITextFieldViewModeNever;
    
    // add custom white clear button
    //
    UIButton *customClearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [customClearButton setImage:[UIImage imageNamed:@"white_clear.png"] forState:UIControlStateNormal];
    
    [customClearButton addTarget:self 
                          action:@selector(clearText:) 
                forControlEvents:UIControlEventTouchUpInside];
    
    customClearButton.frame = CGRectMake(0, 
                                         0, 
                                         [customClearButton imageForState:UIControlStateNormal].size.width, 
                                         [customClearButton imageForState:UIControlStateNormal].size.height);

    customClearButton.alpha = 0.5;
    
    self.rightView = customClearButton;
}

- (void)dealloc
{
    [backgroundView release];
    
    [super dealloc];
}

#pragma mark -

- (void)setText:(NSString *)inText
{
    // set dark backing view
    //
    if ( ! self.backgroundView)
    {
        self.backgroundView = [[[UIView alloc] initWithFrame:CGRectMake(self.frame.origin.x, 
                                                                        self.frame.origin.y    + 1, 
                                                                        self.frame.size.width  + 20, 
                                                                        self.frame.size.height + 10)] autorelease];
        
        self.backgroundView.backgroundColor    = [UIColor blackColor];
        self.backgroundView.layer.cornerRadius = 10.0;
        
        [self.superview insertSubview:self.backgroundView belowSubview:self];

        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(textWasEdited:) 
                                                     name:UITextFieldTextDidChangeNotification 
                                                   object:self];
    }
    
    [super setText:inText];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
}

#pragma mark -

- (void)clearText:(id)sender
{
    self.text = @"";
}

#pragma mark -

- (void)textWasEdited:(NSNotification *)notification
{
    if ([self.text length])
        self.rightViewMode = UITextFieldViewModeAlways;
    
    else
        self.rightViewMode = UITextFieldViewModeNever;
}

@end