Pod::Spec.new do |s|
  s.name     = 'BZGFormViewController'
  s.version  = '2.5.2'
  s.license  = 'MIT'
  s.summary  = 'A library for creating dynamic forms.'
  s.homepage = 'https://github.com/cerupcat/BZGFormViewController'
  s.author   = { 'Ben Guo' => 'benzguo@gmail.com' }
  s.source   = {
    :git => 'https://github.com/cerupcat/BZGFormViewController.git',
    :tag => "v#{s.version}"
  }
  s.dependency 'ReactiveCocoa', '~>2.0'
  s.dependency 'libextobjc', '~>0.4'
  s.dependency 'libPhoneNumber-iOS', '~>0.7.6'
  s.dependency 'JVFloatLabeledTextField', '~>0.0.9'
  s.dependency 'TOMSMorphingLabel', '~> 0.2.3'
  s.requires_arc = true
  s.platform = :ios, '7.0'
  s.source_files = "BZGFormViewController/*.{h,m}", "ZSSRichTextEditor/*.{h,m}"
  s.resources = "**/ZSS*.png", "**/ZSSRichTextEditor.js", "**/editor.html"
  s.frameworks = "CoreGraphics", "CoreText"
end