//
//  iPodLibraryAccess.h
//  MusicPlayer
//
//  Created by KUDO IKUO on 11/07/02.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>


@interface iPodLibraryAccess : NSObject {
	NSMutableArray* songs_;
	NSMutableArray* album_;
	NSMutableArray* artist_;
	NSMutableArray* playList_;
}

@property ( nonatomic, retain ) NSMutableArray* songs_;
@property ( nonatomic, retain ) NSMutableArray* album_;
@property ( nonatomic, retain ) NSMutableArray* artist_;
@property ( nonatomic, retain ) NSMutableArray* playList_;

- ( id ) init;
+ ( iPodLibraryAccess* ) share;
@end
