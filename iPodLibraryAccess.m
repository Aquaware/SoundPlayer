//
//  iPodLibraryAccess.m
//  MusicPlayer
//
//  Created by KUDO IKUO on 11/07/02.
//  Copyright 2011 n/a. All rights reserved.
//

#import "iPodLibraryAccess.h"


@implementation iPodLibraryAccess
@synthesize songs_, album_, artist_, playList_;

static iPodLibraryAccess*  sharedInstance_ = nil;

+ (iPodLibraryAccess*)share
{
    // インスタンスを作成する
    if ( !sharedInstance_ ) {
        sharedInstance_ = [ [ iPodLibraryAccess alloc ] init ];
    }
    
    return sharedInstance_;
}


- ( void ) getSongs
{
	// 全楽曲のクエリーからコレクションを取得
	MPMediaQuery* query = [ MPMediaQuery songsQuery ];
	NSArray* items = [ query collections ];
	
	// 曲数を取得する
	int size = [ items count ];
		
	// 楽曲情報を格納する配列を生成する
	songs_ = [ [NSMutableArray alloc ] initWithCapacity:size ];
	

	
	
}

- ( void ) getAlbumWithArtworkSize : ( CGSize ) size
{
	// 全アルバムクエリーからコレクションを取得する
	MPMediaQuery* query = [MPMediaQuery albumsQuery];
	NSArray *items = [ query collections];
		
	// アルバムのタイトルとアートワークを取得
	for (MPMediaItemCollection *album in items ) 
	{
		MPMediaItem *albumItem = album.representativeItem;
		if( albumItem == nil ) albumItem = [ album.items objectAtIndex:0 ];
		
		// アルバムのタイトルとアートワークを取得
		MPMediaItemArtwork* artwork = (MPMediaItemArtwork *)[albumItem 
															 valueForProperty:MPMediaItemPropertyArtwork];
		UIImage* img = [artwork imageWithSize: size ];

	}	
	
}


- ( void ) getArtist
{
	MPMediaQuery* query = [ MPMediaQuery artistsQuery ];
	NSArray *items = [ query collections ];
	
}

- ( void ) getPlayList
{
	MPMediaQuery *query = [MPMediaQuery playlistsQuery];
	NSArray *items = [ query collections];


	

	
}

- ( id ) init {
    [ super init ];
	
	NSLog( @">>> Start to get iPod Library" );
	[ self getSongs ];
	[ self getAlbumWithArtworkSize: CGSizeMake( 50,  50 ) ];
	[ self getArtist ];
	[ self getPlayList ];
	NSLog( @"<<< End of iPod Library Acccess" );
	
	return self;
}	

-(void) dealloc
{
	[ songs_ release ];
	[ album_ release ];
	[ artist_ release ];
	[ playList_ release ];
	
	[super dealloc];
}

@end
