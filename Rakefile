desc "Bootstraps the repo"
task :bootstrap do
  sh 'bundle'
  sh 'cd SwiftExample && bundle exec pod install'
end

desc "Runs the specs"
task :spec do
  sh("xcodebuild clean test -workspace SwiftExample/SwiftExample.xcworkspace -scheme SwiftExample -destination platform='iOS Simulator',name='iPhone 5s' -sdk iphonesimulator | xcpretty -t -c; exit ${PIPESTATUS[0]}")
end
