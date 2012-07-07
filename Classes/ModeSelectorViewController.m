//
//  ModeSelectorViewController.m
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/09/20.
//  Copyright 2011 n/a. All rights reserved.
//

#import "ModeSelectorViewController.h"


@implementation ModeSelectorViewController
@synthesize picker_;
@synthesize delegate;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	picker_.delegate = self;
    [super viewDidLoad];
}


- (void) pickerView: (UIPickerView*)pView didSelectRow:(NSInteger) row  inComponent:(NSInteger)component
{  
	pickerSelect_ = ( int ) row;
}  

//何列にするか
- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {  
    return 1;  
}  

// 各列あたりのセル数
- (NSInteger) pickerView: (UIPickerView*)pView numberOfRowsInComponent:(NSInteger) component {  
    return 2;  
}  

// 列、セル行のラベル
- (NSString*)pickerView: (UIPickerView*) pView titleForRow:(NSInteger) row forComponent:(NSInteger)component { 
	
	ProcessMode mode = ( ProcessMode ) row;
	
	if( mode == ProcessNormal ) return @"Normal";
	else if ( mode == ProcessVoiceCanceling ) return @"Voice Canceler";
	
	return @"";
}  

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];

}


- (void)dealloc {
	[ picker_ release ];
    [super dealloc];
}

- ( IBAction ) okAction : ( id ) sender
{
	processMode_ = ( ProcessMode ) pickerSelect_;
	if ( [ delegate respondsToSelector:@selector( processModeChanged: ) ] )
		[ delegate processModeChanged: self ];	
	[self dismissModalViewControllerAnimated:YES];
}	
			
- ( IBAction ) cancelAction : ( id ) sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- ( void ) setProcessMode: ( ProcessMode ) mode
{
	processMode_ = mode;
	[ picker_ selectRow: ( int ) mode inComponent: 0 animated:NO ]; 
	
}

- ( ProcessMode ) getProcessMode
{
	return processMode_;
}

@end
