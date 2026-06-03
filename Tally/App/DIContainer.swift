import CoreData

final class DIContainer {
    struct Repositories {
        let bill: BillRepository
        let category: CategoryRepository
        let recurring: RecurringRepository
        let trash: TrashRepository
        let importWrite: ImportWriteRepository?

        static func live(container: NSPersistentContainer) -> Repositories {
            let context = container.viewContext
            return Repositories(
                bill: CoreDataBillRepository(context: context),
                category: CoreDataCategoryRepository(context: context),
                recurring: CoreDataRecurringRepository(context: context),
                trash: CoreDataTrashRepository(context: context),
                importWrite: CoreDataImportWriteRepository(container: container)
            )
        }

        static func mock(bill: BillRepository = MockBillRepository()) -> Repositories {
            Repositories(
                bill: bill,
                category: NoopCategoryRepository(),
                recurring: NoopRecurringRepository(),
                trash: NoopTrashRepository(),
                importWrite: nil
            )
        }
    }

    struct Services {
        let export: ExportService
        let importExport: ImportExportService
        let recurring: RecurringService
        let security: SecurityService
        let seed: SeedService
        let categorySuggestion: CategorySuggestionService

        static func live(container: NSPersistentContainer, repositories: Repositories) -> Services {
            let recurringContext = container.newBackgroundContext()
            recurringContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            return Services(
                export: StubExportService(),
                importExport: DefaultImportExportService(
                    billRepository: repositories.bill,
                    categoryRepository: repositories.category,
                    recurringRepository: repositories.recurring,
                    importWriteRepository: repositories.importWrite
                ),
                recurring: DefaultRecurringService(
                    recurringRepository: CoreDataRecurringRepository(context: recurringContext),
                    billRepository: CoreDataBillRepository(context: recurringContext)
                ),
                security: StubSecurityService(),
                seed: CoreDataSeedService(context: container.viewContext),
                categorySuggestion: DefaultCategorySuggestionService(billRepository: repositories.bill)
            )
        }

        static func mock() -> Services {
            Services(
                export: StubExportService(),
                importExport: StubImportExportService(),
                recurring: StubRecurringService(),
                security: StubSecurityService(),
                seed: StubSeedService(),
                categorySuggestion: StubCategorySuggestionService()
            )
        }
    }

    let repositories: Repositories
    let services: Services

    init(repositories: Repositories, services: Services) {
        self.repositories = repositories
        self.services = services
    }

    static func live(persistenceController: PersistenceController) -> DIContainer {
        let repos = Repositories.live(container: persistenceController.container)
        return DIContainer(
            repositories: repos,
            services: Services.live(container: persistenceController.container, repositories: repos)
        )
    }
}
