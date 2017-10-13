APLPullToRefreshContainer
=========




## Installation
Install via cocoapods by adding this to your Podfile:

	pod "APLPullToRefreshContainer"

## Usage
The APLPullToRefreshViewController is intended to be used as a view controller
that embeds the view controller you want to add a pull to refresh view to.

### Storyboard
Open the Storyboard and create a new View Controller. Set this view controller's
class to _APLPullToRefreshContainerViewController_.

Drag a Container View into this view controller and create an embed segue to your
actual content view controller. Name this segue _aplContent_. You may want to constrain
the Container View to (0, 0, 0, 0) so it fills all available space.

Pro tip: Make sure to set your content view controller's _Adjust Scroll View Insets_
property. We'll make sure all insets work as expected.

### Your Content View Controller

Import header file:

	#import "APLPullToRefreshViewController.h"
	
Your content view controller embeded via the segue named _aplContent_ has to
conform to the _APLPullToRefreshContainerDelegate_ protocol.

* Please provide your content scroll view via _-aplPullToRefreshContentScrollView_. This will most likely be self.scrollView, self.webView.scrollView or self.collectionView.

* Provide your actual Pull to Refresh view via _-aplPullToRefreshPullToRefreshView_. It may optionally conform to the _APLPullToRefreshView_ protocol. __Make sure to set a height constraint for the view you provide or it will have no height.__

* When the user triggers Pull to Refresh, _-aplDidTriggerPullToRefreshCompletion:_ will be called on the main thread. You _must_ call the provided, non-nil completionHandler once your refresh is finished so we can remove the Pull to Refresh view for you and restore the contentInset etc.


### Your Pull To Refresh view

You can provide any view that has a height constraint. It will be added at full width and the height its constraints suggest.

Conforming to the _APLPullToRefreshView_ might turn out to be useful, because:

* Once your pull to refresh view becomes visible, _-aplPullToRefreshProgressUpdate:beyondThreshold:_ gets called on your view any time its visible portion changes. You may find this useful to animate some kind of rotation, color change etc. during the pull process. The parameter's value range is 0...1 to be interpreted as a linear percentage value. The parameter beyondThreshold indicates whether or not releasing the pull to refresh view at this point would trigger the pull to refresh.

* If the user triggered the pull to refresh, _-aplPullToRefreshStartAnimating_ is called. Use this to start an Activity Indicator or such.

* Once the refreshed content is there (and the content view controller calls the completion handler), _-aplPullToRefreshStopAnimating_ is called right before the pull to refresh view is animated away. You can ignore this because you are being animated away soon, anyway, or stop any kind of animation still running.


#### Lifecycle

Once a pan gesture reaches the over-scroll region, a fresh view instance is acquired
from the content view controller and immediately put on display. It is removed if

* the pan gesture stopped and the pull to refresh was not triggered

* or, if the pull to refresh was triggered, once the completionHandler is called and the view is animated away.

It is guaranteed that there is at most one pull to refresh view and one pull to request hanging around. Because we are nice to you, be nice to us and call the provided _completionHandler_ __exactly once__. A useful pattern to call the completionHandler asynchronously could be:

    - (void)aplDidTriggerPullToRefreshCompletion:(APLPullToRefreshCompletionHandler)completionHandler {
        _pendingPullToRefreshCompletionHandler = completionHandler;
        [_webView reload];
    }

    - (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

        if (_pendingPullToRefreshCompletionHandler) {
            _pendingPullToRefreshCompletionHandler();
            _pendingPullToRefreshCompletionHandler = nil;
        }
    }

Calling the completion handler multiple times is undefined behaviour that could lead to threat to life etc.

## Sample code

### Content View Controller

    #import <UIKit/UIKit.h>
    
    @interface WebViewController : UIViewController
    
    @end
    
    #import "APLPullToRefreshContainerViewController.h"
    #import "APLPullToRefreshSampleView.h"
    
    @import WebKit;
    
    @interface WebViewController () <WKNavigationDelegate, APLPullToRefreshContainerDelegate>
    
    @property (nonatomic) WKWebView *webView;
    @property (nonatomic, strong) APLPullToRefreshCompletionHandler pendingPullToRefreshCompletionHandler;
    
    @end
    
    @implementation WebViewController
    
    
    #pragma mark - WKWebView setup
    - (void)viewDidLoad {
        [super viewDidLoad];
    
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
        WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        webView.navigationDelegate = self;
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://heise.de"]]];
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        self.webView = webView;
        
        UIView *view = self.view;
        NSDictionary *views = NSDictionaryOfVariableBindings(webView);
        [view addSubview:webView];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:views]];
        [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:views]];
    }
    
    
    #pragma mark - WKWebView delegate stuff
    - (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    
    
    #pragma mark - APLPushToRefreshContainerDelegate
    - (UIScrollView *)aplPullToRefreshContentScrollView {
        return _webView.scrollView;
    }
    
    - (void)aplDidTriggerPullToRefreshCompletion:(APLPullToRefreshCompletionHandler)completionHandler {
        _pendingPullToRefreshCompletionHandler = completionHandler;
        [_webView reload];
    }
    
    - (UIView *)aplPullToRefreshPullToRefreshView {
        return [APLPullToRefreshSampleView instantiateFromNib];
    }
    
    - (UIColor *)aplPullToRefreshContainerViewBackgroundColor {
        return [UIColor purpleColor];
    }
    
    
    #pragma mark - Pull to refresh action
    - (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
        if (_pendingPullToRefreshCompletionHandler) {
            _pendingPullToRefreshCompletionHandler();
            _pendingPullToRefreshCompletionHandler = nil;
        }
    }
    
    @end
    

### Pull to Refresh view

    #import <UIKit/UIKit.h>
    #import "APLPullToRefreshContainerViewController.h"
    
    @interface APLPullToRefreshSampleView : UIView<APLPullToRefreshView>
    
    @property (weak, nonatomic) IBOutlet UILabel *label;
    
    + (instancetype)instantiateFromNib;
    
    @end
    
    @implementation APLPullToRefreshSampleView
    
    + (instancetype)instantiateFromNib {
        return [[UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil] instantiateWithOwner:nil options:nil][0];
    }
    
    - (void)aplPullToRefreshProgressUpdate:(CGFloat)progress beyondThreshold:(BOOL)beyondThreshold {
        self.label.layer.transform = CATransform3DMakeRotation(M_PI_2 - progress * M_PI_2, 0, 1, 0);
        self.label.text = beyondThreshold ? @"Now release to refresh!" : @"Pull to refresh!";
    }
    
    - (void)aplPullToRefreshStartAnimating {
        self.label.text = @"Loading";
        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * 30];
        rotationAnimation.duration = 30;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = 30;
        
        [self.label.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    }
    
    - (void)aplPullToRefreshStopAnimating {
        self.label.text = @"";
        [self.label.layer removeAnimationForKey:@"rotationAnimation"];
    }
    
    @end