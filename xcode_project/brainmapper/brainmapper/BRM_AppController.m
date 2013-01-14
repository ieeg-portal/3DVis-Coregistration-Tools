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
    NSString *resPath=[[NSBundle mainBundle] resourcePath];
    NSLog(@"resource path is: %@", resPath);
    //NSString *subPath = [[NSBundle mainBundle] pathForResource:@"dcm2nii" ofType:@"" inDirectory:@"Resources"];
    //NSString *subPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:(@"dcm2nii")];
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
        [textField setStringValue: @"Creating 3D model from DICOMS..."];
        [processInd startAnimation:self];
        [self stackDicomArray:(mriArray) forFile:@"mri"];
        [self stackDicomArray:(ctArray) forFile:@"ct"];
        [textField setStringValue:@"Coregistering..."];
        [self coregScript];
        //TODO NEXT: GET OLD SHELL SCRIPT TO RUN ON STACKED IMAGES (will have to add executables)
    }
    [textField setHidden:NO];
    [processInd setHidden:NO];
}

- (void) stackDicomArray:(NSMutableArray*) arr
                 forFile:(NSString*) inFile
{
    NSString *resPath=[[NSBundle mainBundle] resourcePath];
    NSString *execPath = [NSString stringWithFormat:@"%@/dcm2nii",resPath];
    
    //make a directory for inputs/outputs
    BOOL isDir = FALSE;
    NSError *err;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSString *dirPath = [@"~/Desktop/Coregister" stringByExpandingTildeInPath];
    BOOL fileExists = [fileManager fileExistsAtPath:dirPath isDirectory:&isDir];
    if (!isDir || !fileExists) {
        NSLog(@"creating Coregister directory");
        if(![fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&err]) {
            NSLog(@"Error: Create input/output folder failed");
        }
    }
    
    //stack the dicoms
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: execPath];
    [task setArguments:[NSArray arrayWithObject:[arr objectAtIndex:0]]];
    [task launch];
    [task waitUntilExit];
    
    //copy the new nifti into the directory
    NSString *dcmPath = [[arr objectAtIndex:0] stringByDeletingLastPathComponent];
    NSArray *niftis = [[fileManager contentsOfDirectoryAtPath:dcmPath error:&err]filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.nii.gz'"]];
    NSString *nifti;
    //UNTESTED: make sure this works
    if ([niftis count] == 3) {
        nifti = [[niftis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self STARTSWITH 'co'"]] objectAtIndex:0];
    } else if ([niftis count] == 2) {
        nifti = [[niftis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self STARTSWITH 'o'"]] objectAtIndex:0];
    } else if ([niftis count] == 1) {
        nifti = [niftis objectAtIndex:0];
    } else {
        NSLog(@"error: incorrect number of nifti files");
    }
    NSString *movePath = [NSString stringWithFormat:@"%@/%@.nii.gz",dirPath,inFile];
    NSString *fromPath = [NSString stringWithFormat:@"%@/%@",dcmPath,nifti];
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
    return;
}

- (void) coregScript
{
    NSString *resPath=[[NSBundle mainBundle] resourcePath];
    NSString *execPath = [NSString stringWithFormat:@"%@/coregister.sh",resPath];
    
    //UNCOMMENT THE TWO LINES BELOW
    //NSTask *task = [[NSTask alloc] init];
    //[task setLaunchPath: execPath];
    
    
    //I MIGHT WANT TO HOOK UP SOME PIPES SO I CAN WRITE TO A LOG FILE
    //NSPipe *pipe = [NSPipe pipe];
    //[task setStandardOutput:pipe];
    //NSFileHandle *file = [pipe fileHandleForReading];
    
    
   
    // RIGHT NOW IT DOESN'T TAKE ARGUMENTS, BUT I'LL PROBABLY HAVE TO PASS IN THE ROOT PATH
    //[task setArguments:[NSArray arrayWithObject:[arr objectAtIndex:0]]];
    
    //ALSO UNCOMMENT THESE
    //[task launch];
    //[task waitUntilExit];
    return;
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
