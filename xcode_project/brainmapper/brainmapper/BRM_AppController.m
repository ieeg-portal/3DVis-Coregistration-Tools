//
//  BRM_AppController.m
//  brainmapper
//
//  Created by Joost Wagenaar on 11/6/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import "BRM_AppController.h"

@implementation BRM_AppController
@synthesize mriArray, ctArray, hasDepth, inclSegm;

- (id)init
{
	self = [super init];
    if(self){
        NSLog( @"init" );
        mriArray = [[NSMutableArray alloc] init];
        ctArray = [[NSMutableArray alloc] init];
        hasDepth = FALSE;
        inclSegm = FALSE;
    }
 	return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [textField setHidden:TRUE];
    [processInd setHidden:TRUE];
}

- (IBAction)start:(id)sender
{
    // This code should initialyze/start the coregistration scripts.
    NSLog(@"Starting");
    [textField setStringValue: @"Coregistering..."];
    [processInd startAnimation:self];
    [textField setHidden:NO];
    [processInd setHidden:NO];
    }

#pragma mark TableView methods
- (void) acceptFilenameDrag:(NSArray *) filename
             {
                 
    if([filename objectAtIndex:1]==mriView){
        [mriArray addObject:[filename objectAtIndex:0]];
        NSLog(@"addObject");
                [mriView reloadData];
    }
    else if([filename objectAtIndex:1] == ctView){
        [ctArray addObject:[filename objectAtIndex:0]];
        NSLog(@"addObject");
        NSLog([NSString stringWithFormat:@"%ld",[ctArray count] ] );
        [ctView reloadData];
        
    }
	
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    
    if(tableView==mriView){
    
        return (int)[mriArray count];
    }
    else if(tableView == ctView){
        return (int)[ctArray count];
    }
    else
    {
        return 0;
    }
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row
{
    if(tableView==mriView){
        
        return [mriArray objectAtIndex:row];    }
    else if(tableView == ctView){
        return [ctArray  objectAtIndex:row];
    }
    else {
        return 0;
    }
    
}

@end
