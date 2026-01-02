#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dock_progress.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dock_progress'
  s.version          = '0.0.1'
  s.summary          = 'An API wrapper of DockProgress for Flutter'
  s.description      = <<-DESC
  Interacting with macOS dock icon progress bars in Flutter.
                       DESC
  s.homepage         = 'https://github.com/edex96'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'edex96' => 'edexnorth@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
