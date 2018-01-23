/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import SnapKit
import pop

class SyncDeviceTypeButton: UIControl {
    
    var imageView: UIImageView = UIImageView()
    var label: UILabel = UILabel()
    var type: DeviceType!
    var pressed: Bool = false {
        didSet {
            if pressed {
                label.textColor = BraveUX.Blue
                if let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY) {
                    anim.toValue = NSValue(cgSize: CGSize(width: 0.9, height: 0.9))
                    layer.pop_add(anim, forKey: "size")
                }
            }
            else {
                label.textColor = BraveUX.GreyJ
                if let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY) {
                    anim.toValue = NSValue(cgSize: CGSize(width: 1.0, height: 1.0))
                    layer.pop_add(anim, forKey: "size")
                }
            }
        }
    }
    
    convenience init(image: String, title: String, type: DeviceType) {
        self.init(frame: CGRect.zero)
        
        clipsToBounds = false
        backgroundColor = UIColor.white
        layer.cornerRadius = 12
        layer.shadowColor = BraveUX.GreyJ.cgColor
        layer.shadowRadius = 3
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 1)
        
        imageView.image = UIImage(named: image)
        imageView.contentMode = .center
        imageView.tintColor = BraveUX.GreyJ
        addSubview(imageView)
        
        label.text = title
        label.font = UIFont.systemFont(ofSize: 17.0, weight: UIFontWeightBold)
        label.textColor = BraveUX.GreyJ
        label.textAlignment = .center
        addSubview(label)
        
        self.type = type
        
        imageView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-20)
        }
        
        label.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.centerX.equalTo(self)
            make.width.equalTo(self)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        pressed = true
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        pressed = false
    }
    
    override func cancelTracking(with event: UIEvent?) {
        pressed = false
    }
}

class SyncAddDeviceTypeViewController: UIViewController {
    
    let loadingView = UIView()
    var scrollView: UIScrollView!
    // TODO: move strings to string file
    var mobileButton: SyncDeviceTypeButton = SyncDeviceTypeButton(image: "sync-mobile", title: "Add a Mobile Device", type: .mobile)
    var computerButton: SyncDeviceTypeButton = SyncDeviceTypeButton(image: "sync-computer", title: "Add a Computer", type: .computer)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Strings.Sync
        view.backgroundColor = SyncBackgroundColor
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        edgesForExtendedLayout = UIRectEdge()
        
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        scrollView.addSubview(mobileButton)
        scrollView.addSubview(computerButton)
        
        mobileButton.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.left.right.equalTo(self.view).inset(15)
            make.height.equalTo(264)
        }
        
        computerButton.snp.makeConstraints { (make) in
            make.top.equalTo(mobileButton.snp.bottom).offset(20)
            make.left.right.equalTo(self.view).inset(15)
            make.height.equalTo(264)
        }
        
        mobileButton.addTarget(self, action: #selector(addDevice), for: .touchUpInside)
        computerButton.addTarget(self, action: #selector(addDevice), for: .touchUpInside)
    
        // Loading View
    
        // This should be general, and abstracted
    
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.startAnimating()
        loadingView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        loadingView.isHidden = true
        loadingView.addSubview(spinner)
        view.addSubview(loadingView)
    
        spinner.snp.makeConstraints { (make) in
            make.center.equalTo(spinner.superview!)
        }
    
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalTo(loadingView.superview!)
        }
    }
    
    func addDevice(sender: SyncDeviceTypeButton) {

        weak var weakSelf = self
        func attemptPush() {
            weakSelf?.attemptPush(title: sender.label.text ?? "", type: sender.type)
        }
        
        if Sync.shared.isInSyncGroup {
            attemptPush()
            return
        }
        
        self.loadingView.isHidden = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: NotificationSyncReady),
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: { _ in attemptPush() })
        
        Sync.shared.initializeNewSyncGroup(deviceName: UIDevice.current.name)
    }
    
    func attemptPush(title: String, type: DeviceType) {
        if navigationController?.topViewController != self {
            // Only perform a movement if something isn't being shown on top of self
            return
        }
        
        if Sync.shared.isInSyncGroup {
            // Setup sync group
            let view = SyncAddDeviceViewController(title: title, type: type)
            view.navigationItem.hidesBackButton = true
            navigationController?.pushViewController(view, animated: true)
        } else {
            self.loadingView.isHidden = true
            let alert = UIAlertController(title: Strings.SyncUnsuccessful, message: Strings.SyncUnableCreateGroup, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.OK, style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
