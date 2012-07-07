//
//  SoundPlayerViewController.m
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/08/21.
//  Copyright 2011 n/a. All rights reserved.
//

#import "SoundPlayerViewController.h"
#import "AudioDataManager.h"
#import "AudioBufferedPlayer.h"
#import "WaveView.h"
#import "ModeSelectorViewController.h"

@interface SoundPlayerViewController ( private )

- ( void ) import;
@end


@implementation SoundPlayerViewController
@synthesize fileLabel_, song_;
@synthesize audioDataManager_;
@synthesize player_;
@synthesize LchViewWide_, LchViewNarrow_;
@synthesize timeSlider_;
@synthesize modeLabel_;
@synthesize endTimeLabel_;
@synthesize delegate;
@synthesize waitView_, waitIndicator_;
@synthesize modeSelectorView_;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	audioDataManager_ = [ [ AudioDataManager alloc ] init ];
	
	//オーディオセッションを初期化
	//AudioSessionInitialize(NULL, NULL, interruptionListenerCallback, self);
	//オーディオセッションのカテゴリを設定
	UInt32 sessionCategory = kAudioSessionCategory_SoloAmbientSound;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
							sizeof(sessionCategory),
							&sessionCategory);
	//オーディオセッションのアクティブ化
	AudioSessionSetActive(true);
	
	[ LchViewWide_ setColorNo: 0 ];
	//[ LchViewNarrow_ setColorNo: 1 ];
	
	//ツマミの画像
	UIImage *imageForThumb = [UIImage imageNamed:@"slider_knob.png"];

	
	//各画像をセット
	[ timeSlider_ setThumbImage:imageForThumb forState:UIControlStateNormal ];

	
	[ timeSlider_ addTarget: self action:@selector( timeSliderValueChanged: ) 
									forControlEvents: UIControlEventValueChanged ];
	[ timeSlider_ sendActionsForControlEvents: UIControlEventValueChanged ];


	NSNotificationCenter* center = [ NSNotificationCenter defaultCenter ];
	[ center addObserver: self selector:@selector( OnWavSaved: ) name: @"WavSaved" object: nil ];
	[ center addObserver: self selector:@selector( OnFrameUpdated: ) name: @"FrameUpdated" object: nil ];
	player_ = [ [ AudioBufferedPlayer alloc ] init ];
	
	//ウェイトインディケータ
	waitView_ = [[UIView alloc] initWithFrame:self.view.bounds];
	waitView_.backgroundColor = [UIColor blackColor];
	waitView_.alpha = 0.7f;
	
	// インジケータ作成
	waitIndicator_ = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	waitIndicator_.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	[ waitIndicator_ setCenter:CGPointMake( waitView_.bounds.size.width / 2, waitView_.bounds.size.height / 2)];
	
	// ビューに追加
	[ waitView_ addSubview: waitIndicator_ ];
	
	modeSelectorView_ = [ [ ModeSelectorViewController alloc ] init ];
	modeSelectorView_.delegate = self;
	modeLabel_.text = @"Normal";
	
	delegate = self;
}



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[ modeLabel_ release ];
	[ audioDataManager_ release ];
	[ player_ release ];
	[ LchViewWide_ release ];
	[ LchViewNarrow_ release ];	
	[ timeSlider_ release ];
	[ waitIndicator_  release ];
	[ waitView_ release ];
	[ modeSelectorView_ release ];
	
    [super dealloc];
}


- ( void ) timeSliderValueChanged : ( UISlider* ) slider
{

}

- ( IBAction ) sliderAction: ( id ) sender
{
	UInt64 theFrame = [ player_ timeToFrame: timeSlider_.value ];
	
	[ player_ play : theFrame ];	
}


- ( IBAction ) selectAction: ( id ) sender
{
	[ self stopAction: self ];
	// ピッカーを生成
	NSLog(@"iPodライブラリを開く");
	MPMediaPickerController *picker = 
	[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
	
	// デリゲート
	picker.delegate = self;		
	// 複数選択を許可するかどうか？
	picker.allowsPickingMultipleItems = YES;
	// ピッカーのタイトル
	picker.prompt = @"曲追加";
	
	// ピッカーを表示
	[self presentModalViewController:picker animated:YES];
	[picker release];
}

// 曲を選択した時に呼ばれる
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker 
  didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
	
	NSLog(@"曲数:%d" , mediaItemCollection.count );
	NSArray* songs = [  mediaItemCollection items ];
	if( [ songs count ] > 0 )
	{	
		song_ = [ songs objectAtIndex: 0 ];
		[ song_ retain ];
		fileLabel_.text = [ song_ valueForProperty: MPMediaItemPropertyTitle ];
	}
	else{
		fileLabel_.text = @"";
	}
	
	// メディアピッカーを隠す時の処理
	[self dismissModalViewControllerAnimated:YES];
	
	// インジケータ再生
	[ self.view addSubview: waitView_ ];
	[ waitIndicator_ startAnimating ];
	
	// import　MPMediaitem -> Wav file
	//[ audioDataManager_ saveAudioDataToFile: song_ ] ;
	[ audioDataManager_ aquireAudioData2: song_ ];
}

// 曲をキャンセルした時に呼ばれる
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
	
	NSLog(@"キャンセル");
	
	// メディアピッカーを隠す時の処理
	[self dismissModalViewControllerAnimated:YES];
	
	if( !song_ ) return;
}

- ( void ) OnWavSaved: (NSNotification *) notification
{
	NSLog( @"OnWavSaved:" );
	[ waitIndicator_ stopAnimating ];
	[ waitView_ removeFromSuperview ];
}


static void interruptionListenerCallback(void *inUserData, UInt32 interruptionState)
{
	
}

-(void) onTimerGraphDraw:(NSTimer*)timer
{
	UInt64 theFrame = player_.mAudioData.mCurrentFrame;
	if( theFrame > player_.mAudioData.mFrameSize )
	{
		[ timer_ invalidate ];
		timer_ = nil;
		theFrame = player_.mAudioData.mFrameSize -1;
	}	
	
	float time = [ player_ frameToTime: theFrame ];
	[ timeSlider_ setValue: time ];
	[ timeSlider_ setNeedsDisplay ];
	[ LchViewWide_ setupGraph:  theFrame : 5.0 : 0.2 ];
	[ LchViewWide_ setNeedsDisplay ];	
}

- (void) importDid : (SoundPlayerViewController* ) controller
{
	if( timer_ != nil ){
		[ timer_ invalidate ];
		timer_ = nil;
	}
	
	timer_ = [NSTimer scheduledTimerWithTimeInterval: 0.2						//  発生間隔(秒)
											  target: self						//  送信先オブジェクト
											selector: @selector( onTimerGraphDraw: )		//  コールバック関数
											userInfo: nil						//  パラメータ
											 repeats: YES ];  
}

- ( void ) processModeChanged: (ModeSelectorViewController* )  controller
{
	ProcessMode mode = [ modeSelectorView_ getProcessMode ];
	if( mode == ProcessNormal ) modeLabel_.text = @"Normal";
		else if ( mode == ProcessVoiceCanceling )  modeLabel_.text = @"Voice Cancelling";
	[ player_ setProcessMode: mode ];
}

- ( IBAction ) playAction: ( id ) sender
{
	if( audioDataManager_.wavSaveComplete_ == NO ) return;
    
	fileLabel_.text = [ audioDataManager_.wavUrl_ path ];
    
	[ player_ setup: audioDataManager_.wavUrl_ ];
	[ timeSlider_ setMinimumValue: 0 ];
	float endtime = [ player_ getEndTime ];
	endTimeLabel_.text = [ NSString stringWithFormat: @"%.2f", endtime ];
	[ timeSlider_ setMaximumValue: endtime ];
	[ timeSlider_ setValue: 0 ];
    
	int size = player_.mAudioData.mFrameSize;
	[ LchViewWide_ setupDataSource: player_.mAudioData.mData[ 0 ] :size :player_.mAudioData.mSamplingRate ];	
	
	[ delegate importDid: self ];
	[ player_ play : 0 ];
}

- ( IBAction ) stopAction: ( id ) sender
{
	
	[ timer_ invalidate ];	
	timer_ = nil;
	[ player_ stop ];

}



- ( IBAction ) modeSelectAction: ( id ) sender
{
	ProcessMode mode = [ player_ getProcessMode ];
	[ modeSelectorView_ setProcessMode: mode ];
	[self presentModalViewController: modeSelectorView_ animated: YES ];
}

@end
