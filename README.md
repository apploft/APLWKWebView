APLWKWebView
=============

## Installation

Install via Swift Package manager

## Overview

A simple web view controller based on WKWebView. When you need an in-app browser WKWebView is one option
beside SFSafariViewController. In contrast to the later WKWebView gives you some more flexibility and control but 
is more cumbersome to setup. This is where APLWKWebViewController comes into play. It gets you up and running 
quickly. The APLWKWebViewController has features like a loading progress view and easy way to show a toolbar with
basic navigation elements like back and forward buttons and a refresh button. All using the stand system symbols.
Furthermore you can setup a delegate receiving all 'WKNavigationDelegate' and 'WKUIDelegate' delegates. 

## Usage

Below is a simple example of how to use the APLWKWebViewController. For more information please consult the header
or module description.

```
import UIKit
import APLWKWebView

class ViewController: APLWKWebViewController, APLWKWebViewDelegate {

    override func viewDidLoad() {
        aplWebViewDelegate = self

        // If your a self implementing the 'aplWebViewDelegate' be sure to set
        // yourself as delegate before calling super.
        super.viewDidLoad()

        usesContentPageTitle = true
        load(URLRequest(url: URL(string: "https://www.apploft.de")!))
    }

    func showToolbar(_ webViewController: APLWKWebViewController, withSuggestedControlItems suggestedToolbarItems: [UIBarButtonItem]) -> [UIBarButtonItem]? {
        return suggestedToolbarItems
    }
}

```

Enjoy.
