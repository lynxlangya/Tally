//
//  TallyApp.swift
//  Tally
//
//  Created by 琅邪 on 1/16/26.
//

import SwiftUI

@main
struct TallyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var themeManager = ThemeManager.shared
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
                .applyTheme(settings: themeManager.settings)
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

private extension View {
    @ViewBuilder
    func applyTheme(settings: ThemeSettings) -> some View {
        if let colorScheme = settings.appearance.preferredColorScheme {
            self
                .environment(\.colorScheme, colorScheme)
                .environment(\.tallyThemeColors, TallyThemeColors(accent: settings.accent))
                .preferredColorScheme(colorScheme)
                .tint(settings.accent.color)
                .transaction { transaction in
                    if settings.reduceMotion {
                        transaction.disablesAnimations = true
                        transaction.animation = nil
                    }
                }
        } else {
            self
                .environment(\.tallyThemeColors, TallyThemeColors(accent: settings.accent))
                .preferredColorScheme(nil)
                .tint(settings.accent.color)
                .transaction { transaction in
                    if settings.reduceMotion {
                        transaction.disablesAnimations = true
                        transaction.animation = nil
                    }
                }
        }
    }
}
