import CoreData

struct CoreDataSeedService: SeedService {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    private struct SeedCategory {
        let id: UUID
        let type: BillType
        let name: String
        let iconKey: String
        let colorHex: Int
        let isSystem: Bool
        let sortOrder: Int
    }

    private let categories: [SeedCategory] = [
        SeedCategory(id: SystemCategoryID.uncategorizedExpense, type: .expense, name: "未分类", iconKey: "questionmark", colorHex: 0x13EC37, isSystem: true, sortOrder: 0),
        SeedCategory(id: SystemCategoryID.uncategorizedIncome, type: .income, name: "未分类", iconKey: "questionmark", colorHex: 0x13EC37, isSystem: true, sortOrder: 0),

        // Expense presets (30)
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, type: .expense, name: "餐饮", iconKey: "fork.knife", colorHex: 0xF97316, isSystem: false, sortOrder: 1),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, type: .expense, name: "交通", iconKey: "bus", colorHex: 0x3B82F6, isSystem: false, sortOrder: 2),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, type: .expense, name: "购物", iconKey: "cart.fill", colorHex: 0x13EC37, isSystem: false, sortOrder: 3),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, type: .expense, name: "日用", iconKey: "basket.fill", colorHex: 0x22C55E, isSystem: false, sortOrder: 4),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, type: .expense, name: "房租", iconKey: "house.fill", colorHex: 0x6366F1, isSystem: false, sortOrder: 5),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, type: .expense, name: "水电", iconKey: "lightbulb.fill", colorHex: 0xEAB308, isSystem: false, sortOrder: 6),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, type: .expense, name: "通讯", iconKey: "phone.fill", colorHex: 0x06B6D4, isSystem: false, sortOrder: 7),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, type: .expense, name: "医疗", iconKey: "cross.case.fill", colorHex: 0xEF4444, isSystem: false, sortOrder: 8),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, type: .expense, name: "教育", iconKey: "graduationcap.fill", colorHex: 0x8B5CF6, isSystem: false, sortOrder: 9),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, type: .expense, name: "娱乐", iconKey: "film", colorHex: 0xEC4899, isSystem: false, sortOrder: 10),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!, type: .expense, name: "旅行", iconKey: "airplane", colorHex: 0x14B8A6, isSystem: false, sortOrder: 11),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!, type: .expense, name: "运动", iconKey: "dumbbell.fill", colorHex: 0x38BDF8, isSystem: false, sortOrder: 12),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!, type: .expense, name: "油费", iconKey: "fuelpump.fill", colorHex: 0xF97316, isSystem: false, sortOrder: 13),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000016")!, type: .expense, name: "停车", iconKey: "parkingsign.circle.fill", colorHex: 0x3B82F6, isSystem: false, sortOrder: 14),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!, type: .expense, name: "票务", iconKey: "ticket.fill", colorHex: 0xF472B6, isSystem: false, sortOrder: 15),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000018")!, type: .expense, name: "咖啡", iconKey: "cup.and.saucer.fill", colorHex: 0xA855F7, isSystem: false, sortOrder: 16),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000019")!, type: .expense, name: "外卖", iconKey: "takeoutbag.and.cup.and.straw.fill", colorHex: 0x13EC37, isSystem: false, sortOrder: 17),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!, type: .expense, name: "甜点", iconKey: "birthday.cake.fill", colorHex: 0xEC4899, isSystem: false, sortOrder: 18),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!, type: .expense, name: "宠物", iconKey: "pawprint.fill", colorHex: 0x22C55E, isSystem: false, sortOrder: 19),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!, type: .expense, name: "服饰", iconKey: "tshirt.fill", colorHex: 0xF43F5E, isSystem: false, sortOrder: 20),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!, type: .expense, name: "美妆", iconKey: "paintbrush.fill", colorHex: 0xA855F7, isSystem: false, sortOrder: 21),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000024")!, type: .expense, name: "家居", iconKey: "bed.double.fill", colorHex: 0x6366F1, isSystem: false, sortOrder: 22),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000025")!, type: .expense, name: "家电", iconKey: "tv.fill", colorHex: 0x3B82F6, isSystem: false, sortOrder: 23),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000026")!, type: .expense, name: "家装", iconKey: "wrench.and.screwdriver.fill", colorHex: 0x14B8A6, isSystem: false, sortOrder: 24),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000027")!, type: .expense, name: "游戏", iconKey: "gamecontroller.fill", colorHex: 0x8B5CF6, isSystem: false, sortOrder: 25),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000028")!, type: .expense, name: "音乐", iconKey: "music.note", colorHex: 0x06B6D4, isSystem: false, sortOrder: 26),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000029")!, type: .expense, name: "电影", iconKey: "theatermasks.fill", colorHex: 0xEF4444, isSystem: false, sortOrder: 27),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000030")!, type: .expense, name: "礼物", iconKey: "gift.fill", colorHex: 0xF472B6, isSystem: false, sortOrder: 28),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!, type: .expense, name: "社交", iconKey: "person.2.fill", colorHex: 0x38BDF8, isSystem: false, sortOrder: 29),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000032")!, type: .expense, name: "其他", iconKey: "bag.badge.plus", colorHex: 0x22C55E, isSystem: false, sortOrder: 30),

        // Income presets (10)
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000033")!, type: .income, name: "工资", iconKey: "creditcard.fill", colorHex: 0x3B82F6, isSystem: false, sortOrder: 1),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000034")!, type: .income, name: "奖金", iconKey: "banknote.fill", colorHex: 0x13EC37, isSystem: false, sortOrder: 2),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000035")!, type: .income, name: "投资", iconKey: "chart.line.uptrend.xyaxis", colorHex: 0x22C55E, isSystem: false, sortOrder: 3),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000036")!, type: .income, name: "理财", iconKey: "percent", colorHex: 0x8B5CF6, isSystem: false, sortOrder: 4),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000037")!, type: .income, name: "报销", iconKey: "doc.text.fill", colorHex: 0x06B6D4, isSystem: false, sortOrder: 5),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000038")!, type: .income, name: "生意", iconKey: "briefcase.fill", colorHex: 0xF97316, isSystem: false, sortOrder: 6),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000039")!, type: .income, name: "兼职", iconKey: "wallet.pass.fill", colorHex: 0xEC4899, isSystem: false, sortOrder: 7),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000040")!, type: .income, name: "红包", iconKey: "gift.fill", colorHex: 0xF472B6, isSystem: false, sortOrder: 8),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000041")!, type: .income, name: "退款", iconKey: "repeat", colorHex: 0x14B8A6, isSystem: false, sortOrder: 9),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000042")!, type: .income, name: "其他收入", iconKey: "dollarsign.circle.fill", colorHex: 0xEAB308, isSystem: false, sortOrder: 10)
    ]

    func seedIfNeeded() throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        fetchRequest.fetchLimit = 1
        let existingCount = try context.count(for: fetchRequest)
        if existingCount == 0 {
            for seed in categories {
                let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
                apply(seed, to: object)
            }
        } else {
            try ensureSystemCategories()
        }

        if context.hasChanges {
            try context.save()
        }
    }

    func seedPreviewBill() throws {
        let object = NSEntityDescription.insertNewObject(forEntityName: "Bill", into: context)
        let now = Date()
        let snapshot = TimePolicy.snapshot(for: now)
        object.setValue(UUID(), forKey: "id")
        object.setValue(BillType.expense.rawValue, forKey: "type")
        object.setValue(Int64(428560), forKey: "amount")
        object.setValue(snapshot.occurredAtUTC, forKey: "occurredAtUTC")
        object.setValue(snapshot.tzId, forKey: "tzId")
        object.setValue(Int32(snapshot.tzOffset), forKey: "tzOffset")
        object.setValue(snapshot.occurredLocalDate, forKey: "occurredLocalDate")
        object.setValue("示例账单", forKey: "note")
        object.setValue(false, forKey: "isFromRecurring")
        object.setValue(now, forKey: "createdAt")
        object.setValue(now, forKey: "updatedAt")

        if context.hasChanges {
            try context.save()
        }
    }

    private func ensureSystemCategories() throws {
        let systemSeeds = categories.filter { $0.isSystem }
        for seed in systemSeeds {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", seed.id as CVarArg)
            let objects = try context.fetch(request)
            let object = objects.first ?? NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
            apply(seed, to: object)
        }
    }

    private func apply(_ seed: SeedCategory, to object: NSManagedObject) {
        object.setValue(seed.id, forKey: "id")
        object.setValue(seed.type.rawValue, forKey: "type")
        object.setValue(seed.name, forKey: "name")
        object.setValue(seed.iconKey, forKey: "iconKey")
        object.setValue(Int64(seed.colorHex), forKey: "colorHex")
        object.setValue(seed.isSystem, forKey: "isSystem")
        object.setValue(Int64(seed.sortOrder), forKey: "sortOrder")
    }
}
