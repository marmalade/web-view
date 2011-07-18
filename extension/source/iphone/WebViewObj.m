//
//  WebViewObj.m
//  WebView_iphone
//
//  Created by Bjorn Runaker on 2011-04-14.
//  Copyright 2011 Runåker Produktkonsult AB. All rights reserved.
//
#include "WebView_autodefs.h"
#import "WebViewObj.h"
#include "s3eEdk.h"
#include "s3eEdk_iphone.h"


enum WebViewCallback
{
    WEBVIEW_CALLBACK_PAGE_LOADED,
    WEBVIEW_CALLBACK_PAGE_ERROR,
	WEBVIEW_CALLBACK_LINK,
	WEBVIEW_CALLBACK_KEYBOARD,
    S3E_WEBVIEW_CALLBACK_MAX
};



///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static CGFloat kTransitionDuration = 0.3;


BOOL IsDeviceIPad() {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	}
#endif
	return NO;
}


@implementation WebViewObj

- (BOOL)shouldRotateToOrientation:(UIDeviceOrientation)orientation {
	if (orientation == _orientation) {
		return NO;
	} else {
		return orientation == UIDeviceOrientationLandscapeLeft
		|| orientation == UIDeviceOrientationLandscapeRight
		|| orientation == UIDeviceOrientationPortrait
		|| orientation == UIDeviceOrientationPortraitUpsideDown;
	}
}

- (CGAffineTransform)transformForOrientation {
	UIInterfaceOrientation orientation = newDirection;
	if (orientation == UIDeviceOrientationUnknown)
		orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		return CGAffineTransformMakeRotation(M_PI*1.5);
	} else if (orientation == UIInterfaceOrientationLandscapeRight) {
		return CGAffineTransformMakeRotation(M_PI/2);
	} else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		return CGAffineTransformMakeRotation(-M_PI);
	} else {
		return CGAffineTransformIdentity;
	}
}

- (void)sizeToFitOrientation:(BOOL)transform {
	if (transform) {
		self.transform = CGAffineTransformIdentity;
	}
	
	CGRect frame = [UIScreen mainScreen].applicationFrame;
	CGPoint center = CGPointMake(
								 frame.origin.x + ceil(frame.size.width/2),
								 frame.origin.y + ceil(frame.size.height/2));
	
	CGFloat scale_factor = 1.0f;
	
	CGFloat width = floor(scale_factor * frame.size.width);
	CGFloat height = floor(scale_factor * frame.size.height);
	
	_orientation = newDirection;
	if (_orientation == UIDeviceOrientationUnknown)
		_orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(_orientation)) {
		self.frame = CGRectMake(0, 0, height, width);
	} else {
		self.frame = CGRectMake(0, 0, width, height);
	}
	self.center = center;
	
	if (transform) {
		self.transform = [self transformForOrientation];
	}
}

- (void)updateWebOrientation {
	UIInterfaceOrientation orientation = newDirection;
	if (orientation == UIDeviceOrientationUnknown)
		orientation = [UIApplication sharedApplication].statusBarOrientation;
	[[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
/*	if (UIInterfaceOrientationIsLandscape(orientation)) {
		[_webView stringByEvaluatingJavaScriptFromString:
		 @"document.body.setAttribute('orientation', 90);"];
	} else {
		[_webView stringByEvaluatingJavaScriptFromString:
		 @"document.body.removeAttribute('orientation');"];
	}*/
	
}

- (void)bounce1AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/2];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce2AnimationStopped)];
	self.transform = CGAffineTransformScale([self transformForOrientation], 0.9, 0.9);
	[UIView commitAnimations];
}

- (void)bounce2AnimationStopped {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/2];
	self.transform = [self transformForOrientation];
	[UIView commitAnimations];
}

- (void) orientationAnimationStopped {
	[_webView stringByEvaluatingJavaScriptFromString:@"var e = document.createEvent('Events'); e.initEvent('orientationchange', true, false); document.dispatchEvent(e); "];   
	
}

- (NSURL*)generateURL:(NSString*)baseURL params:(NSDictionary*)params {
	if (params) {
		NSMutableArray* pairs = [NSMutableArray array];
		for (NSString* key in params.keyEnumerator) {
			NSString* value = [params objectForKey:key];
			NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
																						  NULL, /* allocator */
																						  (CFStringRef)value,
																						  NULL, /* charactersToLeaveUnescaped */
																						  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
																						  kCFStringEncodingUTF8);
			
			[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
			[escaped_value release];
		}
		
		NSString* query = [pairs componentsJoinedByString:@"&"];
		NSString* url = [NSString stringWithFormat:@"%@?%@", baseURL, query];
		{
			static char saved_url[4048];
			strncpy(saved_url, [url  UTF8String], 4048);
			saved_url[4047] = 0;
			
			s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_LINK, saved_url, strlen(saved_url) + 1, NULL,S3E_FALSE,NULL,NULL);	
		}		
		
		return [NSURL URLWithString:url];
	} else {
		return [NSURL URLWithString:baseURL];
	}
}


- (void)addObservers {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeObservers {
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)postDismissCleanup {
	[self removeObservers];
	[self removeFromSuperview];
}


- (id)init {
	if (self = [super initWithFrame:CGRectZero]) {
		_loadingURL = nil;
		_orientation = UIDeviceOrientationUnknown;
		newDirection = UIDeviceOrientationUnknown;
		_showingKeyboard = NO;

		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = YES;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.contentMode = UIViewContentModeRedraw;

		_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 480, 480)];
		_webView.delegate = self;
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:_webView];

		_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
					UIActivityIndicatorViewStyleWhiteLarge];
		_spinner.autoresizingMask =
		UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
		| UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:_spinner];
	}
	return self;
}		

- (void)dealloc {
	_webView.delegate = nil;
	[_webView release];
	[_spinner release];
	[_loadingURL release];
	[_params release];
	[_serverURL release];
	[super dealloc];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
	NSURL* url = request.URL;
	
	
	if ([[url scheme] isEqualToString:@"webapp"]) {
		static char saved_url[4048];
		[request.HTTPBody getBytes: saved_url length:4000];
		saved_url[[request.HTTPBody length]] = 0;
		s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_LINK, saved_url, strlen(saved_url) + 1, NULL,S3E_FALSE,NULL,NULL);	
		return NO;
	}
	if ([_loadingURL isEqual:url]) {
		return YES;
	} else if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
		static char saved_url[4048];
		strncpy(saved_url, [[url absoluteString] UTF8String], 4048);
		saved_url[4047] = 0;
		s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_LINK, saved_url, strlen(saved_url) + 1, NULL,S3E_FALSE,NULL,NULL);	
		[_spinner sizeToFit];
		[_spinner startAnimating];
		_spinner.center = _webView.center;
		_spinner.hidden = NO;
		return YES;
	} else {
		 return YES;
	}

}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[_spinner stopAnimating];
	_spinner.hidden = YES;
	
	[self updateWebOrientation];
	
	int status = [[[webView request] valueForHTTPHeaderField:@"Status"] intValue];
    if (status == 404) {
		s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_PAGE_ERROR, NULL, 0, NULL,S3E_FALSE,NULL,NULL);		
    } else {
		s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_PAGE_LOADED, NULL, 0, NULL,S3E_FALSE,NULL,NULL);
	}

	
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSLog (@"webView:didFailLoadWithError");
	s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_PAGE_ERROR, NULL, 0, NULL,S3E_FALSE,NULL,NULL);
	[_spinner stopAnimating];
	_spinner.hidden = YES;

}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIDeviceOrientationDidChangeNotification

- (void)deviceOrientationDidChange:(void*)object {
		
	
	
	UIDeviceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	/*if (!_showingKeyboard && [self shouldRotateToOrientation:orientation])*/ {
		[self updateWebOrientation];
		
		CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:duration];
		[self sizeToFitOrientation:YES];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(orientationAnimationStopped)];
		[UIView commitAnimations];
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// UIKeyboardNotifications

- (void)keyboardWillShow:(NSNotification*)notification {
	
	_showingKeyboard = YES;
	
	s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_KEYBOARD, NULL, 0, NULL,S3E_FALSE,NULL,NULL);

	
	if (IsDeviceIPad()) {
		// On the iPad the screen is large enough that we don't need to
		// resize the dialog to accomodate the keyboard popping up
		return;
	}
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		_webView.frame = CGRectInset(_webView.frame,
									 0,
									 0);
	}
}

- (void)keyboardWillHide:(NSNotification*)notification {
	_showingKeyboard = NO;
	
	if (IsDeviceIPad()) {
		return;
	}
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		_webView.frame = CGRectInset(_webView.frame,
									 0,
									 0);
	}
}

- (id)initWithURL: (NSString *) serverURL
           params: (NSMutableDictionary *) params

{
	
	self = [self init];
	_serverURL = [serverURL retain];
	_params = [params retain];

	return self;
}

- (void)load {
	[self loadURL:_serverURL get:_params];
}

- (void)loadURL:(NSString*)url get:(NSDictionary*)getParams {
	
	[_loadingURL release];
	
	if (![[url substringToIndex:7] isEqual:@"http://"]) {
		url = [NSString stringWithFormat:@"http://%@", url];
	}
	_loadingURL = [[self generateURL:url params:getParams] retain];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_loadingURL];
	
	{
		static char saved_url[]="Before loadRequest";
		s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_LINK, saved_url, strlen(saved_url) + 1, NULL,S3E_FALSE,NULL,NULL);	
	}		
	[_webView loadRequest:request];
	
	[_spinner sizeToFit];
	[_spinner startAnimating];
	_spinner.center = _webView.center;
	
//	[self show];
	{
		static char saved_url[]="after loadRequest";
		s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_LINK, saved_url, strlen(saved_url) + 1, NULL,S3E_FALSE,NULL,NULL);	
	}		
}

- (void) loadFile:(NSString*) filename  {
	[_loadingURL release];
	_loadingURL = [[NSURL fileURLWithPath:filename] retain];
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_loadingURL];

	/*
	cb = _cb;
	if (cb) {
		EDK_CALLBACK_REG(WEBVIEW, WEBVIEW_EVENT, (s3eCallback)cb, NULL, true);

	}
	*/
	
	[_webView loadRequest:request];
	[self show];
}

-(NSString*) evalJS:(NSString*) js {
	
	{
		static char saved_url[4048];
		strncpy(saved_url, [js UTF8String], 4048);
		saved_url[4047] = 0;
		
		s3eEdkCallbacksEnqueue(S3E_EXT_WEBVIEW_HASH, WEBVIEW_CALLBACK_LINK, saved_url, strlen(saved_url) + 1, NULL,S3E_FALSE,NULL,NULL);	
	}		
	
	return [_webView stringByEvaluatingJavaScriptFromString:js];	
}

- (void)show {
	[self sizeToFitOrientation:NO];
		
	_webView.frame = CGRectMake(
								0,
								0,
								self.frame.size.width,
								self.frame.size.height);
	
	[_spinner sizeToFit];
	[_spinner startAnimating];
	_spinner.center = _webView.center;
	
	UIWindow* window = [UIApplication sharedApplication].keyWindow;
	if (!window) {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
	
	
	[window addSubview:self];
	
	
	self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:kTransitionDuration/1.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
	self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
	[UIView commitAnimations];
	self.alpha = 1.0;
	
	[self addObservers];
}

- (void)dismiss {

	[_loadingURL release];
	_loadingURL = nil;
	
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:kTransitionDuration];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(postDismissCleanup)];
		self.alpha = 0;
		[UIView commitAnimations];
}



-(void) chkRotation: (int) direction {
	newDirection = direction;	
	
	
	[self deviceOrientationDidChange: nil];
}




@end
