//
//  WaveView.m
//  SoundPlayer
//
//  Created by KUDO IKUO on 11/09/04.
//  Copyright 2011 n/a. All rights reserved.
//

#import "WaveView.h"



@implementation WaveView

@synthesize graphRect_, tWidth_, tOffset_, sampleRate_;
@synthesize beginFrame_, centerFrame_, currentFrame_, endFrame_, viewFrameLength_;
@synthesize bufferFrameSize_;
@synthesize buffer_;
@synthesize delegate;


// 8.24fix = float * ( 1 << kAudioUnitSampleFractionBits )
// float = 8.24fix / ( 1 << kAudioUnitSampleFractionBits )
float fixToFloat( AudioUnitSampleType  fix824 )
{
	float f = ( float ) fix824 / ( float ) ( 1 << kAudioUnitSampleFractionBits );
	
	return 	f;
}

- ( CGPoint ) transPoint : ( UInt64 ) frame :  ( float ) value
{
	
	CGPoint center = CGPointMake(graphRect_.origin.x + graphRect_.size.width / 2,
								 graphRect_.origin.y + graphRect_.size.height / 2 );
	
	// frame
	float graphWidth = ( float ) graphRect_.size.width / 2.0;
	float x = center.x + graphWidth * ( ( float )frame - ( float )centerFrame_ ) / ( float ) viewFrameLength_;
	
	float graphHeight =  ( float ) graphRect_.size.height / 2.0;
	float y = center.y -  graphHeight * value / upperValue_;
	
	
	CGPoint p = CGPointMake( x, y );
	
	return p;
}




- ( CGColorRef ) CGColorRefWith: ( float ) red  : ( float ) green : ( float ) blue : ( float ) a
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();	
	CGFloat rgba[] = { red, green, blue, a };	
	CGColorRef color = CGColorCreate( colorSpace, rgba );	
	
	return color;
}

- ( void ) setColorNo: ( int ) no
{
	
	switch( no ){
		case 0: 
			bgColor_ = [ self CGColorRefWith: 0.0 : 0.0 : 0.0 : 1.0 ]; 
			axisLineColor_ = [ self CGColorRefWith: 0.0 : 0.4 : 0.4 :1.0 ];
			plotColor_ = [ self CGColorRefWith: 0.0 : 0.0 : 1.0 : 1.0 ];
			plotCenterColor_ = [ self CGColorRefWith: 0.4 : 0.4 : 1.0 : 1.0 ];			
		break;
			
		case 1:
			bgColor_ = [ self CGColorRefWith: 0.4 : 0.4 : 0.5 : 1.0 ]; 
			axisLineColor_ = [ self CGColorRefWith: 0.0 : 0.4 : 0.4 :1.0 ];
			plotColor_ = [ self CGColorRefWith: 1.0 : 0.6 : 0.6 : 1.0 ];
			plotCenterColor_ = [ self CGColorRefWith: 1.0 : 0.6 : 0.6 : 1.0 ];			
		break;
	}			
			

}

- ( id ) setupDataSource: ( AudioUnitSampleType* ) data :( UInt64 ) size  :( float ) sampleRate 
{
	buffer_ = ( SInt32* ) data;
	bufferFrameSize_ = size;
	
	float upperMargin = 1;
	float lowerMargin = 1;
	float leftMargin = 1;
	float rightMargin = 1;
	
	graphRect_ = CGRectMake( leftMargin, upperMargin,
							self.frame.size.width - leftMargin - rightMargin,
							self.frame.size.height - upperMargin - lowerMargin );
	
	
	sampleRate_ = sampleRate;
	
	
/*	AudioUnitSampleType* p = data;
	double min, max, mean;
	mean = 0;
	for( UInt64 i = 0; i < size; i++ )
	{
		AudioUnitSampleType d = *p++;
		float data = fixToFloat( d );
		if( i == 0 )
		{
			min = max = data;
			mean += data;
		}
		else{
			if( data < min ) min = data;
			if( data > max ) max = data;
			mean += data;
		}
	}
	
	if( size > 0 ) mean /= ( float ) size;
	NSLog( @"size:%d   Max: %.5f   Min: %.5f   Mean: %.5f", size, max, min, mean );
	
*/	
	return self;
}


// twidth: 表示する時間幅（センターより片側）
// tCenterBand: 中心付近で色を変える時間幅（センターより片側）
- ( void ) setupGraph:  ( UInt64 ) currentFrame : ( float ) tWidth : ( float ) tCenterBand 
{

	tWidth_ = tWidth;
	viewFrameLength_ = ( int ) ( sampleRate_ * tWidth );		//	表示する時間幅
	
	if( tCenterBand > tWidth ) tCenterBand = 0.0;
	tCenterBand_ = tCenterBand;
	centerBandFrameLength_ =  ( int ) ( sampleRate_ * tCenterBand );		//	色を変えて表示する時間幅
	
	// scanするフレーム
	centerFrame_ = currentFrame;
	if( centerFrame_ < viewFrameLength_ )
		beginFrame_ = 0;
	else 
		beginFrame_ = centerFrame_ - viewFrameLength_;
	
	endFrame_ = centerFrame_ + viewFrameLength_;
	if( endFrame_ > bufferFrameSize_ ) endFrame_ = bufferFrameSize_ - 1;
	
	if( centerFrame_ < centerBandFrameLength_ )
		centerBandBeginFrame_ = 0;
	else 
		centerBandBeginFrame_ = centerFrame_ - centerBandFrameLength_;
	

	centerBandEndFrame_ = centerFrame_ + centerBandFrameLength_;
	if( centerBandEndFrame_ > bufferFrameSize_ ) centerBandEndFrame_ = bufferFrameSize_ - 1;
	
	
	// 縦軸
	float limit = 0.8f;
	upperValue_ = limit;
	lowerValue_ = -limit;
}



- (void)dealloc {
	
	CGColorRelease( bgColor_ );
	CGColorRelease( axisLineColor_ );
	CGColorRelease( plotColor_ );
	CGColorRelease( plotCenterColor_ );	
	
    [super dealloc];
}


- (void)drawRect:(CGRect)rect {
	
	if( ( endFrame_ - beginFrame_ ) <= 0 ) return;
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor( context,  bgColor_);
	CGContextFillRect( context, rect );

	// draw X axis
	//CGFloat lineDash[] = { 6.0f, 6.0f };
			
	//CGContextSetLineDash( context, 0.0f, lineDash, 2 );
	CGContextSetLineWidth( context, 1.0f );

	float y = graphRect_.origin.y;
	
	//線の色
	CGContextSetStrokeColorWithColor( context, axisLineColor_ );
	// x axis
	for( int i = 0; i < 5; i++ )
	{
		CGPoint startPoint	= CGPointMake( graphRect_.origin.x, y );
		CGPoint endPoint	= CGPointMake( graphRect_.origin.x + graphRect_.size.width - 1,  y );
		CGContextMoveToPoint( context, startPoint.x, startPoint.y );
		CGContextAddLineToPoint( context, endPoint.x, endPoint.y );
		CGContextClosePath( context );
		CGContextStrokePath( context );
		y += graphRect_.size.height / 4;
	}
		
	// y axis
	float x = graphRect_.origin.x;
	for( int i = 0; i < 5; i++ )
	{
		CGPoint startPoint	= CGPointMake( x, graphRect_.origin.y );
		CGPoint endPoint	= CGPointMake( x, graphRect_.origin.y + graphRect_.size.height - 1 );
		CGContextMoveToPoint( context, startPoint.x, startPoint.y );
		CGContextAddLineToPoint( context, endPoint.x, endPoint.y );
		CGContextClosePath( context );
		CGContextStrokePath( context );
		x += graphRect_.size.width / 4;
	}
	
	
	CGPoint p0;
	CGPoint p1;
	AudioUnitSampleType* d = buffer_;
	
	float r = ( ( float ) viewFrameLength_ ) / ( ( float ) graphRect_.size.width / 2.0 );
	
	UInt64 delta =  1 +  ( int ) (  r  ); 
	
	CGContextSetLineWidth( context, 1.5f );
	for( UInt64 i = beginFrame_; i < centerBandBeginFrame_; i += delta )
	{
		if( i == beginFrame_ ) 
		{ 
			 AudioUnitSampleType fix = d[ i ];
			float value = fixToFloat( fix );
			p0 = [ self transPoint: i  :  value ];			
			continue;
		}
		else p1 = [ self transPoint: i  : fixToFloat( d[ i ] ) ];
		
		CGContextMoveToPoint( context, p0.x, p0.y );
		CGContextAddLineToPoint( context, p1.x, p1.y );
		CGContextClosePath( context );
			
		CGContextSetStrokeColorWithColor( context, plotColor_);
		CGContextStrokePath( context );
			
		p0 = p1;

	}
	
	for( UInt64 i = centerBandBeginFrame_; i < centerBandEndFrame_; i += delta )
	{

		if( i == beginFrame_ ) 
		{ 
			AudioUnitSampleType fix = d[ i ];
			float value = fixToFloat( fix );
			p0 = [ self transPoint: i  :  value ];			
			continue;
		}
		else p1 = [ self transPoint: i  : fixToFloat( d[ i ] ) ];
		
		CGContextMoveToPoint( context, p0.x, p0.y );
		CGContextAddLineToPoint( context, p1.x, p1.y );
		CGContextClosePath( context );
		
		CGContextSetStrokeColorWithColor( context, plotCenterColor_ );
		CGContextStrokePath( context );
		
		p0 = p1;

	}
	
	
	for( UInt64 i = centerBandEndFrame_; i < endFrame_; i += delta )
	{
		if( i == beginFrame_ ) 
		{ 
			AudioUnitSampleType fix = d[ i ];
			float value = fixToFloat( fix );
			p0 = [ self transPoint: i  :  value ];			
			continue;
		}
		else p1 = [ self transPoint: i  : fixToFloat( d[ i ] ) ];
		
		CGContextMoveToPoint( context, p0.x, p0.y );
		CGContextAddLineToPoint( context, p1.x, p1.y );
		CGContextClosePath( context );
		
		CGContextSetStrokeColorWithColor( context, plotColor_ );
		CGContextStrokePath( context );
		
		p0 = p1;

	}	
	
}

- (void)reloadData {
	
	[self setNeedsDisplay];
}



// タッチ開始
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	beginPoint_ = [ [ touches anyObject ] locationInView: self ];	
	beginTime_ = [ [ NSDate date ] retain ];	
	direction_ = SwipeNothing;
	velocity_ = 0.0;
	dx_ = 0.0;
}

// 移動
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint current  = [ [ touches anyObject ] locationInView: self ];	
	
	// 水平のスワイプを検出
	if( fabsf( beginPoint_.x - current.x ) >= SWIPE_SENSITIVITY &&
	    fabsf( beginPoint_.y - current.y ) <= SWIPE_LIMIT_HORIZONTAL ){
		if( beginPoint_.x < current.x )
			direction_ = SwipeLeft;
		else
			direction_ = SwipeRight;
		
	}
}

// タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint current = [ [ touches anyObject ] locationInView: self ];	
	
	if( direction_ == SwipeNothing ) return;
	
	// スワイプの速度を検出
	NSTimeInterval dt = - [ beginTime_ timeIntervalSinceNow ];
	dx_ = fabsf( beginPoint_.x - current.x );
	velocity_ = dx_ / dt;		
	NSLog( @"dir:%d, dx:%f, dt:%f, speed:%f", direction_, dx_, dt, velocity_);	
	
	if ( [ delegate respondsToSelector: @selector( swipeDetected: ) ] )
											[ delegate swipeDetected: self ];	
}





@end
