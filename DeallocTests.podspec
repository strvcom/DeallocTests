Pod::Spec.new do |s|
 s.name = 'DeallocTests'
 s.version = '1.0.3'
 s.license = { :type => "MIT", :file => "LICENSE" }
 s.summary = 'Easy-to-use framework for custom deallocation tests.'
 s.homepage = 'http://strv.com'
 s.social_media_url = 'https://twitter.com/DanielCech'
 s.authors = { "Daniel Cech" => "daniel.cech@strv.com", "Jan Kaltoun" => "jan.kaltoun@strv.com" }
 s.source = { :git => "https://github.com/strvcom/DeallocTests.git", :tag => "v"+s.version.to_s }
 s.platforms = { :ios => "12.0" }
 s.requires_arc = true
 s.swift_versions = ['5.0']

 s.pod_target_xcconfig = {
   'APPLICATION_EXTENSION_API_ONLY' => 'YES',
   'DEFINES_MODULE' => 'YES',
   'ENABLE_BITCODE' => 'NO',
   'OTHER_LDFLAGS' => '$(inherited) -weak-lXCTestSwiftSupport -Xlinker -no_application_extension',
   'OTHER_SWIFT_FLAGS' => '$(inherited) -suppress-warnings',
   'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "$(PLATFORM_DIR)/Developer/Library/Frameworks"',
   "ENABLE_TESTING_SEARCH_PATHS" => "YES", # Required for Xcode 12.5
 }

 s.default_subspec = "SwinjectBased"

 s.subspec "SwinjectBased" do |ss|
     ss.source_files  = "Sources/**/*.swift"
     ss.framework  = "Foundation"
     ss.dependency "Swinject", "~> 2.7.0"
 end

 s.subspec "SwinjectFree" do |ss|
     ss.source_files  = "Sources/**/*.swift"
     ss.framework  = "Foundation"
 end

end
