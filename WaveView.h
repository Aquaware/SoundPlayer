//
//  WaveView.h
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/09/04.
//  Copyright 2011 n/a. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/ExtendedAudioFile.h>

#define SWIPE_SENSITIVITY 12
#define SWIPE_LIMIT_HORIZONTAL 10 


typedef enum {
	SwipeNothing = 0,
	SwipeLeft = 1,
	SwipeRight = 2
} SwipeDirection;

@interface WaveView : UIView {
	CGRect graphRect_;
	float tWidth_;
	UInt64 viewFrameLength_;
	
	float tCenterBand_;
	UInt64 centerBandFrameLength_; 
	
	float upperValue_;
	float lowerValue_;
	
	float sampleRate_;
	UInt64 beginFrame_;
	UInt64 centerBandBeginFrame_;
	UInt64 centerFrame_;
	UInt64 centerBandEndFrame_;
	UInt64 currentFrame_;
	UInt64 endFrame_;

	UInt64 bufferFrameSize_;
	AudioUnitSampleType* buffer_;
	
	NSDate* beginTime_;
	double velocity_;
	double dx_;
	SwipeDirection direction_;
	CGPoint beginPoint_;
	

	CGColorRef bgColor_;
	CGColorRef axisLineColor_;
	CGColorRef plotColor_;
	CGColorRef plotCenterColor_;
	
	id delegate;

}

@property ( assign ) CGRect graphRect_;
@property ( assign ) float tWidth_;
@property ( assign ) float tOffset_;
@property ( assign ) float sampleRate_;
@property ( assign ) UInt64 beginFrame_;
@property ( assign ) UInt64 centerFrame_;
@property ( assign ) UInt64 currentFrame_;
@property ( assign ) UInt64 endFrame_;
@property ( assign ) UInt64 viewFrameLength_;
@property ( assign ) UInt64 bufferFrameSize_;
@property ( assign ) AudioUnitSampleType* buffer_;
@property ( assign ) id delegate;


- ( id ) setupDataSource: ( AudioUnitSampleType* ) data :( UInt64 ) size  :( float ) sampleRate ;
- ( void ) setupGraph:  ( UInt64 ) currentFrame : ( float ) tWidth : ( float ) tCenterBand;
- ( void ) setColorNo: ( int ) no;

@end

// デリゲートメソッド
@interface NSObject ( WaveViewDelegate )
	- ( void ) swipeDetected: ( WaveView* ) controller;
@end
