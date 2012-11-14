//
//  BRM_AppController.h
//  brainmapper
//
//  Created by Joost Wagenaar on 11/6/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BRM_AppController : NSObject
{
    IBOutlet NSTextField *textField;
    IBOutlet NSTableView *mriView;
    IBOutlet NSTableView *ctView;
    IBOutlet NSPathControl *targetPath;
    
    NSMutableArray *mriArray;
    NSMutableArray *ctArray;

}
@property (copy) NSMutableArray *mriArray, *ctArray;

@end
