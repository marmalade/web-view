//
//  WebViewObj.h
//  WebView_iphone
//
//  Created by Bjorn Runaker on 2011-04-14.
//  Copyright 2011 Runåker Produktkonsult AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface WebViewObj : UIView <UIWebViewDelegate> {
	NSURL* _loadingURL;
	NSMutableDictionary *_params;
	NSString * _serverURL;

	UIWebView* _webView;
	UIActivityIndicatorView* _spinner;
	UIDeviceOrientation _orientation, newDirection;
	BOOL _showingKeyboard;

//	WebViewCallbackFn cb;
}


- (id)initWithURL: (NSString *) serverURL
           params: (NSMutableDictionary *) params;
/**
 * Displays the view with an animation.
 *
 * The view will be added to the top of the current key window.
 */
- (void)show;

- (void)loadURL:(NSString*)url get:(NSDictionary*)getParams;
- (void) loadFile:(NSString*) filename;
-(NSString*) evalJS:(NSString*) js ;
- (void)dismiss;
-(void) chkRotation: (int) direction;


@end
