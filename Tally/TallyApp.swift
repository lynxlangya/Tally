//
//  TallyApp.swift
//  Tally
//
//  Created by 琅邪 on 1/16/26.
//

import Foundation
import os
import SwiftUI

private let recurringLogger = Logger(subsystem: "com.langya.Tally", category: "recurring")

@main
struct TallyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    @StateObject private var persistenceStartupState: PersistenceStartupState
    @State private var didRunInitialStartupJobs = false
    private let environment: AppEnvironment

    init() {
        let environment = Self.resolvedEnvironment()
        self.environment = environment
        _persistenceStartupState = StateObject(wrappedValue: environment.persistenceController.startupState)
        UITabBar.appearance().isHidden = true
    }

    var body: some Scene {
        WindowGroup {
            startupContent
                .environment(\.appEnvironment, environment)
                .applyTheme(settings: themeManager.settings)
                .environment(\.locale, languageManager.currentLocale)
                .onAppear {
                    runInitialStartupJobsIfReady()
                }
                .onChange(of: persistenceStartupState.status) { _, status in
                    guard status.isReady else { return }
                    runInitialStartupJobsIfReady()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, persistenceStartupState.status.isReady else { return }
            runRecurringCatchUpIfNeeded()
        }
    }

    @ViewBuilder
    private var startupContent: some View {
        switch persistenceStartupState.status {
        case .loading:
            PersistenceStartupStatusView()
        case .ready:
            ContentView()
        case .failed(let issue):
            PersistenceStartupStatusView(issue: issue)
        }
    }

    private func runInitialStartupJobsIfReady() {
        guard persistenceStartupState.status.isReady, !didRunInitialStartupJobs else { return }
        didRunInitialStartupJobs = true
        runRecurringCatchUpIfNeeded()
        WidgetSnapshotService.refresh(using: environment.container.repositories.bill)
    }

    private func runRecurringCatchUpIfNeeded() {
        do {
            let created = try environment.container.services.recurring.runCatchUp(maxDays: 60)
            if created > 0 {
                NotificationCenter.default.post(name: .billDidChange, object: nil)
                WidgetSnapshotService.refresh(using: environment.container.repositories.bill)
            }
        } catch {
            recurringLogger.error("Recurring catch-up failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func resolvedEnvironment() -> AppEnvironment {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-tallyUsePreviewData") {
            return .preview
        }
        #endif
        return .live
    }
}

private struct PersistenceStartupStatusView: View {
    let issue: PersistenceStartupIssue?

    init(issue: PersistenceStartupIssue? = nil) {
        self.issue = issue
    }

    var body: some View {
        ZStack {
            Color.tallyBg.ignoresSafeArea()

            VStack(spacing: TallySpacing.s5) {
                Image(systemName: issue == nil ? "externaldrive" : "externaldrive.badge.exclamationmark")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(issue == nil ? Color.tallyInkDim : Color.red)
                    .frame(width: 72, height: 72)
                    .background(Color.tallySurface)
                    .clipShape(Circle())

                VStack(spacing: TallySpacing.s2) {
                    Text(issue?.title ?? "正在准备账本")
                        .font(TallyType.display(22, weight: .semibold))
                        .foregroundStyle(Color.tallyInk)

                    Text(issue?.message ?? "正在打开本地数据，请稍候。")
                        .font(TallyType.body(15))
                        .foregroundStyle(Color.tallyInkDim)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, TallySpacing.s8)
            .frame(maxWidth: 360)
        }
    }
}

private extension View {
    func applyTheme(settings: ThemeSettings) -> some View {
        modifier(TallyThemeModifier(settings: settings))
    }

    @ViewBuilder
    func applyResolvedTheme(settings: ThemeSettings, reduceMotion: Bool) -> some View {
        if let colorScheme = settings.appearance.preferredColorScheme {
            self
                .environment(\.colorScheme, colorScheme)
                .environment(\.tallyThemeColors, TallyThemeColors(accent: settings.accent))
                .preferredColorScheme(colorScheme)
                .tint(settings.accent.color)
                .transaction { transaction in
                    if reduceMotion {
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
                    if reduceMotion {
                        transaction.disablesAnimations = true
                        transaction.animation = nil
                    }
                }
        }
    }
}

private struct TallyThemeModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    let settings: ThemeSettings

    func body(content: Content) -> some View {
        content.applyResolvedTheme(
            settings: settings,
            reduceMotion: settings.reduceMotion || accessibilityReduceMotion
        )
    }
}
