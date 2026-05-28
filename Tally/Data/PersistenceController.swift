//
//  Persistence.swift
//  Tally
//
//  Created by 琅邪 on 1/16/26.
//

import Combine
import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    private static let storeFileName = "Tally.sqlite"

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true, runsStartupSeed: false)
        let viewContext = result.container.viewContext
        do {
            let seedService = CoreDataSeedService(context: viewContext)
            try seedService.seedIfNeeded()
            try seedService.seedPreviewBill()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer
    let startupState: PersistenceStartupState

    init(
        inMemory: Bool = false,
        startupState: PersistenceStartupState = PersistenceStartupState(),
        runsStartupSeed: Bool = true,
        storeLoader: ((NSPersistentContainer, @escaping (Error?) -> Void) -> Void)? = nil,
        seedRunner: ((NSManagedObjectContext) throws -> Void)? = nil
    ) {
        let container = NSPersistentContainer(name: "Tally")
        var setupIssue: PersistenceStartupIssue?
        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                let storeURL = Self.defaultStoreURL()
                do {
                    try FileManager.default.createDirectory(
                        at: storeURL.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                } catch {
                    setupIssue = PersistenceStartupIssue(
                        phase: .storeDirectory,
                        details: error.localizedDescription
                    )
                }
                description.url = storeURL
            }
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
            description.setOption(
                FileProtectionType.complete as NSObject,
                forKey: NSPersistentStoreFileProtectionKey
            )
        }

        self.container = container
        self.startupState = startupState

        if let setupIssue {
            startupState.markFailed(setupIssue)
            return
        }

        let loadStores = storeLoader ?? { container, completion in
            container.loadPersistentStores { _, error in
                completion(error)
            }
        }
        loadStores(container) { error in
            if let error {
                startupState.markFailed(PersistenceStartupIssue(
                    phase: .storeLoad,
                    details: (error as NSError).localizedDescription
                ))
                return
            }

            guard runsStartupSeed else {
                startupState.markReady()
                return
            }

            let viewContext = container.viewContext
            viewContext.perform {
                do {
                    if let seedRunner {
                        try seedRunner(viewContext)
                    } else {
                        let seedService = CoreDataSeedService(context: viewContext)
                        try seedService.seedIfNeeded()
                        try seedService.migrateLegacyCategoryColors()
                        try seedService.migrateLegacyIconKeys()
                    }
                    startupState.markReady()
                } catch {
                    startupState.markFailed(PersistenceStartupIssue(
                        phase: .seedMigration,
                        details: error.localizedDescription
                    ))
                }
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func defaultStoreURL() -> URL {
        NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent(storeFileName)
    }
}

final class PersistenceStartupState: ObservableObject {
    @Published private(set) var status: PersistenceStartupStatus = .loading

    func markReady() {
        updateStatus(.ready)
    }

    func markFailed(_ issue: PersistenceStartupIssue) {
        updateStatus(.failed(issue))
    }

    private func updateStatus(_ nextStatus: PersistenceStartupStatus) {
        let apply = { [weak self] in
            guard let self else { return }
            if case .failed = self.status {
                return
            }
            self.status = nextStatus
        }

        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.async(execute: apply)
        }
    }
}

enum PersistenceStartupStatus: Equatable {
    case loading
    case ready
    case failed(PersistenceStartupIssue)

    var isReady: Bool {
        if case .ready = self {
            return true
        }
        return false
    }
}

struct PersistenceStartupIssue: Equatable, Identifiable {
    enum Phase: String {
        case storeDirectory
        case storeLoad
        case seedMigration
    }

    let phase: Phase
    let details: String

    var id: String {
        "\(phase.rawValue):\(details)"
    }

    var title: String {
        switch phase {
        case .storeDirectory, .storeLoad:
            return "账本数据暂时无法打开"
        case .seedMigration:
            return "账本数据准备未完成"
        }
    }

    var message: String {
        switch phase {
        case .storeDirectory:
            return "Tally 无法创建本地数据目录。请确认设备存储空间充足，然后完全退出并重新打开 App。"
        case .storeLoad:
            return "Tally 无法读取本地账本。请完全退出并重新打开 App；如果问题持续，请先不要卸载 App，避免丢失本地数据。"
        case .seedMigration:
            return "Tally 无法完成默认分类或数据迁移准备。请完全退出并重新打开 App 后重试。"
        }
    }
}
