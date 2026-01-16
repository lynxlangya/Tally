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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appEnvironment, environment)
        }
    }
}
