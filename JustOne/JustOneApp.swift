//
//  JustOneApp.swift
//  JustOne
//
//  Created by 琅邪 on 1/16/26.
//

import SwiftUI

@main
struct JustOneApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let environment = AppEnvironment.live

    init() {
        UITabBar.appearance().isHidden = true
        runRecurringCatchUpIfNeeded()
        WidgetSnapshotService.refresh(using: environment.container.repositories.bill)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appEnvironment, environment)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            runRecurringCatchUpIfNeeded()
        }
    }

    private func runRecurringCatchUpIfNeeded() {
        do {
            let created = try environment.container.services.recurring.runCatchUp(maxDays: 60)
            if created > 0 {
                NotificationCenter.default.post(name: .billDidChange, object: nil)
                WidgetSnapshotService.refresh(using: environment.container.repositories.bill)
            }
        } catch {
            // Keep startup resilient even if recurring catch-up fails.
        }
    }
}
