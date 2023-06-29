platform :ios, '15.0'

  flutter_application_path = '../vr'
  load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

def share_pods
  use_frameworks!
  
  pod 'Toast-Swift', '~> 5.0.1'
  pod 'Alamofire', '4.9.1'
  pod 'SnapKit', '5.6.0'
  pod 'CocoaLumberjack/Swift'
  pod 'Bugly'
end


target '360CameraTest_Beta' do
  install_all_flutter_pods(flutter_application_path)
  share_pods
end


post_install do |installer|
  flutter_post_install(installer) if defined?(flutter_post_install)
end
