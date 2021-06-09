Pod::Spec.new do |s|
  s.name         = "YCPhoto"
  s.version      = "1.0.0"
  s.summary      = "图片选择器"
  s.swift_version = "5.0"
  s.description  = <<-DESC
  "自定义图片选择控制器"
                   DESC
  s.homepage = 'ssh://lindc@10.10.2.2:29418/~lindc/HLogin.git'
  s.license      = "MIT"
  s.author       = { "NightDriver" => "lin_de_chun@sina.com" }
  s.source       = { :git => "ssh://lindc@10.10.2.2:29418/~lindc/HLogin.git", :tag => "#{s.version}" }
  s.source_files  = "YCPhoto/*/*.swift", "YCPhoto/*.swift"
  s.resource_bundles = {
    "Localizable" => [""]
  }
  s.resources    = ['YCPhoto/YCPhoto.bundle', 'YCPhoto/*.lproj/*', 'YCPhoto/*.storyboard']
  s.ios.deployment_target = '10.0'
  s.dependency "BaseKitSwift"
  #s.exclude_files = "Classes/Exclude"
end
