//
//  ScanboardApp.swift
//  Scanboard
//
//  Created by シン・ジャスティン on 2026/03/13.
//

import SwiftUI

@main
struct ScanboardApp: App {

    @State private var showScanner = false

#if DEBUG
    private func loadRocketSimConnect() {
        guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
    }

    init() {
        loadRocketSimConnect()
    }
#endif

    var body: some Scene {
        WindowGroup {
            ContentView(showScanner: $showScanner)
                .onOpenURL { url in
                    if url.scheme == "scanboard" && url.host == "scan" {
                        showScanner = true
                    }
                }
                .task {
                    LiveActivityManager.startActivity()
                }
        }
    }
}
