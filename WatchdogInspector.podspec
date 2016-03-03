Pod::Spec.new do |s|
  s.name     = 'WatchdogInspector'
  s.version  = '0.1.0'
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.summary = 'Shows the current framerate (fps) in the status bar of your iOS app'
  s.description  = 'WatchdogInspector displays the current framerate of your iOS app in the device\'s status bar. Whenever your framerate drops your status bar will get red. If everything is fine your status bar is happy and is green. To detect unwanted main thread stalls you can set a custom watchdog timeout.'
  s.homepage = 'https://github.com/tapwork/WatchdogInspector'
  s.social_media_url = 'https://twitter.com/cmenschel'
  s.authors  = { 'Christian Menschel' => 'christian@tapwork.de' }
  s.source = {
    :git => 'https://github.com/tapwork/WatchdogInspector.git',
    :tag => s.version.to_s
  }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Classes/**.{h,m}'
  s.requires_arc = true
  s.dependency 'YourStatusBar', '~> 1.0.0'
end
