/*
 * iphone-specific implementation of the WebView extension.
 * Add any platform-specific functionality here.
 */
/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */

#include "WebView_internal.h"
#import "WebViewObj.h"
#include "s3eEdk.h"
#include "s3eEdk_iphone.h"


WebViewObj* webview;
NSMutableDictionary* params;

s3eResult WebViewInit_platform()
{

    // Add any platform-specific initialisation code here
    return S3E_RESULT_SUCCESS;
}

void WebViewTerminate_platform()
{
    // Add any platform-specific termination code here
}

WebViewSession* InitWebView_platform()
{
	webview = [[WebViewObj alloc] init];
	params = [[NSMutableDictionary alloc] init];
	
    return (WebViewSession*) webview;
}

s3eResult CreateWebView_platform(WebViewSession* session, const char* file)
{
	if (session != NULL) {
		WebViewObj* _webview = (WebViewObj*) session;
		
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
															 NSUserDomainMask, YES); 
		NSString* documentsDirectory = [paths objectAtIndex:0];     
		NSString* leafname = [[[NSString alloc] initWithUTF8String:file] autorelease]; 
		NSString* filenameStr = [documentsDirectory
								 stringByAppendingPathComponent:leafname];
		
		BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filenameStr];
		
		if (!fileExists) {
			
			NSString* bundlePath = [[NSBundle mainBundle] resourcePath];
			filenameStr = [bundlePath
						   stringByAppendingPathComponent:leafname];
		}
		
		fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filenameStr];
		
		if (!fileExists) 
			return S3E_RESULT_ERROR;
				
		[_webview loadFile:filenameStr]; 
		return S3E_RESULT_SUCCESS;
	}
	
    return S3E_RESULT_ERROR;
}

s3eResult ParamWebView_platform(WebViewSession* session, const char* name, const char* value)
{
	if (session != NULL) {
		[params setObject:[[[NSString alloc] initWithUTF8String:value] autorelease] forKey:[[[NSString alloc] initWithUTF8String:name] autorelease]];
		return S3E_RESULT_SUCCESS;
	}
	return S3E_RESULT_ERROR;
}

s3eResult ConnectWebView_platform(WebViewSession* session, const char* url)
{
	if (session != NULL) {
		WebViewObj* _webview = (WebViewObj*) session;
		[_webview loadURL:[[[NSString alloc] initWithUTF8String:url] autorelease] get:params];
		return S3E_RESULT_SUCCESS;
	}		
	return S3E_RESULT_ERROR;
}

s3eResult RemoveWebView_platform(WebViewSession* session)
{
	if (session != NULL) {
		WebViewObj* _webview = (WebViewObj*) session;
		[_webview dismiss];
		[_webview release];
		return S3E_RESULT_SUCCESS;
	}
	return S3E_RESULT_ERROR;
}

s3eResult TurnWebView_platform(WebViewSession* session, int direction)
{
	if (session != NULL) {
		WebViewObj* _webview = (WebViewObj*) session;
		[_webview chkRotation:direction];
	}
	return S3E_RESULT_ERROR;		
}

const char* EvalJSWebView_platform(WebViewSession* session, const char* js)
{
	NSString* result = nil;
	if (session != NULL) {
		WebViewObj* _webview = (WebViewObj*) session;
		result = [_webview evalJS:[[[NSString alloc] initWithUTF8String:js] autorelease]];
	}		
	if (result) {
		return [result UTF8String];
	} else {
		return NULL;		
	}

}
