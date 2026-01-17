//
//  JustOneApp.swift
//  JustOne
//
//  Created by 琅邪 on 1/16/26.
//

import SwiftUI

@main
struct JustOneApp: App {
    private let environment = AppEnvironment.live
    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appEnvironment, environment)
        }
    }
}
