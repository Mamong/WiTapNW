//
//  SceneDelegate.swift
//  WiTapNW
//
//  Created by tryao on 1/16/24.
//

import UIKit
import Network

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    var picker: PickerViewController?

    var tapViewController: TapViewController?

    var server: PeerListener?

    var isServerRegisterred = false
    var isServerStarted = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }

        tapViewController = window?.rootViewController as? TapViewController
        assert(tapViewController != nil)
        tapViewController?.delegate = self

        // Create and advertise our server.  We only want the service to be registered on
        // local networks so we pass in the "local." domain.
        var name = UIDevice.current.name
        // on ios16 you only get "iPhone",so append a random number
        if #available(iOS 16.0, *) {
            name += "-\(Int.random(in: 1...100))"
        }
        let server = PeerListener(name: name, delegate: self)
        self.server = server

        // we should startListening in sceneWillEnterForeground later
        //server.startListening()
        //isServerStarted = true

        // Set up for a new game, which presents a Bonjour browser that displays other
        // available games.
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5){
            self.setupForNewGame()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.

        server?.startListening()
        isServerStarted = true

        if isServerRegisterred {
            startPicker()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // If there's a game playing, shut it down.  Whether this is the right thing to do
        // depends on your app.  In some cases it might be more sensible to leave the connection
        // in place for a short while to see if the user comes back to the app.  This issue is
        // discussed in more depth in Technote 2277 "Networking and Multitasking".
        //
        // <https://developer.apple.com/library/ios/#technotes/tn2277/_index.html>

        if sharedConnection != nil {
            setupForNewGame()
        }

        // Quiesce the server and service browser, if any.
        server?.stopListening()
        isServerStarted = false
        isServerRegisterred = false

        if picker != nil {
            picker?.stop()
        }
    }

    func setupForNewGame(){
        // Reset our tap view state to avoid old taps appearing in the new game.
        tapViewController?.resetTouches()

        // If there's a connection, shut it down.
        // but keep listener working
        sharedConnection?.cancel()
        sharedConnection = nil
        
        // And show the service picker.
        presentPicker()
    }

    func startPicker(){
        picker?.start()
    }

    func presentPicker() {
        if picker != nil {
            // If the picker is already on screen then we're here because of a connection failure.
            // In that case we just cancel the picker's connection UI and the user can choose another
            // service.

            picker?.cancelConnect()

        }else{
            // Create the service picker and put it up on screen.  We only start the picker
            // if our server has completed its registration (the picker needs to know our
            // service name so that it can exclude us from the list).  If that's not the
            // case then the picker remains stopped until -serverDidStart: runs.

            picker = tapViewController?.storyboard?.instantiateViewController(identifier: "picker")
            picker?.localService = server?.service
            picker?.delegate = self
            if isServerRegisterred {
                startPicker()
            }
            tapViewController?.present(picker!, animated: true)
        }
    }

    func dismissPicker(){
        picker?.dismiss(animated: true)
        picker?.stop()
        picker = nil
    }

    func send(message:UInt8){
        guard let sharedConnection else { return }

        sharedConnection.selectCharacter(message)
    }
}

extension SceneDelegate: PickerDelegate {
    func pickerViewController(_ picker: PickerViewController, connectTo service: NWBrowser.Result) {
        sharedConnection = PeerConnection(endpoint: service.endpoint, interface: service.interfaces.first, delegate: self)
        dismissPicker()
    }


    func pickerViewControllerDidCancelConnect(_ picker: PickerViewController) {
        // Called by the picker when the user taps the Cancel button in its
        // connection-in-progress UI.  We respond by closing our in-progress connection.

    }
}

extension SceneDelegate: TapViewControllerDelegate {

    func tapViewController(_ controller: TapViewController, localTouchDownOn item: UInt8) {
        let char:Character = "A"
        send(message: char.asciiValue! + item)
    }

    func tapViewController(_ controller: TapViewController, localTouchUpOn item: UInt8) {
        let char:Character = "a"
        send(message: char.asciiValue! + item)
    }

    func tapViewControllerDidClose(_ controller: TapViewController) {
        setupForNewGame()
    }
}

extension SceneDelegate: PeerConnectionDelegate {
    func serviceDidPublish(){
        // If our server wasn't started when we brought up the picker, we
        // left the picker stopped (because without our service name it can't
        // filter us out of its list).  In that case we have to start the picker
        // now.
        isServerRegisterred = true
        if picker != nil {
            startPicker()
        }
    }

    func connectionReady() {

    }

    func connectionFailed() {

    }

    func connectionAccept(){
        dismissPicker()
    }

    func disconnectByRemote(){
        setupForNewGame()
    }

    func receivedMessage(content: Data?, message: NWProtocolFramer.Message) {
        // We received a remote tap update, forward it to the appropriate view

        let value = Int(content?.first ?? 0)
        let A = Int(("A" as Character).asciiValue!)
        let a = Int(("a" as Character).asciiValue!)

        if case A...A+kTapViewControllerTapItemCount = value {
            tapViewController?.remoteTouchDown(on: value-A)
        } else if case a...a+kTapViewControllerTapItemCount = value {
            tapViewController?.remoteTouchUp(on: value-a)
        } else {
            // Ignore the bogus input.  This is important because it allows us
            // to telnet in to the app in order to test its behaviour.  telnet
            // sends all sorts of odd characters, so ignoring them is a good thing.
        }
    }

    func displayAdvertiseError(_ error: NWError) {
        
    }


}

