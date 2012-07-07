//
//  AudioBufferedPlayer.m
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/08/29.
//  Copyright 2011 n/a. All rights reserved.
//

#import "AudioBufferedPlayer.h"


@implementation  LPCMdata

@synthesize mChannelSize, mFrameSize, mCurrentFrame, mSamplingRate, mData;


@end

// ***** end of LPCMdata *****

@interface  AudioBufferedPlayer ( private )

- ( BOOL ) initAudioUnit : ( UInt32  ) channelSize : ( Float64 ) samplingRate ;
- ( void ) memoryClear;
- ( BOOL ) memoryAlloc;
@end


@implementation AudioBufferedPlayer

@synthesize mASBD, mAudioData, mAudioFileRef, mAudioUnit;
@synthesize	mLoop, mReverse;
@synthesize delegate;
@synthesize mProcessMode;
@synthesize mPlayerState;

// AudioUnit正準形(kAudioFormatFlagsAudioUnitCanonical)
// iPhone OS 2.2 :  8.24固定小数点・非インタリーブ
// iPhone OS 3.0 :  16ビット符号付き整数・インタリーブ
AudioStreamBasicDescription  genASBDforLpcm( Float64 samplingRate,  UInt32 channelSize )
{
	AudioStreamBasicDescription asbd;
	
    asbd.mSampleRate         = samplingRate;
    asbd.mFormatID           = kAudioFormatLinearPCM;
    asbd.mFormatFlags        = kAudioFormatFlagsAudioUnitCanonical;
    asbd.mChannelsPerFrame   = channelSize;
    asbd.mBytesPerPacket     = sizeof(AudioUnitSampleType);
    asbd.mBytesPerFrame      = sizeof(AudioUnitSampleType);
    asbd.mFramesPerPacket    = 1;
    asbd.mBitsPerChannel     = 8 * sizeof(AudioUnitSampleType);
    asbd.mReserved           = 0;
	
	return asbd;
}


// 8.24fix = float * ( 1 << kAudioUnitSampleFractionBits )
// float = 8.24fix / ( 1 << kAudioUnitSampleFractionBits )
AudioUnitSampleType floatToFix( float value )
{
	return value * ( 1 << kAudioUnitSampleFractionBits );
}

AudioUnitSampleType average( AudioUnitSampleType  val1,  AudioUnitSampleType val2 )
{
	float f1 = ( float ) val1 / ( float ) ( 1 << kAudioUnitSampleFractionBits );
	float f2 = ( float ) val2 / ( float ) ( 1 << kAudioUnitSampleFractionBits );
	
	return 	floatToFix(  f1 - f2  );
}

AudioUnitSampleType dif( AudioUnitSampleType  val1,  AudioUnitSampleType val2 )
{
	return 	( AudioUnitSampleType ) (  ( SInt64 ) val1 -  ( SInt64 ) val2  );
}

- ( float ) getEndTime
{
	if( mAudioData.mFrameSize > 0 )
		return [ self frameToTime: mAudioData.mFrameSize ];
	else 
		return 0.0;
}

-( float ) frameToTime: ( UInt64 ) frame
{
	if( mAudioData.mSamplingRate > 0 )  
		return ( float ) frame / mAudioData.mSamplingRate;
	else 
		return 0;
}

- ( UInt64 ) timeToFrame: ( float )  time 
{
	if( mAudioData.mSamplingRate > 0 )  
		return ( int ) ( time *  mAudioData.mSamplingRate );
	else 
		return 0;
}

- ( void ) sendCurrentFrameUpdate
{
	//if ( [ delegate respondsToSelector:@selector( currentFrameUpdated: ) ] )
	//	[ delegate currentFrameUpdated: self ];	
	
	NSNotification* notification = [ NSNotification notificationWithName: @"FrameUpdated" object: self  ];
	[ [ NSNotificationCenter defaultCenter ] postNotification: notification ];	
	
}

static OSStatus callback( void*						inRefCon,
						 AudioUnitRenderActionFlags*	ioActionFlags,
						 const AudioTimeStamp*		inTimeStamp,
						 UInt32						inBusNumber,
						 UInt32						inNumberFrames,
						 AudioBufferList*				ioData )

{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	AudioBufferedPlayer* THIS = ( AudioBufferedPlayer* ) inRefCon;
    
    AudioUnitSampleType *outL = (  AudioUnitSampleType * ) ioData->mBuffers[ 0 ].mData;
    AudioUnitSampleType *outR = (  AudioUnitSampleType * ) ioData->mBuffers[ 1 ].mData;
    
    AudioUnitSampleType **buffer =  ( AudioUnitSampleType ** ) THIS->mAudioData.mData;
    UInt64 currentFrame = THIS->mAudioData.mCurrentFrame;
    SInt64 totalFrames = THIS->mAudioData.mFrameSize;
    UInt32 numberOfChannels = THIS->mAudioData.mChannelSize;
	ProcessMode mode = THIS->mProcessMode;
    
   // NSLog( @"current frame:%llu", currentFrame );
	//NSLog( @"buffer[ 0 ] :%d", ( int ) buffer[ 0 ] );
	//NSLog( @"buffer[ 1 ] :%d", ( int ) buffer[ 1 ] );
	
    for (int i = 0; i < inNumberFrames; i++ ){
		if( THIS->mPlayerState != PlayerStatePlay || ( currentFrame > totalFrames ) ){
            //再生するサンプルが無いので0で埋める
            *outL++ = *outR++ = 0;
        }else{
			//if(currentFrame == totalFrames) currentFrame = 0;
				
			if( numberOfChannels == 2 )
			{ //ステレオの場合
				AudioUnitSampleType lch = buffer[ 0 ][ currentFrame ];
				AudioUnitSampleType rch = buffer[ 1 ][ currentFrame ];
				if( mode == ProcessNormal ){
					*outL++ = lch;
					*outR++ = rch;  	
				}
				else if( mode == ProcessVoiceCanceling ) {
					AudioUnitSampleType d = dif( lch, rch );
					*outL++ = d;
					*outR++ = d;
				}

			}
			else{ //モノラル
				*outL++ = buffer[0][ currentFrame ];
				*outR++ = buffer[0][ currentFrame ];
			}
			
			currentFrame++;
		}
    }
    
    THIS->mAudioData.mCurrentFrame = currentFrame;
	
//	float passingTime = [ THIS frameToTime: currentFrame - THIS->mLastDisplayFrame ];
//	if( passingTime > 1 ){
//		[ THIS sendCurrentFrameUpdate ]; // 100ms経過していたら表示更新
//		THIS->mLastDisplayFrame = currentFrame;
//	}
	
	if( currentFrame > totalFrames ) [ THIS stop ];
	
	[ pool release ];
	
    return noErr;
}

void interruptionListenerCallback(void *inUserData, UInt32 interruptionState)
{
}

- ( ProcessMode ) getProcessMode
{
	return mProcessMode;
}

- ( void ) setProcessMode: ( ProcessMode ) mode
{
	mProcessMode = mode;
}

- ( id ) init
{
	self = [ super init ];
	
	if( self ){
		mAudioData = [ [ LPCMdata alloc ] init ];
	}
	
    
    
    [ self memoryAlloc ];
    
	mProcessMode = ProcessNormal;
	mPlayerState = PlayerStateNothing;
	
	return self;
}

- ( BOOL ) memoryAlloc
{
    //データバッファー領域を確保
	mAudioData.mData = ( AudioUnitSampleType** ) malloc( sizeof( AudioUnitSampleType* ) * kChannelSizeMax );// 1フレーム
	
	//buffer = ( AudioUnitSampleType** ) malloc( channelSize );// 1フレーム
	for( int i = 0; i < kChannelSizeMax; i++ ){
		mAudioData.mData[ i ] = ( AudioUnitSampleType* ) malloc( sizeof( AudioUnitSampleType ) * kFrameSizeMax );
		if( !mAudioData.mData[ i ] ) return NO;
        //mAudioBufferList->mBuffers[ i ].mData = mAudioData.mData[ i ];
	}
    

    
    return YES;
}

- ( void ) memoryClear
{
	for( int i = 0; i < mAudioData.mChannelSize; i++ ){
		free( mAudioData.mData[ i ]  );
        mAudioData.mData[ i ] = nil;
	}
	free( mAudioData.mData );	
    mAudioData.mData = nil;
	[ mAudioData  release ];
	mAudioData = nil;
    
    //free( mAudioBufferList );
    //mAudioBufferList = nil;
}

- ( void ) dealloc
{
	[ self stop ];
	[ self memoryClear ];
	
	AudioUnitUninitialize( mAudioUnit );
    AudioComponentInstanceDispose( mAudioUnit );
	
	[ super dealloc ];
}

- ( BOOL ) setup: ( NSURL* ) soundFileUrl
{
	return [ self setup: soundFileUrl : mAudioData.mSamplingRate  ];
}

- ( BOOL ) setup : ( NSURL* ) soundFileUrl :(Float64)  samplingRate
{
	UInt32 inputChannelSize;
	SInt64 frameSize;
	
	if( mAudioData == nil ) mAudioData = [ [ LPCMdata alloc ] init ];
	
	// 出力パラメータ
	mAudioData.mChannelSize = 2;
	mAudioData.mSamplingRate = 44100.0;
	
	if( ![ self openExtAudioFile: &mAudioFileRef: &mASBD: &frameSize : &inputChannelSize: soundFileUrl: mAudioData.mSamplingRate ] ) return NO;
	if( ![ self readExtAudioFileToBuffer:  &mAudioFileRef: inputChannelSize: frameSize ] ) return NO;
	if( ![ self initAudioUnit:  mAudioData.mChannelSize: mAudioData.mSamplingRate ] ) return NO;
	mAudioData.mCurrentFrame = 0;
	mAudioData.mFrameSize = frameSize;
	
	mPlayerState = PlayerStateWavSetted;
	
	return YES;
}

- ( BOOL ) initAudioUnit : ( UInt32  ) channelSize : ( Float64 ) samplingRate 
{
NSLog( @"initAudiUnit (1) " );		
    AudioComponentDescription cd;
    cd.componentType = kAudioUnitType_Output;
    cd.componentSubType = kAudioUnitSubType_RemoteIO;
    cd.componentManufacturer = kAudioUnitManufacturer_Apple;
    cd.componentFlags = 0;
    cd.componentFlagsMask = 0;
    
    AudioComponent component = AudioComponentFindNext(NULL, &cd);    
    AudioComponentInstanceNew(component, &mAudioUnit);
    AudioUnitInitialize( mAudioUnit );

NSLog( @"initAudiUnit (2) " );	
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = callback;
    callbackStruct.inputProcRefCon = self;
    
    AudioUnitSetProperty( mAudioUnit, 
                         kAudioUnitProperty_SetRenderCallback, 
                         kAudioUnitScope_Input,
                         0,
                         &callbackStruct,
                         sizeof(AURenderCallbackStruct));
    
NSLog( @"initAudiUnit (3) " );	
    AudioStreamBasicDescription audioFormat = genASBDforLpcm( samplingRate, channelSize );   
    AudioUnitSetProperty( mAudioUnit,
						 kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,
                         &audioFormat,
                         sizeof( AudioStreamBasicDescription ) );
NSLog( @"initAudiUnit (4) " );	
	
	return YES;
}

// 正準系、チャンネル数はファイルフォーマットに準ずる、サンプリングレートはsamplingRateとして指定する
//
// (パラメータ)	audioFileUrl:	オーディファイルURL
//				samplingRate:	読み込みサンプリングレート
// (戻り値)		audioFileRef:	オーディオファイルリファレンス
//				asbd:			読み込み用オーディオファイルフォーマット
//				frameSize:		オーディオファイルトータルフレーム数
//				channelSize:	オーディオファイルチャンネル数
- ( BOOL ) openExtAudioFile:
								  ( ExtAudioFileRef* ) audioFileRef
						   : ( AudioStreamBasicDescription* ) asbd
						   :	 (  SInt64* ) frameSize
						   :	  ( UInt32* ) channelSize
								   
						   :	(   NSURL* ) audioFileUrl
						   :	  ( Float64 ) samplingRate
{
	OSStatus err;
	UInt32 size;
	UInt32 nChannels;
	SInt64 nFrames;
	
	// オーディオデータファイルを開く
	err = ExtAudioFileOpenURL( ( CFURLRef ) audioFileUrl, audioFileRef );
	if ( err ) {
		NSLog( @"ExtAudioFileOpenURL failed.(err=%ld)\n", err );
		return false;
	}
	
	//オーディオファイルのデータフォーマットを取得
    AudioStreamBasicDescription inputFormat;
	size = sizeof(AudioStreamBasicDescription);
    err = ExtAudioFileGetProperty( *audioFileRef, 
								  kExtAudioFileProperty_FileDataFormat, 
								  &size,
								  &inputFormat);
	
	// オーディオファイルのチャンネル数
	nChannels = inputFormat.mChannelsPerFrame;
	
	// clientフォーマット ASBDを生成
	AudioStreamBasicDescription clientFormat = genASBDforLpcm( samplingRate, nChannels  );
	
	// AudioFileRefにクライアントフォーマット（読み込みフォーマット）を設定する
	size = sizeof( AudioStreamBasicDescription );
	err = ExtAudioFileSetProperty( *audioFileRef,
								  kExtAudioFileProperty_ClientDataFormat, 
								  size,
								  &clientFormat );
	if(err){
		NSLog( @"kExtAudioFileProperty_ClientDataFormat failed.(err=%ld)\n", err );
		return false;
	}
	
	// 読み込みフレーム数を取得
	size = sizeof(SInt64);
	err = ExtAudioFileGetProperty( *audioFileRef,
								  kExtAudioFileProperty_FileLengthFrames,
								  &size,
								  &nFrames );
	if ( err ) {
		NSLog( @"ExtAudioFileGetProperty failed.(err=%ld)\n", err );
		return NO;
	}
	NSLog( @"Frame Count = %lld\n", nFrames );
    
    if( nChannels > kChannelSizeMax || nFrames > kFrameSizeMax ) {
        UIAlertView* alert = [[ UIAlertView alloc ] initWithTitle: @"Error" 
                                                          message: @"データサイズが大きすぎます"
                                                         delegate: self
                                                cancelButtonTitle: @"OK"
                                                otherButtonTitles: nil,
                              nil ];
        
        [ alert show ];
        [ alert release ];
    }
	
	*channelSize = nChannels;
	*frameSize = nFrames;
	
	return YES;	
}

// バッファに領域を確保し、オーディオデータを読み込む
//
// (パラメータ)	audioFileRef:	オーディファイルリファレンス
//				samplingRate:	読み込みサンプリングレート
//				frameSize:		読み込みフレーム数
//				channelSize:	読み込みチャンネル数
// (戻り値)		buffer:			読み込みデータバッファ
-( BOOL ) readExtAudioFileToBuffer:
									( ExtAudioFileRef* ) audioFileRef
								  : ( UInt32 ) channelSize
								  :	  ( UInt32 ) frameSize 
{
	NSLog( @"readExtAudioFileToBuffer (1) " );
	
    if( channelSize > kChannelSizeMax ) return NO;
    if( frameSize > kFrameSizeMax ) return NO;

	//AudioBufferListの作成
    AudioBufferList* audioBufferList;
	audioBufferList = 
        ( AudioBufferList* ) calloc(  1, sizeof( AudioBufferList  ) + channelSize * sizeof( AudioBuffer ) );

    if( audioBufferList == nil ) return NO;
    audioBufferList->mNumberBuffers = channelSize;
	for( int i = 0; i < channelSize ; i++ )
	{
		audioBufferList->mBuffers[ i ].mNumberChannels = 1;
		audioBufferList->mBuffers[ i ].mDataByteSize = sizeof( AudioUnitSampleType ) * frameSize;
		audioBufferList->mBuffers[ i ].mData = mAudioData.mData[ i ];
	}
	
	NSLog( @"readExtAudioFileToBuffer (4) " );	
	//位置を0に移動
    ExtAudioFileSeek( *audioFileRef, 0 );
	UInt32 readFrameSize = frameSize;
	OSStatus err = ExtAudioFileRead( *audioFileRef, &readFrameSize, audioBufferList );
    
    free( audioBufferList );
    audioBufferList = nil;
    
	if ( err != noErr ) {
		NSLog( @"ExtAudioFileRead() failed. err=%ld\n", err );
		return NO;
	}
    
	//OSStatus err2 = ExtAudioFileDispose( *audioFileRef  );
	//if ( err2 != noErr ) {
	//	NSLog( @"ExtAudioFileDispose failed. err=%ld\n", err );
	//	return NO;
	//}
	
	NSLog( @"readExtAudioFileToBuffer (7) " );		
	return YES;
	
	
CatchError:
	NSLog ( @"Malloc error" );
	return NO;
}

-( void ) play: ( UInt64 ) startFrame
{
NSLog( @"play (1) " );		
	if( startFrame > mAudioData.mFrameSize ) return;

	mAudioData.mCurrentFrame = startFrame;
	mLastDisplayFrame = 0;	// 波形表示更新用
	
	if( mPlayerState == PlayerStatePlay  ) [ self stop ];

	//オーディオセッションを初期化
	AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, self);
	//オーディオセッションのカテゴリを設定
	UInt32 sessionCategory = kAudioSessionCategory_SoloAmbientSound;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
							sizeof(sessionCategory),
							&sessionCategory);
	//オーディオセッションのアクティブ化
	AudioSessionSetActive(true);
	
	AudioOutputUnitStart( mAudioUnit );
	NSLog( @"AudioOutputUnitStart" );	
	
	mPlayerState = PlayerStatePlay;
}

-( void ) stop
{
	if( mPlayerState != PlayerStatePlay  ) return;
	
	AudioOutputUnitStop( mAudioUnit );
	NSLog( @"AudioOutputUnitStop" );
	
	mPlayerState = PlayerStateStop;

}

@end
