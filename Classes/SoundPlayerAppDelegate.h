//
//  SoundPlayerAppDelegate.h
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/08/21.
//  Copyright 2011 n/a. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SoundPlayerViewController;

@interface SoundPlayerAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SoundPlayerViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SoundPlayerViewController *viewController;

@end

