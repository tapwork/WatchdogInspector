Pod::Spec.new do |s|
  s.name     = 'FramerateInspector'
  s.version  = '0.1.0'
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.summary = ''
  s.description  = ''
  s.homepage = 'https://github.com/tapwork/FramerateInspector'
  s.social_media_url = 'https://twitter.com/cmenschel'
  s.authors  = { 'Christian Menschel' => 'christian@tapwork.de' }
  s.source = {
    :git => 'https://github.com/tapwork/FramerateInspector.git',
    :tag => s.version.to_s
  }
  s.ios.deployment_target = '7.0'
  s.source_files = 'Classes/**.{h,m}'
  s.requires_arc = true
  s.dependency 'YourStatusBar', '~> 1.0.0'
end
