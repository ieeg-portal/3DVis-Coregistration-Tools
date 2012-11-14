//
//  ImageSlice.m
//  brainmapper
//
//  Created by Joost Wagenaar on 11/12/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import "ImageSlice.h"

@implementation ImageSlice
@synthesize index, pathStr;

- (id)init {
    self = [super init];
    if(self) {
        pathStr = [[NSString alloc] init];
        index = [[NSString alloc] init];
    }
    return self;
}


@end
