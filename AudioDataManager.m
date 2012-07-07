//
//  AudioDataManager.m
//  MusicPlayer
//
//  Created by Ikuo Kudo on 11/08/01.
//  Copyright 2011  All rights reserved.
//

#import "AudioDataManager.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>



//******************************

@implementation AudioDataManager

@synthesize wavUrl_, wavSaveComplete_;
@synthesize delegate;

// type は"mp3", "aac"など
// ファイル名とファイルタイプを指定してリソースよりファイルURLを取得する 
- ( NSURL* ) urlFromResourceFile: ( NSString* ) name Type: ( NSString* ) type
{
	NSString* fromPath = [[NSBundle mainBundle] pathForResource: name ofType: type];
	NSURL* url = [NSURL fileURLWithPath:fromPath];
	
	return url;
}

// ドキュメントディレクトリのファイル名を指定してファイルURLを取得する
- ( NSURL* ) filepathWithFile: ( NSString* ) filename
{
	NSArray* filePaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
	NSString* directory = [filePaths objectAtIndex:0];    
	NSString* path = [ directory stringByAppendingPathComponent: filename ];
	NSURL *url = [NSURL fileURLWithPath: path ];

	return url;
}

//Apple Lossless AudioStreamBasicDescription フォーマットを生成
- ( AudioStreamBasicDescription ) genASBDAppleLossless
{
	//変換するフォーマット(Apple Lossless)
	AudioStreamBasicDescription format;
	memset( &format, 0, sizeof(AudioStreamBasicDescription));
	format.mSampleRate       = 44100.0;
	format.mFormatID         = kAudioFormatAppleLossless;
	format.mChannelsPerFrame = 2;

	UInt32 size = sizeof(AudioStreamBasicDescription);
	AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &format);
	
	return format;
}

- ( id ) init
{
	
	self =  [ super init ];
	
	if( self )
	{
		//NSNotificationCenter* center = [ NSNotificationCenter defaultCenter ];
		//[ center addObserver: self selector:@selector( OnWavSaved: ) name: @"WavSaved" object: nil ];
	}
	
	return self;
}

- ( void ) dealloc
{
	[ [ NSNotificationCenter defaultCenter ] removeObserver:self ];
	
	[ super dealloc ];
}

// iPodライブラリファイルの取り込み　テスト用
- ( BOOL ) aquireAudioData: ( MPMediaItem *) item
{
    NSError *error = nil;
	
	// 読み込みフォーマット
    NSDictionary *audioSetting = [ NSDictionary dictionaryWithObjectsAndKeys:
                                  [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                  [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                                  [ NSNumber numberWithInt: 16], AVLinearPCMBitDepthKey,
                                  [ NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                                  [ NSNumber numberWithBool: NO ], AVLinearPCMIsFloatKey, 
                                  [ NSNumber numberWithBool: 0 ], AVLinearPCMIsBigEndianKey,
                                  [ NSNumber numberWithBool: NO ], AVLinearPCMIsNonInterleaved,
                                  [ NSData data ], AVChannelLayoutKey, nil ];
    
    // AVURLAsset <- MPMediaItem
    NSURL* url = [ item valueForProperty:MPMediaItemPropertyAssetURL ];
    AVURLAsset* URLAsset = [AVURLAsset URLAssetWithURL:url options:nil ];
    if( !URLAsset ) return NO;
    
	// AVAssetReader生成 <- AVURLAsset
    AVAssetReader *assetReader = [ AVAssetReader assetReaderWithAsset: URLAsset error: &error ];
    if( error ) return NO;
    
	// AVAssetReaderAutioMixOutput生成 <- AVURLAsset
    NSArray *tracks = [ URLAsset tracksWithMediaType: AVMediaTypeAudio ];
    if( ![ tracks count ] ) return NO;
    AVAssetReaderAudioMixOutput *audioMixOutput = [AVAssetReaderAudioMixOutput
                                                   assetReaderAudioMixOutputWithAudioTracks: tracks
                                                   audioSettings:audioSetting];
    // AudioMixOutputをReaderに追加
    if (![assetReader canAddOutput: audioMixOutput]) return NO;
    [ assetReader addOutput:audioMixOutput ];
    if (![assetReader startReading]) return NO;
	
	CMSampleBufferRef sampleBuffer = [audioMixOutput copyNextSampleBuffer];
	
	CMBlockBufferRef blockBuffer;
	AudioBufferList audioBufferList;
	
	blockBuffer = CMSampleBufferGetDataBuffer( sampleBuffer );
	
	CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer( sampleBuffer, 
															NULL, 
															&audioBufferList, 
															sizeof(audioBufferList),
															NULL, 
															NULL, 
															0, 
															&blockBuffer);
	
	//
	//    ここでAudioBufferListから読み出す処理など
	NSLog( @"mNumberBuffers: %lu", audioBufferList.mNumberBuffers );
	NSLog( @"mNumberChannels: %lu", audioBufferList.mBuffers[ 0 ].mNumberChannels  );
	NSLog( @"mDataByteSize: %lu", audioBufferList.mBuffers[ 0 ].mDataByteSize );
	SInt16* samples = (SInt16 *) audioBufferList.mBuffers[ 0 ].mData;
	
	for( int i = 0; i < 2000; i++ )
	{	
		NSLog( @"mData[ %i ]: %f", i, ( float ) samples[ i ] / ( float ) ( 1 << kAudioUnitSampleFractionBits ) );
	}
	
	
	
	CFRelease(sampleBuffer);
	CFRelease(blockBuffer);	
	
	return YES;
}


// iPodライブラリファイルの取り込み　テスト用
- ( BOOL ) aquireAudioData2: ( MPMediaItem *) currentSong
{
	
	NSURL *currentSongURL = [currentSong valueForProperty:MPMediaItemPropertyAssetURL];
	AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:currentSongURL options:nil];
	NSError *error = nil;        
	AVAssetReader* reader = [[AVAssetReader alloc] initWithAsset:songAsset error:&error];
	
	AVAssetTrack* track = [[songAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
	
	NSMutableDictionary* audioReadSettings = [NSMutableDictionary dictionary];
	[audioReadSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]
						 forKey:AVFormatIDKey];
	
	AVAssetReaderTrackOutput* readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:audioReadSettings];
	[reader addOutput:readerOutput];
	[reader startReading];
	CMSampleBufferRef sample = [readerOutput copyNextSampleBuffer];
	
	UInt32 acqCount = 0;
    AudioBufferList audioBufferList;
    CMItemCount numSamplesInBuffer;
    CMBlockBufferRef buffer ;
	while( sample != NULL )
	{
		sample = [readerOutput copyNextSampleBuffer];
		
		if( sample == NULL )continue;
		
		buffer = CMSampleBufferGetDataBuffer( sample );
		numSamplesInBuffer = CMSampleBufferGetNumSamples(sample);
		
		
		CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sample,
																NULL,
																&audioBufferList,
																sizeof(audioBufferList),
																NULL,
																NULL,
																kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
																&buffer
																);
		
	/*	for (int bufferCount=0; bufferCount < audioBufferList.mNumberBuffers; bufferCount++)
		{
			SInt16* samples = (SInt16 *)audioBufferList.mBuffers[bufferCount].mData;
			for (int i=0; i < 100 ;  i++)
				NSLog(@"  %i", samples[i]);
        }
	*/	
	
	/*	for( int j = 0; j < audioBufferList.mNumberBuffers; j ++ )
		{	
			SInt16* samples = (SInt16 *)audioBufferList.mBuffers[ j ].mData;
				NSLog(@" acq count: %d   buffer list number: %d  sample size in buffer: %ld  data: %i",
				acqCount, j, numSamplesInBuffer, samples[ 0 ] );
		}
		
		acqCount++;
    */
	}
	
    SInt16* samples = (SInt16 *)audioBufferList.mBuffers[ 0 ].mData;
    for( UInt32 j = 0; j < 2000; j ++ )
    {	
        NSLog(@" %lu:    data: %i", j, samples[ j ] );
    }
    

	
    //Release the buffer when done with the samples 
    //(retained by CMSampleBufferGetAudioBufferListWithRetainedblockBuffer)
    //CFRelease(buffer);             
	
    CFRelease( sample );
	
	return YES;
}	

- ( NSURL* ) saveAudioDataToFile: ( MPMediaItem *)item
{
	NSString* title = [ item valueForProperty: MPMediaItemPropertyTitle ];
	return [ self saveAudioDataToFile: title	mediaItem: item ];
}

// iPodライブラリの音楽ファイルをWavファイルフォーマットに変換して保存する。
// ファイルはドキュメントディレクトリに(title).wavとして保存される。
// 変換は時間がかかるのでスレッド処理
// 
// 　http://objective-audio.jp/ を参照した
- ( NSURL* ) saveAudioDataToFile: ( NSString* ) title mediaItem:(MPMediaItem *)item
{
	wavSaveComplete_ = NO;
	
	if( wavUrl_ )
	{
		[ wavUrl_ release ];
		wavUrl_ = nil;
	}
	
    NSError *error = nil;
	
	// 読み込みフォーマット
    NSDictionary *audioSetting = [ NSDictionary dictionaryWithObjectsAndKeys:
                                  [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                  [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                                  [ NSNumber numberWithInt: 16], AVLinearPCMBitDepthKey,
                                  [ NSNumber numberWithInt: kAudioFormatLinearPCM], AVFormatIDKey,
                                  [ NSNumber numberWithBool: NO ], AVLinearPCMIsFloatKey, 
                                  [ NSNumber numberWithBool: 0 ], AVLinearPCMIsBigEndianKey,
                                  [ NSNumber numberWithBool: NO ], AVLinearPCMIsNonInterleaved,
                                  [ NSData data ], AVChannelLayoutKey, nil ];
    
    // AVURLAsset <- MPMediaItem
    NSURL* url = [ item valueForProperty:MPMediaItemPropertyAssetURL ];
    AVURLAsset* URLAsset = [AVURLAsset URLAssetWithURL:url options:nil ];
    if( !URLAsset ) return nil;
    
	// AVAssetReader生成 <- AVURLAsset
    AVAssetReader *assetReader = [ AVAssetReader assetReaderWithAsset: URLAsset error: &error ];
    if( error ) return nil;
    
	// AVAssetReaderAutioMixOutput生成 <- AVURLAsset
    NSArray *tracks = [ URLAsset tracksWithMediaType: AVMediaTypeAudio ];
    if( ![ tracks count ] ) return NO;
    AVAssetReaderAudioMixOutput *audioMixOutput = [AVAssetReaderAudioMixOutput
                                                   assetReaderAudioMixOutputWithAudioTracks: tracks
                                                   audioSettings:audioSetting];
    // AudioMixOutputをReaderに追加
    if (![assetReader canAddOutput: audioMixOutput]) return nil;
    [ assetReader addOutput:audioMixOutput ];
    if (![assetReader startReading]) return nil;
    
    //出力ファイル名： (曲タイトル).wav
    NSArray* docDirs = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString* dir = [ docDirs objectAtIndex: 0 ];
	NSString* path = [ [ dir stringByAppendingPathComponent: title ] stringByAppendingPathExtension:@"wav" ];
    NSURL* outUrl = [ NSURL fileURLWithPath: path ];	
	//ファイルが存在する場合
	NSNotification* notification1 = [ NSNotification notificationWithName: @"WavSaved" object: self  ];
	if ( [ [ NSFileManager defaultManager ] fileExistsAtPath: path ] ) {
		wavUrl_ = outUrl;
		[ outUrl retain ];
		wavSaveComplete_ = YES;
		[ [ NSNotificationCenter defaultCenter ] postNotification: notification1 ];
		return outUrl;
	}
	
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL: outUrl fileType: AVFileTypeWAVE error: &error];
	
    if( error ) return nil;
    AVAssetWriterInput *assetWriterInput = 
	[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSetting];
    assetWriterInput.expectsMediaDataInRealTime = NO;
    if( ![ assetWriter canAddInput:assetWriterInput ] ) return nil;
    [ assetWriter addInput:assetWriterInput ];
    if( ![ assetWriter startWriting ] ) return nil;
    
    //コピー処理
    [ assetReader retain ];
    [ assetWriter retain ];
    [ assetWriter startSessionAtSourceTime: kCMTimeZero ];
	
	// スレッド処理
    dispatch_queue_t queue = dispatch_queue_create( "assetWriterQueue", NULL );
    [ assetWriterInput requestMediaDataWhenReadyOnQueue:queue usingBlock:^{
        
        NSLog(@"start");
        while (1)
        {
            if( [ assetWriterInput isReadyForMoreMediaData ] )
			{
                CMSampleBufferRef sampleBuffer = [ audioMixOutput copyNextSampleBuffer ];                
                if( sampleBuffer ){
                    [ assetWriterInput appendSampleBuffer:sampleBuffer ];
                    CFRelease( sampleBuffer );
                } else {
                    [ assetWriterInput markAsFinished ];
                    break;
                }
            }
        }
        
        [ assetWriter finishWriting ];
        [ assetReader release ];
        [ assetWriter release ];
        

        NSLog( @"finish" );
		
		wavUrl_ = outUrl;
		[ outUrl retain ];
		
		wavSaveComplete_ = YES;
		
		NSNotification* notification2 = [ NSNotification notificationWithName: @"WavSaved" object: self  ];
		[ [ NSNotificationCenter defaultCenter ] postNotification: notification2 ];
		
    } ];
    
    dispatch_release( queue );
	
	
    return outUrl;
}

// core Audio programmingより
-(void)convertFrom:(NSURL*)fromURL 
             toURL:(NSURL*)toURL 
            format:(AudioStreamBasicDescription)outputFormat
    outputFileType:(AudioFileTypeID)outputFileType
{    
    ExtAudioFileRef inFile,outFile;
    OSStatus err;
    //ExAudioFileの作成
    err = ExtAudioFileOpenURL((CFURLRef)fromURL, &inFile);
    // checkError(err,"ExtAudioFileOpenURL");
    
    //変換対象ファイルのASBDを取得
    AudioStreamBasicDescription inputFormat;
    UInt32 size = sizeof(AudioStreamBasicDescription);
    err = ExtAudioFileGetProperty(inFile,
                                  kExtAudioFileProperty_FileDataFormat, 
                                  &size, 
                                  &inputFormat);
    //checkError(err,"ExtAudioFileSetProperty");
    
    //リニアPCM以外からの変換であれば、リニアPCMとして読み込む
    if(inputFormat.mFormatID != kAudioFormatLinearPCM){
        //一旦変換するフォーマット(リニアPCM Little Endian)
        AudioStreamBasicDescription linearPCMFormat;
        linearPCMFormat.mSampleRate         = outputFormat.mSampleRate;
        linearPCMFormat.mFormatID			= kAudioFormatLinearPCM;
        linearPCMFormat.mFormatFlags		=  kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        linearPCMFormat.mFramesPerPacket	= 1;
        linearPCMFormat.mChannelsPerFrame	= outputFormat.mChannelsPerFrame;
        linearPCMFormat.mBitsPerChannel     = 16;
        linearPCMFormat.mBytesPerPacket     = 2 * outputFormat.mChannelsPerFrame;
        linearPCMFormat.mBytesPerFrame      = 2 * outputFormat.mChannelsPerFrame;
        linearPCMFormat.mReserved			= 0;
        
        //読み出すフォーマットをリニアPCMにする(中間フォーマット)
        inputFormat = linearPCMFormat;
    }
    
    //読み込むフォーマットを設定
    //必ずlinearPCMで読み出される
    err = ExtAudioFileSetProperty(inFile,
                                  kExtAudioFileProperty_ClientDataFormat, 
                                  sizeof(AudioStreamBasicDescription), 
                                  &inputFormat);
    //checkError(err,"ExtAudioFileSetProperty");
    
    err = ExtAudioFileCreateWithURL((CFURLRef)toURL,
                                    outputFileType, //引数で渡されたTypeで作成する
                                    &outputFormat,
                                    NULL, 
                                    kAudioFileFlags_EraseFile, 
                                    &outFile);
    //checkError(err,"ExtAudioFileCreateWithURL");
    
    //書き込むファイルに、"入力"フォーマットを設定。//linearPCMで入力する
    err = ExtAudioFileSetProperty(outFile,
                                  kExtAudioFileProperty_ClientDataFormat, 
                                  sizeof(AudioStreamBasicDescription), 
                                  &inputFormat);
    //checkError(err,"kExtAudioFileProperty_ClientDataFormat");
    
    
    //読み込み位置を0に移動
    err = ExtAudioFileSeek(inFile, 0);
    //checkError(err,"ExtAudioFileSeek");
    
    //一度に読み込むフレーム数
    UInt32 readFrameSize = 1024;
    
    //読み込むバッファ領域を確保
    UInt32 bufferSize = sizeof(char) * readFrameSize * inputFormat.mBytesPerPacket;
    char *buffer =( char* ) malloc(bufferSize);
    
    //AudioBufferListの作成
    AudioBufferList* audioBufferList;
    audioBufferList->mNumberBuffers = 1;
    audioBufferList->mBuffers[0].mNumberChannels = inputFormat.mChannelsPerFrame;
    audioBufferList->mBuffers[0].mDataByteSize = bufferSize;
    audioBufferList->mBuffers[0].mData = buffer;
    
    while(1){
        UInt32 numPacketToRead = readFrameSize;
        err = ExtAudioFileRead(inFile, &numPacketToRead, audioBufferList);
        //checkError(err,"ExtAudioFileRead");
        
        //読み込むフレームが無くなったら終了する
        if(numPacketToRead == 0){
            break;
        }
        err = ExtAudioFileWrite(outFile, 
                                numPacketToRead, 
                                audioBufferList);
        //checkError(err,"ExtAudioFileWrite");
    }
    
    ExtAudioFileDispose(inFile);
    ExtAudioFileDispose(outFile);
    free(buffer);
    buffer = nil;
}





@end
