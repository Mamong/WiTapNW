//
//  TapViewController.swift
//  WiTapNW
//
//  Created by tryao on 1/16/24.
//

import UIKit

@objc protocol TapViewControllerDelegate:NSObjectProtocol {

    @objc optional func tapViewController(_ controller: TapViewController, localTouchDownOn item: UInt8)

    @objc optional func tapViewController(_ controller: TapViewController, localTouchUpOn item: UInt8)
    
    @objc optional func tapViewControllerDidClose(_ controller: TapViewController)
}

let kTapViewControllerTapItemCount = 9


class TapViewController: UIViewController {

    public weak var delegate:TapViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        for tapViewTag in 1...kTapViewControllerTapItemCount {
            let tapView = view.viewWithTag(tapViewTag)
            assert(tapView is TapView)
            tapView?.backgroundColor = UIColor(hue: CGFloat(Double(tapViewTag)/Double(kTapViewControllerTapItemCount)), saturation: 0.75, brightness: 0.75, alpha: 1.0)
        }
    }

    @IBAction func closeButtonAction(sender: Any){
        if let _ = delegate?.responds(to: #selector(TapViewControllerDelegate.tapViewControllerDidClose(_:))) {
            delegate?.tapViewControllerDidClose?(self)
        }
    }

    func remoteTouchDown(on item: Int) {
        assert(item < kTapViewControllerTapItemCount)
        if isViewLoaded {
            let tapView = view.viewWithTag(item+1) as? TapView
            tapView?.remoteTouch = true
        }
    }

    func remoteTouchUp(on item: Int) {
        assert(item < kTapViewControllerTapItemCount)
        if isViewLoaded {
            let tapView = view.viewWithTag(item+1) as? TapView
            tapView?.remoteTouch = false
        }
    }

    func resetTouches() {
        for tapViewTag in 1...kTapViewControllerTapItemCount {
            let tapView = view.viewWithTag(tapViewTag) as? TapView
            assert(tapView != nil)
            tapView?.resetTouches()
        }
    }
}

extension TapViewController: TapViewDelegate {
    func tapViewLocalTouchDown(_ tapView: TapView) {
        if let _ = delegate?.responds(to: #selector(TapViewControllerDelegate.tapViewController(_:localTouchDownOn:))){
            assert(tapView.tag != 0)
            assert(tapView.tag <= kTapViewControllerTapItemCount);
            delegate?.tapViewController?(self, localTouchDownOn: UInt8(tapView.tag-1))
        }
    }

    func tapViewLocalTouchUp(_ tapView: TapView) {
        if let _ = delegate?.responds(to: #selector(TapViewControllerDelegate.tapViewController(_:localTouchUpOn:))){
            assert(tapView.tag != 0)
            assert(tapView.tag <= kTapViewControllerTapItemCount);
            delegate?.tapViewController?(self, localTouchUpOn: UInt8(tapView.tag-1))
        }
    }
}

