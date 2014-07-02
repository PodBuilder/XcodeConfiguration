#
# Be sure to run `pod lib lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "XcodeConfiguration"
  s.version          = "1.0.1"
  s.summary          = "A library to manipulate xcconfig files."
  s.homepage         = "https://github.com/PodBuilder/XcodeConfiguration"
  s.license          = 'MIT'
  s.author           = { "William Kent" => "https://github.com/wjk011" }
  s.source           = { :git => "https://github.com/PodBuilder/XcodeConfiguration.git", :tag => s.version.to_s }

  s.source_files = 'Pod/Classes'
  s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'NSString+ShellSplit', '~> 1.0'
  s.requires_arc = true
end
