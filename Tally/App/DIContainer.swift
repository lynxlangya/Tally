import CoreData

final class DIContainer {
    struct Repositories {
        let bill: BillRepository
        let category: CategoryRepository
        let recurring: RecurringRepository
        let trash: TrashRepository
        let importWrite: ImportWriteRepository?

        static func live(context: NSManagedObjectContext) -> Repositories {
            Repositories(
                bill: CoreDataBillRepository(context: context),
                category: CoreDataCategoryRepository(context: context),
                recurring: CoreDataRecurringRepository(context: context),
                trash: CoreDataTrashRepository(context: context),
                importWrite: CoreDataImportWriteRepository(context: context)
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

        static func live(context: NSManagedObjectContext, repositories: Repositories) -> Services {
            Services(
                export: StubExportService(),
                importExport: DefaultImportExportService(
                    billRepository: repositories.bill,
                    categoryRepository: repositories.category,
                    recurringRepository: repositories.recurring,
                    importWriteRepository: repositories.importWrite
                ),
                recurring: DefaultRecurringService(
                    recurringRepository: repositories.recurring,
                    billRepository: repositories.bill
                ),
                security: StubSecurityService(),
                seed: CoreDataSeedService(context: context)
            )
        }

        static func mock() -> Services {
            Services(
                export: StubExportService(),
                importExport: StubImportExportService(),
                recurring: StubRecurringService(),
                security: StubSecurityService(),
                seed: StubSeedService()
            )
        }
    }

    let repositories: Repositories
    let services: Services

    init(repositories: Repositories, services: Services = Services.mock()) {
        self.repositories = repositories
        self.services = services
    }

    static func live(persistenceController: PersistenceController) -> DIContainer {
        let context = persistenceController.container.viewContext
        let repos = Repositories.live(context: context)
        return DIContainer(repositories: repos, services: Services.live(context: context, repositories: repos))
    }
}
