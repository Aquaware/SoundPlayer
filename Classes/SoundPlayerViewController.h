//
//  SoundPlayerViewController.h
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/08/21.
//  Copyright 2011 n/a. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class AudioDataManager;
@class AudioBufferedPlayer;
@class WaveView;
@class ImportingAnnouceViewController;
@class ModeSelectorViewController;

@interface SoundPlayerViewController : UIViewController < MPMediaPickerControllerDelegate > {

	id delegate;
	IBOutlet UILabel* modeLabel_;	
	IBOutlet UILabel* fileLabel_;
	IBOutlet UILabel* endTimeLabel_;	
	IBOutlet WaveView* LchViewWide_;
	IBOutlet WaveView* LchViewNarrow_;	
	IBOutlet UISlider* timeSlider_;
	MPMediaItem* song_;
	AudioDataManager* audioDataManager_;
	AudioBufferedPlayer* player_;

	UIView* waitView_;
	UIActivityIndicatorView* waitIndicator_;
	
	NSTimer* timer_;
	int timerFrameCount_;
	
	ModeSelectorViewController* modeSelectorView_;
	
}

@property ( nonatomic, assign ) id delegate;
@property ( nonatomic, retain ) UILabel* modeLabel_;
@property ( nonatomic, retain ) UILabel* endTimeLabel_;
@property ( nonatomic, retain ) UILabel* fileLabel_;
@property ( nonatomic, retain ) UISlider* timeSlider_;
@property ( nonatomic, retain ) WaveView* LchViewWide_;
@property ( nonatomic, retain ) WaveView* LchViewNarrow_;
@property ( nonatomic, retain ) MPMediaItem* song_;
@property ( nonatomic, retain ) AudioDataManager* audioDataManager_;
@property ( nonatomic, retain ) AudioBufferedPlayer* player_;
@property ( nonatomic, retain ) UIView* waitView_;
@property ( nonatomic, retain ) UIActivityIndicatorView* waitIndicator_;
@property ( nonatomic, retain ) ModeSelectorViewController* modeSelectorView_;

- ( IBAction ) selectAction: ( id ) sender;
- ( IBAction ) playAction: ( id ) sender;
- ( IBAction ) stopAction: ( id ) sender;
- ( IBAction ) sliderAction: ( id ) sender;
- ( IBAction ) modeSelectAction: ( id ) sender;
- ( void ) OnWavSaved: (NSNotification *) notification;
- (void) WavSaveComplete: ( AudioDataManager* ) controller;
@end

// デリゲートメソッド
@interface NSObject ( SoundPlayerViewControllerDelegate )

- (void) importDid : (SoundPlayerViewController* ) controller;

@end
