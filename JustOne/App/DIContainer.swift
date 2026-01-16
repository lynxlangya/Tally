import CoreData

final class DIContainer {
    struct Repositories {
        let bill: BillRepository
        let category: CategoryRepository
        let recurring: RecurringRepository
        let trash: TrashRepository

        static func live(context: NSManagedObjectContext) -> Repositories {
            Repositories(
                bill: CoreDataBillRepository(context: context),
                category: CoreDataCategoryRepository(context: context),
                recurring: CoreDataRecurringRepository(context: context),
                trash: CoreDataTrashRepository(context: context)
            )
        }

        static func mock(bill: BillRepository = MockBillRepository()) -> Repositories {
            Repositories(
                bill: bill,
                category: NoopCategoryRepository(),
                recurring: NoopRecurringRepository(),
                trash: NoopTrashRepository()
            )
        }
    }

    struct Services {
        init() {}
    }

    let repositories: Repositories
    let services: Services

    init(repositories: Repositories, services: Services = Services()) {
        self.repositories = repositories
        self.services = services
    }

    static func live(persistenceController: PersistenceController) -> DIContainer {
        let repos = Repositories.live(context: persistenceController.container.viewContext)
        return DIContainer(repositories: repos)
    }
}
