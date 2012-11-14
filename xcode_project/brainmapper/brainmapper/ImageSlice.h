//
//  ImageSlice.h
//  brainmapper
//
//  Created by Joost Wagenaar on 11/12/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageSlice : NSObject {
    NSString *pathStr;
    NSString *index;
}

@property NSString *pathStr;
@property NSString *index;

@end
