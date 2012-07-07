//
//  AudioBufferedPlayer.h
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/08/29.
//  Copyright 2011 n/a. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>

#define kChannelSizeMax 2
#define kFrameSizeMax 25000000

@interface LPCMdata : NSObject
{
	UInt32	mChannelSize;
	SInt64	mFrameSize;		// フレーム数
	SInt64	mCurrentFrame;	// カレントフレーム
	Float64	mSamplingRate;	// サンプリングレート
    
	AudioUnitSampleType** mData;	// 波形データバッファ	
}

@property  ( assign ) UInt32 mChannelSize;
@property  ( assign ) SInt64 mFrameSize;
@property  ( assign ) SInt64 mCurrentFrame;
@property  ( assign ) Float64 mSamplingRate;
@property  ( assign ) AudioUnitSampleType** mData;

@end


typedef enum {
	ProcessNormal = 0,
	ProcessVoiceCanceling = 1	
	
} ProcessMode;

typedef enum {
	PlayerStateNothing = 0,
	PlayerStateWavSetted = 1,
	PlayerStatePlay = 2,
	PlayerStatePause = 3,
	PlayerStateStop = 4
	
} PlayerState;

@interface AudioBufferedPlayer : NSObject
{
	id  delegate;	
	LPCMdata* mAudioData;
    AudioBufferList *mAudioBufferList;
	AudioStreamBasicDescription mASBD;
	ExtAudioFileRef	mAudioFileRef;	
	AudioUnit	mAudioUnit;
	float		mVolume;		// 音量	
	BOOL		mLoop;
	BOOL		mReverse;
	UInt64		mLastDisplayFrame;
	ProcessMode mProcessMode;
	PlayerState mPlayerState;
}

@property ( nonatomic, assign ) id  delegate;
@property ( nonatomic, assign ) ProcessMode mProcessMode;
@property ( nonatomic, assign ) PlayerState mPlayerState;
@property ( readonly )  AudioStreamBasicDescription mASBD;
@property ( nonatomic, retain )  LPCMdata* mAudioData;
@property ( readonly )  ExtAudioFileRef	mAudioFileRef;
@property ( readonly )  AudioUnit	mAudioUnit;
@property BOOL		mLoop;
@property BOOL		mReverse;

- ( float ) getEndTime;
-( float ) frameToTime: ( UInt64 ) frame;
-( UInt64 ) timeToFrame: ( float )  time ;

-( void ) play: ( UInt64 ) startFrame;
-( void ) stop;
-( BOOL ) readExtAudioFileToBuffer:( ExtAudioFileRef* ) audioFileRef :( UInt32 ) channelSize :( UInt32 ) frameSize ;
- ( BOOL ) openExtAudioFile: ( ExtAudioFileRef* ) audioFileRef	: ( AudioStreamBasicDescription* ) asbd
						   : (  SInt64* ) frameSize				: ( UInt32* ) channelSize
						   : (   NSURL* ) audioFileUrl			: ( Float64 ) samplingRate;	
- ( BOOL ) setup: ( NSURL* ) soundFileUrl;
- ( BOOL ) setup: ( NSURL* ) soundFileUrl :(Float64)  samplingRate;
- ( void ) sendCurrentFrameUpdate;

- ( ProcessMode ) getProcessMode;
- ( void ) setProcessMode: ( ProcessMode ) mode;
@end

// デリゲートメソッド
@interface NSObject ( AudioBufferedPlayerDelegate )

- (void) currentFrameUpdated : ( AudioBufferedPlayer* ) controller;

@end
