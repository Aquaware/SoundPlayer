//
//  ModeSelectorViewController.h
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/09/20.
//  Copyright 2011 n/a. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioBufferedPlayer.h"


@interface ModeSelectorViewController : UIViewController <UIPickerViewDelegate> {

	IBOutlet UIPickerView* picker_;
	int pickerSelect_;
	ProcessMode processMode_;
	id delegate;
}

@property ( nonatomic, retain ) IBOutlet UIPickerView* picker_;
@property ( nonatomic, assign ) ProcessMode processMode_;
@property ( nonatomic, assign ) id delegate;

- ( IBAction ) okAction : ( id ) sender;
- ( IBAction ) cancelAction : ( id ) sender;

- ( void ) setProcessMode: ( ProcessMode ) mode;
- ( ProcessMode ) getProcessMode;
@end

// デリゲートメソッド
@interface NSObject (  ModeSelectorViewControllerDelegate )
- ( void ) processModeChanged: (ModeSelectorViewController* ) controller;
@end