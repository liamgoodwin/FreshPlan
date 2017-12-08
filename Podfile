platform :ios, '10.3'
inhibit_all_warnings!
use_frameworks!

target 'FreshPlan' do
  pod 'SnapKit'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'JWTDecode'
  pod 'RxDataSources'
  pod 'RxGesture'
  pod 'Moya/RxSwift'
  pod 'RxOptional'
  pod 'MaterialComponents', '~> 40.1.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['SWIFT_VERSION'] = "4.0"
    end
  end
end
