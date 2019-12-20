#
# Be sure to run `pod lib lint CorePersistence.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CorePersistence'
  s.version          = '1.1.0'
  s.summary          = 'Easy and safe data persistence and parsing'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  'Easy and safe way to parse objects and persist them in CoreData'
  DESC

  s.homepage         = 'https://github.com/SynchronicSolutions/CorePersistence'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'SynchronicSolutions' => 'miloshbabic88@gmail.com' }
  s.source           = { :git => 'https://github.com/SynchronicSolutions/CorePersistence.git', :tag => s.version.to_s }
  s.swift_version    = '5.0'

  s.ios.deployment_target = '10.0'

  s.source_files = 'CorePersistence/Classes/**/*'
end
