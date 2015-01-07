Pod::Spec.new do |s|
  s.name             = "XcodeConfiguration"
  s.version          = "2.0.0"
  s.summary          = "A library to manipulate xcconfig files."
  s.homepage         = "https://github.com/PodBuilder/XcodeConfiguration"
  s.license          = 'MIT'
  s.author           = { "William Kent" => "wjk011+pods@gmail.com" }
  s.source           = { :git => "https://github.com/PodBuilder/XcodeConfiguration.git", :tag => s.version.to_s }

  s.source_files = 'Pod/Classes'
  s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'NSString+ShellSplit', '~> 1.0'
  s.requires_arc = true
end
