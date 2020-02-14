Pod::Spec.new do |s|
 s.name = 'DeallocTests'
 s.version = '0.0.1'
 s.license = { :type => "MIT", :file => "LICENSE" }
 s.summary = 'Easy-to-use framework for custom deallocation tests.'
 s.homepage = 'http://strv.com'
 s.social_media_url = 'https://twitter.com/DanielCech'
 s.authors = { "Daniel Cech" => "daniel.cech@strv.com" }
 s.source = { :git => "https://github.com/DanielCech/DeallocTests.git", :tag => "v"+s.version.to_s }
 s.platforms = { :ios => "9.0", :osx => "10.10", :tvos => "9.0", :watchos => "2.0" }
 s.requires_arc = true

 s.default_subspec = "Core"
 s.subspec "Core" do |ss|
     ss.source_files  = "Sources/**/*.swift"
     ss.framework  = "Foundation"
 end
end
