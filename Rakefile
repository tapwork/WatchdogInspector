desc "Bootstraps the repo"
task :bootstrap do
  sh 'bundle'
  sh 'cd Example && bundle exec pod install'
end

desc "Runs the specs"
task :spec do
  sh 'xcodebuild test -workspace Example/WatchdogExample.xcworkspace -scheme \'WatchdogExample\' -sdk iphonesimulator -configuration \'Debug\' -destination \'platform=iOS Simulator,name=iPhone 5s\' | xcpretty -tc; exit ${PIPESTATUS[0]}'
end
