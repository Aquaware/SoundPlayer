//
//  AudioDataManager.h
//  MusicPlayer
//
//  Created by Ikuo Kudo on 11/08/01.
//  Copyright 2011  All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioConverter.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import <UIKit/UIKit.h>
#import "SoundPlayerViewController.h"



@interface AudioDataManager : NSObject {

	NSURL* wavUrl_;
	BOOL wavSaveComplete_;
	id  delegate; // Assign
}

@property ( nonatomic, retain ) NSURL* wavUrl_;	
@property ( nonatomic, assign ) BOOL wavSaveComplete_;
@property ( nonatomic, assign ) id delegate;


- ( id ) init;
- ( BOOL ) aquireAudioData: ( MPMediaItem *) item;
- ( BOOL ) aquireAudioData2: ( MPMediaItem *) currentSong;

- ( void ) convertFrom:(NSURL*)fromURL toURL:(NSURL*)toURL 
			format:(AudioStreamBasicDescription)outputFormat 
			outputFileType:(AudioFileTypeID)outputFileType;

- ( AudioStreamBasicDescription ) genASBDAppleLossless;
- ( NSURL* ) urlFromResourceFile: ( NSString* ) name Type: ( NSString* ) type;
- ( NSURL* ) filepathWithFile: ( NSString* ) filename;
- ( NSURL* ) saveAudioDataToFile: ( MPMediaItem *)item;
- ( NSURL* ) saveAudioDataToFile: ( NSString* ) title mediaItem:(MPMediaItem *)item;
- ( void ) OnWavSaved: (NSNotification *)notification;

@end

// デリゲートメソッド
@interface NSObject (AudioDataManagerDelegate)

- (void)WavSaveComplete: ( AudioDataManager* ) controller;

@end
