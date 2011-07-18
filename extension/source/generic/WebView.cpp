/*
Generic implementation of the WebView extension.
This file should perform any platform-indepedentent functionality
(e.g. error checking) before calling platform-dependent implementations.
*/

/*
 * NOTE: This file was originally written by the extension builder, but will not
 * be overwritten (unless --force is specified) and is intended to be modified.
 */


#include "WebView_internal.h"
s3eResult WebViewInit()
{
    //Add any generic initialisation code here
    return WebViewInit_platform();
}

void WebViewTerminate()
{
    //Add any generic termination code here
    WebViewTerminate_platform();
}

WebViewSession* InitWebView()
{
	return InitWebView_platform();
}

s3eResult CreateWebView(WebViewSession* session, const char* html)
{
	return CreateWebView_platform(session, html);
}

s3eResult ParamWebView(WebViewSession* session,const char* name, const char* value)
{
	return ParamWebView_platform(session, name, value);
}

s3eResult ConnectWebView(WebViewSession* session, const char* url)
{
	return ConnectWebView_platform(session, url);
}

s3eResult RemoveWebView(WebViewSession* session)
{
	return RemoveWebView_platform(session);
}

s3eResult TurnWebView(WebViewSession* session, int direction)
{
	return TurnWebView_platform(session, direction);
}

const char* EvalJSWebView(WebViewSession* session, const char* js)
{
	return EvalJSWebView_platform(session, js);
}
