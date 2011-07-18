/*
Internal header for the WebView extension.

This file should be used for any common function definitions etc that need to
be shared between the platform-dependent and platform-indepdendent parts of
this extension.
*/

/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */


#ifndef WEBVIEW_H_INTERNAL
#define WEBVIEW_H_INTERNAL

#include "s3eTypes.h"
#include "WebView.h"
#include "WebView_autodefs.h"


/**
 * Initialise the extension.  This is called once then the extension is first
 * accessed by s3eregister.  If this function returns S3E_RESULT_ERROR the
 * extension will be reported as not-existing on the device.
 */
s3eResult WebViewInit();

/**
 * Platform-specific initialisation, implemented on each platform
 */
s3eResult WebViewInit_platform();

/**
 * Terminate the extension.  This is called once on shutdown, but only if the
 * extension was loader and Init() was successful.
 */
void WebViewTerminate();

/**
 * Platform-specific termination, implemented on each platform
 */
void WebViewTerminate_platform();
WebViewSession* InitWebView_platform();

s3eResult CreateWebView_platform(WebViewSession* session, const char* html);

s3eResult ParamWebView_platform(WebViewSession* session, const char* name, const char* value);

s3eResult ConnectWebView_platform(WebViewSession* session, const char* url);

s3eResult RemoveWebView_platform(WebViewSession* session);

s3eResult TurnWebView_platform(WebViewSession* session, int direction);

const char* EvalJSWebView_platform(WebViewSession* session, const char* js);


#endif /* WEBVIEW_H_INTERNAL */