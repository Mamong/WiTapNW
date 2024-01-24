//
//  PickerViewController.swift
//  WiTapNW
//
//  Created by tryao on 1/16/24.
//

import UIKit
import Network

protocol PickerDelegate: AnyObject {

    func pickerViewController(_ picker:PickerViewController, connectTo service:NWBrowser.Result)

    func pickerViewControllerDidCancelConnect(_ picker:PickerViewController)

}

class PickerViewController: UITableViewController {

    public var type: String?

    public weak var delegate: PickerDelegate?

    public var localService: NWListener.Service? {
        didSet {

            // If there's a local service name label (that is, -viewDidLoad has been called), updated it.

            if localServiceNameLabel != nil{
                setupLocalServiceNameLabel()
            }

            // There's a chance that the browser saw our service before we heard about its successful
            // registration, at which point we need to hide the service.  Doing that would be easy,
            // but there are other edge cases to consider (for example, if the local service changes
            // name, we would have to unhide the old name and hide the new name).  Rather than attempt
            // to handle all of those edge cases we just stop and restart when the service name changes.

            if browser != nil {
                stop()
                start()
            }
        }
    }

    @IBOutlet var localServiceNameLabel: UILabel!

    var localServiceLabelFont: UIFont?

    @IBOutlet var connectView: UIView!

    @IBOutlet var connectLabel: UILabel!

    var services:[NWBrowser.Result] = []

    var browser: PeerBrowser?

    init(){
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit(){
    }

    private func setupLocalServiceNameLabel(){
        assert(localServiceNameLabel != nil)

        if let localService {
            localServiceNameLabel.font = localServiceLabelFont
            localServiceNameLabel.text = localService.name
        } else {
            localServiceNameLabel.font = UIFont.italicSystemFont(ofSize: localServiceLabelFont!.pointSize * 0.75)
            localServiceNameLabel.text = "registering…"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(localServiceNameLabel != nil)
        assert(connectView != nil)
        assert(connectLabel != nil)

        // Stash the original font for use by -setupLocalServiceNameLabel then call
        // -setupLocalServiceNameLabel to apply the local service to our header.
        localServiceLabelFont = localServiceNameLabel.font


        // Set up the connect view and stash the label text for use as a template.
        connectView.layer.cornerRadius = 10.0
        connectView.layer.shadowColor = UIColor.black.cgColor;
        connectView.layer.shadowOffset = CGSizeMake(3.0, 3.0)
        connectView.layer.shadowOpacity = 0.7

        setupLocalServiceNameLabel()
    }

    func start(){
        assert(services.count == 0)
        assert(self.browser == nil)

        let browser = PeerBrowser(delegate: self)
        self.browser = browser

        browser.startBrowsing()
    }

    func stop(){
        browser?.stopBrowsing()
        browser = nil

        services.removeAll()

        tableView.reloadData()
    }

    func cancelConnect(){
        hideConnectViewAndNotify(false)
    }

    private func showConnectViewForService(_ service: NWBrowser.Result){
        assert(connectView.superview == nil)
        assert(connectView != nil)
        assert(connectLabel != nil)

        // Show the connection UI.
        if case let .service(name:name, _, _, _) = service.endpoint {
            connectLabel.text = "Connecting to “\(name)”…"
        }

        let viewBounds = tableView.bounds
        connectView.center = CGPointMake(CGRectGetMidX(viewBounds), CGRectGetMidY(viewBounds))
        tableView .addSubview(connectView)

        // Disable user interactions on the table view to prevent the user doing
        // stuff 'behind' our connection-in-progress UI.
        tableView.isScrollEnabled = false
        tableView.allowsSelection = false

        // Tell the delegate.
        delegate?.pickerViewController(self, connectTo: service)
    }

    private func hideConnectViewAndNotify(_ notify: Bool){

        // Hide the view we showed in -showConnectViewForService:
        if connectView.superview != nil {
            connectView.removeFromSuperview()
            tableView.isScrollEnabled = true
            tableView.allowsSelection = true
        }

        if notify {
            delegate?.pickerViewControllerDidCancelConnect(self)
        }
    }

    @IBAction func connectCancelAction(sender:Any){
        hideConnectViewAndNotify(true)
    }

}

extension PickerViewController: PeerBrowserDelegate {

    func refreshResults(results: Set<NWBrowser.Result>) {
        // exclude local service and sort services by name
        let list = results
            .filter({ result in
                if case let .service(name:name, _, _, _) = result.endpoint{
                    return name != self.localService?.name
                }
                return false
            })
            .sorted { a, b in
                if case let .service(name:aname, _, _, _) = a.endpoint,
                   case let .service(name:bname, _, _, _) = b.endpoint{
                    return aname < bname
                }
                return true
            }
        services.removeAll()
        services.append(contentsOf: list)
        tableView.reloadData()
    }

    func displayBrowseError(_ error: NWError) {

    }
}

extension PickerViewController{
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let service = services[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if case let .service(name:name,_,_,_) = service.endpoint{
            cell.textLabel?.text = name
        }
        return cell
    }
}

extension PickerViewController{

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Find the service associated with the cell and start a connection to that.
        let service = services[indexPath.row]
        showConnectViewForService(service)
    }
}
