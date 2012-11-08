//
//  BRM_AppController.m
//  brainmapper
//
//  Created by Joost Wagenaar on 11/6/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import "BRM_AppController.h"

@implementation BRM_AppController

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
                [targetPath setStringValue:[fileURL absoluteString]];
            }
        }
        
    }];
}

@end
