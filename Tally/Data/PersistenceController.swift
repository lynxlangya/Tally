//
//  Persistence.swift
//  Tally
//
//  Created by 琅邪 on 1/16/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    private static let storeFileName = "Tally.sqlite"

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
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

    init(inMemory: Bool = false) {
        let container = NSPersistentContainer(name: "Tally")
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
                    assertionFailure("Failed to create CoreData store directory: \(error)")
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

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                assertionFailure("CoreData store failed to load: \(error), \(error.userInfo)")
                return
            }

            let viewContext = container.viewContext
            viewContext.perform {
                do {
                    let seedService = CoreDataSeedService(context: viewContext)
                    try seedService.seedIfNeeded()
                    try seedService.migrateLegacyCategoryColors()
                } catch {
                    assertionFailure("SeedService failed: \\(error)")
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        self.container = container
    }

    private static func defaultStoreURL() -> URL {
        NSPersistentContainer
            .defaultDirectoryURL()
            .appendingPathComponent(storeFileName)
    }
}
