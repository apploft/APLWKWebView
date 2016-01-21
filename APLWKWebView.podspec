Pod::Spec.new do |s|
  s.name         = "APLWKWebView"
  s.version      = "0.0.1"
  s.summary      = "APLWKWebViewController contains a WKWebView, a Pull to Refresh control and a loading indicator"

  s.description  = <<-DESC
		This is a Pull to Refresh Control where a more verbose description will follow.
                   DESC

  s.homepage     = "https://bitbucket.org/lb-lab/aplwkwebview"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  
  s.author       = 'Nico Schuemann'

  s.platform     = :ios, '5.0'

  s.source       = { :git => "git@bitbucket.org:lb-lab/aplwkwebview.git", :tag => s.version.to_s }

  s.source_files  = 'APLWKWebView', 'APLWKWebView/**/*.{h,m}'
  s.exclude_files = 'APLWKWebView/Exclude'

  s.requires_arc = true

  s.dependency = 'APLPullToRefreshContainer', '~> 0.0.2'

end
