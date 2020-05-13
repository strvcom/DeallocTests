Pod::Spec.new do |s|
 s.name = 'DeallocTests'
 s.version = '0.0.4'
 s.license = { :type => "MIT", :file => "LICENSE" }
 s.summary = 'Easy-to-use framework for custom deallocation tests.'
 s.homepage = 'http://strv.com'
 s.social_media_url = 'https://twitter.com/DanielCech'
 s.authors = { "Daniel Cech" => "daniel.cech@strv.com", "Jan Kaltoun" => "jan.kaltoun@strv.com" }
 s.source = { :git => "git@github.com:strvcom/ios-research-dealloc-tests.git", :tag => "v"+s.version.to_s }
 s.platforms = { :ios => "12.0" }
 s.requires_arc = true
 s.swift_versions = ['5.0']
 s.dependency "Swinject", "~> 2.7.0"

 s.pod_target_xcconfig = {
   'APPLICATION_EXTENSION_API_ONLY' => 'YES',
   'DEFINES_MODULE' => 'YES',
   'ENABLE_BITCODE' => 'NO',
   'OTHER_LDFLAGS' => '$(inherited) -weak-lswiftXCTest -Xlinker -no_application_extension',
   'OTHER_SWIFT_FLAGS' => '$(inherited) -suppress-warnings',
   'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(PLATFORM_DIR)/Developer/Library/Frameworks"',
 }

 s.default_subspec = "Core"
 s.subspec "Core" do |ss|
     ss.source_files  = "Sources/**/*.swift"
     ss.framework  = "Foundation"
 end
end
