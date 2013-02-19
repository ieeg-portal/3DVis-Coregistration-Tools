//
//  BRM_AppController.m
//  brainmapper
//
//  Created by Joost Wagenaar on 11/6/12.
//  Copyright (c) 2012 University of Pennsylvania. All rights reserved.
//

#import "BRM_AppController.h"

@implementation BRM_AppController
@synthesize mriArray, ctArray, hasDepth, inclSegm, destPath;



- (id)init
{
	self = [super init];
    if(self){
        NSLog( @"init" );
        mriArray = [[NSMutableArray alloc] init];
        ctArray = [[NSMutableArray alloc] init];
        destPath = [[NSString alloc] init];
        hasDepth = FALSE;
        inclSegm = FALSE;
    }
   
    //This is just for checking to see that we have the right resources, not actually involved in coregistration
    NSString *resPath=[NSString stringWithFormat:@"%@",[[NSBundle mainBundle] resourcePath]];
    NSLog(@"resource path is: %@", resPath);
    NSError *err;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:resPath error:&err];
    NSLog(@"contents of respath directory:%@",contents);
   
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
    //TODO make this user-specified
    destPath = [@"~/Desktop/Coregister" stringByExpandingTildeInPath];
    
    //Check if MRI array and CT arrays are empty
    if ([mriArray count] == 0) {
        [textField setStringValue: @"Please drag DICOM files from MRI into window"];
    }
    else if ([ctArray count] == 0) {
        [textField setStringValue:@"Please drag DICOM files from CT into window"];
    }
    else {
        // This code should initialize/start the coregistration scripts.
        NSLog(@"Starting");
        [processInd setHidden:NO];
        [textField setStringValue: @"Creating 3D model from DICOMS..."];
        [processInd startAnimation:self];
        //TODO: allow user to specify name for output
        [self stackDicomArray:(mriArray) forFile:@"mri"];
        [self stackDicomArray:(ctArray) forFile:@"ct"];
        [textField setStringValue:@"Coregistering..."];
        [self coregScript];
    }
    [textField setHidden:NO];
}

- (void) stackDicomArray:(NSMutableArray*) arr
                 forFile:(NSString*) inFile
{
    NSString *resPath=[NSString stringWithFormat:@"%@",[[NSBundle mainBundle] resourcePath]];
    NSString *execPath = [NSString stringWithFormat:@"%@/dcm2nii",resPath];
    
    //make a directory for inputs/outputs
    BOOL isDir = FALSE;
    NSError *err;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    BOOL fileExists = [fileManager fileExistsAtPath:destPath isDirectory:&isDir];
    NSLog(@"Do we have a coregister directory? %d", fileExists);
    if (!isDir || !fileExists) {
        NSLog(@"creating Coregister directory");
        if(![fileManager createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:&err]) {
            NSLog(@"Error: Create input/output folder failed");
        }
    }
    
    //stack the dicoms
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: execPath];
    NSLog(@"exec path is: %@, input arg is %@", execPath, [arr objectAtIndex:0]);
    [task setArguments:[NSArray arrayWithObject:[arr objectAtIndex:0]]];
    [task launch];
    [task waitUntilExit];
    
    //copy the new nifti into the directory
    NSString *dcmPath = [[arr objectAtIndex:0] stringByDeletingLastPathComponent];
    NSArray *niftis = [[fileManager contentsOfDirectoryAtPath:dcmPath error:&err]filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.nii.gz'"]];
    NSString *nifti;
    //NEED TO TEST THIS 
    if ([niftis count] == 3) {
        nifti = [[niftis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH 'co'"]] objectAtIndex:0];
    } else if ([niftis count] == 2) {
        nifti = [[niftis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH 'o'"]] objectAtIndex:0];
    } else if ([niftis count] == 1) {
        nifti = [niftis objectAtIndex:0];
    } else {
        NSLog(@"error: incorrect number of nifti files");
    }
    NSString *movePath = [NSString stringWithFormat:@"%@/%@.nii.gz",destPath,inFile];
    NSString *fromPath = [NSString stringWithFormat:@"%@/%@",dcmPath,nifti];
    //make sure there aren't multiple files of the same name
    if ([fileManager fileExistsAtPath:movePath]) {
        int append = 1;
        while([fileManager fileExistsAtPath: [NSString stringWithFormat:@"%@/%@_%d", destPath, inFile, append]]) {
            append++;
        }
        movePath = [NSString stringWithFormat:@"%@/%@_%d", destPath, inFile, append];
    }
    
    NSLog(@"moving %@ to %@", fromPath, movePath);
    if(![fileManager moveItemAtPath:fromPath toPath:movePath error:&err]) {
        NSLog(@"error with moving nifti file: %@",err);
    }
    
    //remove any remaining niftis (UNTESTED)
    if ([niftis count] > 1) {
        niftis = [[fileManager contentsOfDirectoryAtPath:dcmPath error:&err] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.nii.gz'"]];
        for (NSString* nii_file in niftis) {
            if(![fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@",dcmPath,nii_file] error:&err]) { NSLog(@"Error removing additional niftis"); }
        }
    }
    //TODO: make this return an array with the names of the .nii.gz files
    return;
}

- (void) coregScript
{
  
    //use system function to call shell script
    NSString *resPath=[NSString stringWithFormat:@"%@",[[NSBundle mainBundle] resourcePath]];
    NSLog(@"resource path is: %@", resPath);
    NSString *execPath = [NSString stringWithFormat:@"source %@/coregister.sh %@ %@",resPath, resPath, destPath];
    NSLog(@"system call: %@",execPath);
    const char* arg = [execPath cStringUsingEncoding:[NSString defaultCStringEncoding]];
    int status = system(arg);
    NSLog(@"System call returned %d", status);
    
    
    /*
    //Using exec doesn't work
    NSString *resPath=[NSString stringWithFormat:@"%@/en.lproj",[[NSBundle mainBundle] resourcePath]];
    NSString *execPath = [NSString stringWithFormat:@"%@/coregister.sh",resPath];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: execPath];
    
    //Placeholder so it can take arguments
    //[task setArguments:[NSArray arrayWithObject:[arr objectAtIndex:0]]];
    
    [task launch];
    [task waitUntilExit];
    return;
    */
    
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
