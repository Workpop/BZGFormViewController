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
  s.dependency 'libPhoneNumber-iOS', '~>0.8.16'
  s.dependency 'JVFloatLabeledTextField', '~>0.0.9'
  s.dependency 'TOMSMorphingLabel', '~> 0.2.3'
  s.dependency 'BZGMailgunEmailValidation', '~> 1.1.1'
  s.requires_arc = true
  s.platform = :ios, '10.0'
  s.source_files = "BZGFormViewController/*.{h,m}", "BZGFormViewController/ZSSRichTextEditor/*.{h,m}"
  s.resources = "**/ZSS*.png", "**/ZSSRichTextEditor.js", "**/editor.html"
  s.frameworks = "CoreGraphics", "CoreText"
end