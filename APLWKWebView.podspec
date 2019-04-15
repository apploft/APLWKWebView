Pod::Spec.new do |s|
  s.name         = "APLWKWebView"
  s.version      = "1.0.2"
  s.summary      = "APLWKWebViewController contains a WKWebView, a Pull to Refresh control and a loading indicator"

  s.description  = <<-DESC
		APLWKWebViewController contains a WKWebView, a Pull to Refresh control and a loading indicator.
                Use it if you want to provide web view content to your users with some convenience functionality.
                   DESC

  s.homepage     = "https://github.com/apploft/APLWKWebView"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  
  s.author       = 'Nico Schuemann'

  s.platform     = :ios, '10.0'

  s.source       = { :git => "https://github.com/apploft/APLWKWebView.git", :tag => s.version.to_s }

  s.source_files  = 'APLWKWebView', 'APLWKWebView/**/*.{h,m}'
  s.exclude_files = 'APLWKWebView/Exclude'

  s.requires_arc = true

  s.dependency 'APLPullToRefreshContainer', '~> 1.0.0'

end
