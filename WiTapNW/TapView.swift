//
//  TapView.swift
//  WiTapNW
//
//  Created by tryao on 1/16/24.
//

import UIKit

@objc protocol TapViewDelegate: NSObjectProtocol {

    @objc optional func tapViewLocalTouchDown(_ tapView: TapView)

    @objc optional func tapViewLocalTouchUp(_ tapView: TapView)

}

fileprivate let kActivationInset: CGFloat = 10.0

class TapView: UIView {

    private(set) var localTouch = false

    public var remoteTouch = false {
        didSet{
            updateLayerBorder()
        }
    }

    @IBOutlet weak  var delegate: TapViewDelegate?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    func commonInit(){
        assert(!isMultipleTouchEnabled)
        layer.borderColor = UIColor.darkGray.cgColor
    }


    func updateLayerBorder(){
        layer.borderWidth = (localTouch || remoteTouch) ? kActivationInset : 0.0
    }

    public func resetTouches(){
        localTouchUp(notify: false)
        if remoteTouch {
            remoteTouch = false
        }
    }

    // MARK: -Touch tracking
    func localTouchDown() {
        if !localTouch {
            localTouch = true
            updateLayerBorder()

            if let _ = delegate?.responds(to: #selector(TapViewDelegate.tapViewLocalTouchDown(_:))) {
                delegate?.tapViewLocalTouchDown?(self)
            }
        }
    }

    func localTouchUp(notify: Bool) {
        if localTouch {
            localTouch = false
            updateLayerBorder()

            if notify,
               let _ = delegate?.responds(to: #selector(TapViewDelegate.tapViewLocalTouchUp(_:))) {
                delegate?.tapViewLocalTouchUp?(self)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        localTouchDown()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        localTouchUp(notify: true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        localTouchUp(notify: true)
    }
}
