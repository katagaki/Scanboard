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
