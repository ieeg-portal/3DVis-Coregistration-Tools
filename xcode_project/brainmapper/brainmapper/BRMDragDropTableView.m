//
//  BRMDragDropTableView.m
//  brainmapper
//
//  Created by Joost Wagenaar on 11/12/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import "BRMDragDropTableView.h"

@implementation BRMDragDropTableView

- (void) awakeFromNib
{
	// Register to accept filename drag/drop
    NSLog(@"help");
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	// Need the delegate hooked up to accept the dragged item(s) into the model
	if ([self delegate]==nil)
	{
		return NSDragOperationNone;
	}
	
	if ([[[sender draggingPasteboard] types] containsObject:NSFilenamesPboardType])
	{
		return NSDragOperationCopy;
	}
	
	return NSDragOperationNone;
}

// Work around a bug from 10.2 onwards
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationEvery;
}

// Stop the NSTableView implementation getting in the way
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [self draggingEntered:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	int i;
	NSPasteboard *pboard;
	pboard = [sender draggingPasteboard];
    
	if ([[pboard types] containsObject:NSFilenamesPboardType])
	{
		id delegate = [self delegate];
		NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
		if ([delegate respondsToSelector:@selector(acceptFilenameDrag:)])
		{
			for (i=0;i<[filenames count];i++)
			{
                NSLog(@"data");
                NSArray * arrayOfThingsIWantToPassAlong =
                [NSArray arrayWithObjects: [filenames objectAtIndex:i], self, nil];
                
//				[delegate performSelector:@selector(acceptFilenameDrag:) withObject:[filenames objectAtIndex:i]];
                [delegate performSelector:@selector(acceptFilenameDrag:) withObject:arrayOfThingsIWantToPassAlong];

			}
		}
        NSLog(@"accept data");
		return YES;
	}
	return NO;
}



@end
