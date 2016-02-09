desc "Bootstraps the repo"
task :bootstrap do
  sh 'bundle'
  sh 'cd Example && bundle exec pod install'
end

desc "Runs the specs"
task :spec do
  sh 'xcodebuild -workspace Example/TWWatchdogInspector.xcworkspace -scheme \'TWWatchdogInspector\' test -sdk iphonesimulator | xcpretty -tc; exit ${PIPESTATUS[0]}'
end
