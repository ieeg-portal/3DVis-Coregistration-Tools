//
//  BRM_AppController.m
//  brainmapper
//
//  Created by Joost Wagenaar on 11/6/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import "BRM_AppController.h"

@implementation BRM_AppController
@synthesize mriArray, ctArray;

- (id)init
{
	self = [super init];
    if(self){
        NSLog( @"init" );
        mriArray = [[NSMutableArray alloc] init];
        ctArray = [[NSMutableArray alloc] init];
    }
 	return self;
}

- (IBAction)start:(id)sender
{
    NSLog(@"Starting");
    [textField setStringValue: @"init"];
}

-(IBAction)pickPath:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    // Configure your panel the way you want it
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            
            for (NSURL *fileURL in [panel URLs]) {
                // Do what you want with fileURL
                [targetPath setURL: (NSURL *)fileURL];
            }
        }
        
    }];
}

#pragma mark TableView methods

- (void) acceptFilenameDrag:(NSArray *) filename
             {
                 
    if([filename objectAtIndex:1]==mriView){
        [mriArray addObject:[filename objectAtIndex:0]];
        NSLog(@"addObject");
        NSLog([NSString stringWithFormat:@"%ld",[mriArray count] ] );
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
    
        return [mriArray count];
    }
    else if(tableView == ctView){
        return [ctArray count];
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
