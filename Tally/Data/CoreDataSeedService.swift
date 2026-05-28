import CoreData

struct CoreDataSeedService: SeedService {
    static let colorMigrationFlagKey = "tally.color.migration.v1"
    static let iconMigrationFlagKey = "tally.icon.migration.phosphor.v1"

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    static let brandColorHexByCategoryName: [String: Int] = [
        "午餐": BrandSwatch.catPersimmon,
        "咖啡": BrandSwatch.catOchre,
        "晚餐": BrandSwatch.catTerracotta,
        "日用": BrandSwatch.catMoss,
        "通勤": BrandSwatch.catSlate,
        "房租": BrandSwatch.catIndigo,
        "水电": BrandSwatch.catOchre,
        "网络": BrandSwatch.catTeal,
        "医疗": BrandSwatch.catRose,
        "教育": BrandSwatch.catPlum,
        "衣物": BrandSwatch.catSage,
        "观影": BrandSwatch.catTerracotta,
        "音乐": BrandSwatch.catPlum,
        "宠物": BrandSwatch.catOlive,
        "旅行": BrandSwatch.catTeal,
        "礼物": BrandSwatch.catRose,
        "游戏": BrandSwatch.catIndigo,
        "未分类": BrandSwatch.catAsh,
        "薪资": BrandSwatch.catMoss,
        "奖金": BrandSwatch.catOchre,
        "副业": BrandSwatch.catTeal,
        "理财": BrandSwatch.catSlate
    ]

    private static let brandColorHexBySeedCategoryName: [String: Int] = {
        var values = brandColorHexByCategoryName
        values.merge([
            "早餐": BrandSwatch.catOchre,
            "运动": BrandSwatch.catSage,
            "油费": BrandSwatch.catSlate,
            "甜点": BrandSwatch.catRose,
            "服饰": BrandSwatch.catSage,
            "通讯": BrandSwatch.catTeal,
            "娱乐": BrandSwatch.catTerracotta,
            "其他": BrandSwatch.catAsh,
            "交通": BrandSwatch.catSlate,
            "购物": BrandSwatch.catMoss,
            "工资": BrandSwatch.catMoss,
            "基金": BrandSwatch.catSlate,
            "黄金": BrandSwatch.catOchre,
            "股票": BrandSwatch.catMoss,
            "兼职": BrandSwatch.catTeal,
            "礼金": BrandSwatch.catRose,
            "红包": BrandSwatch.catRose,
            "投资": BrandSwatch.catSlate,
            "退款": BrandSwatch.catTeal
        ]) { current, _ in current }
        return values
    }()

    static var presetCategoryIDs: Set<UUID> {
        Set(categories.map(\.id))
    }

    static let legacyIconKeyMap: [String: String] = [
        "fork.knife": "fork-knife",
        "cup.and.saucer.fill": "coffee",
        "cup.and.heat.waves.fill": "coffee",
        "cart.fill": "shopping-cart",
        "bag.fill": "shopping-bag",
        "house.fill": "house",
        "lightbulb.fill": "lightbulb",
        "drop.fill": "drop",
        "cross.case.fill": "first-aid-kit",
        "pills.fill": "pill",
        "graduationcap.fill": "graduation-cap",
        "book.fill": "book-open",
        "car.fill": "car",
        "tram.fill": "train",
        "airplane": "airplane-tilt",
        "fuelpump.fill": "gas-pump",
        "birthday.cake.fill": "cake",
        "banknote.fill": "money-wavy",
        "creditcard.fill": "credit-card",
        "briefcase.fill": "briefcase",
        "dumbbell.fill": "barbell",
        "figure.walk": "person-simple-run",
        "gift.fill": "gift",
        "film": "film-slate",
        "music.note": "music-notes",
        "pawprint.fill": "paw-print",
        "leaf.fill": "leaf",
        "wifi": "wifi-high",
        "phone.fill": "phone",
        "repeat": "repeat",
        "tshirt.fill": "t-shirt",
        "scissors": "scissors",
        "gamecontroller.fill": "game-controller",
        "doc.text.fill": "file-text",
        "fish": "bowl-food",
        "basket.fill": "shopping-bag",
        "bag.badge.plus": "tag",
        "questionmark": "tag",
        "bus": "bus",
        "wallet.pass.fill": "wallet",
        "dollarsign.circle.fill": "currency-cny",
        "chart.line.uptrend.xyaxis": "coins",
        "percent": "coins",
        "envelope.fill": "gift"
    ]

    private enum BrandSwatch {
        static let catTerracotta = 0xB8553E
        static let catPersimmon = 0xD6864A
        static let catOchre = 0xC49A3C
        static let catOlive = 0x7A8043
        static let catMoss = 0x4D7148
        static let catSage = 0x5E8B7A
        static let catTeal = 0x3D7D7E
        static let catSlate = 0x5C6F86
        static let catIndigo = 0x5B5E8A
        static let catPlum = 0x7E4D6E
        static let catRose = 0xA65566
        static let catAsh = 0x6B6964
    }

    private struct SeedCategory {
        let id: UUID
        let type: BillType
        let name: String
        let iconKey: String
        let legacyColorHex: Int
        let isSystem: Bool
        let sortOrder: Int

        var colorHex: Int {
            CoreDataSeedService.brandColorHex(for: name, fallback: legacyColorHex)
        }

        init(
            id: UUID,
            type: BillType,
            name: String,
            iconKey: String,
            colorHex: Int,
            isSystem: Bool,
            sortOrder: Int
        ) {
            self.id = id
            self.type = type
            self.name = name
            self.iconKey = iconKey
            self.legacyColorHex = colorHex
            self.isSystem = isSystem
            self.sortOrder = sortOrder
        }
    }

    private static let categories: [SeedCategory] = [
        SeedCategory(id: SystemCategoryID.uncategorizedExpense, type: .expense, name: "未分类", iconKey: "tag", colorHex: 0x13EC37, isSystem: true, sortOrder: 0),
        SeedCategory(id: SystemCategoryID.uncategorizedIncome, type: .income, name: "未分类", iconKey: "tag", colorHex: 0x13EC37, isSystem: true, sortOrder: 0),

        // Expense presets (20)
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, type: .expense, name: "晚餐", iconKey: "fork-knife", colorHex: 0xF97316, isSystem: false, sortOrder: 1),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, type: .expense, name: "午餐", iconKey: "bowl-food", colorHex: 0x3B82F6, isSystem: false, sortOrder: 2),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, type: .expense, name: "早餐", iconKey: "coffee", colorHex: 0x13EC37, isSystem: false, sortOrder: 3),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, type: .expense, name: "咖啡", iconKey: "coffee", colorHex: 0xA855F7, isSystem: false, sortOrder: 4),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, type: .expense, name: "房租", iconKey: "house", colorHex: 0x6366F1, isSystem: false, sortOrder: 5),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, type: .expense, name: "水电", iconKey: "lightbulb", colorHex: 0xEAB308, isSystem: false, sortOrder: 6),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!, type: .expense, name: "医疗", iconKey: "first-aid-kit", colorHex: 0xEF4444, isSystem: false, sortOrder: 7),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, type: .expense, name: "教育", iconKey: "graduation-cap", colorHex: 0x8B5CF6, isSystem: false, sortOrder: 8),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!, type: .expense, name: "旅行", iconKey: "airplane-tilt", colorHex: 0x14B8A6, isSystem: false, sortOrder: 9),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!, type: .expense, name: "运动", iconKey: "barbell", colorHex: 0x38BDF8, isSystem: false, sortOrder: 10),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!, type: .expense, name: "油费", iconKey: "gas-pump", colorHex: 0xF97316, isSystem: false, sortOrder: 11),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!, type: .expense, name: "甜点", iconKey: "cake", colorHex: 0xEC4899, isSystem: false, sortOrder: 12),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!, type: .expense, name: "宠物", iconKey: "paw-print", colorHex: 0x22C55E, isSystem: false, sortOrder: 13),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000016")!, type: .expense, name: "服饰", iconKey: "t-shirt", colorHex: 0xF43F5E, isSystem: false, sortOrder: 14),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!, type: .expense, name: "通讯", iconKey: "phone", colorHex: 0x06B6D4, isSystem: false, sortOrder: 15),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000018")!, type: .expense, name: "娱乐", iconKey: "film-slate", colorHex: 0x8B5CF6, isSystem: false, sortOrder: 16),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000019")!, type: .expense, name: "其他", iconKey: "tag", colorHex: 0x6366F1, isSystem: false, sortOrder: 17),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!, type: .expense, name: "交通", iconKey: "bus", colorHex: 0x3B82F6, isSystem: false, sortOrder: 18),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!, type: .expense, name: "购物", iconKey: "shopping-cart", colorHex: 0x13EC37, isSystem: false, sortOrder: 19),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!, type: .expense, name: "日用", iconKey: "shopping-bag", colorHex: 0x22C55E, isSystem: false, sortOrder: 20),

        // Income presets (10)
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000033")!, type: .income, name: "工资", iconKey: "credit-card", colorHex: 0x3B82F6, isSystem: false, sortOrder: 1),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000034")!, type: .income, name: "基金", iconKey: "coins", colorHex: 0x13EC37, isSystem: false, sortOrder: 2),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000035")!, type: .income, name: "黄金", iconKey: "money-wavy", colorHex: 0xEAB308, isSystem: false, sortOrder: 3),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000036")!, type: .income, name: "股票", iconKey: "coins", colorHex: 0x22C55E, isSystem: false, sortOrder: 4),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000037")!, type: .income, name: "兼职", iconKey: "briefcase", colorHex: 0xEC4899, isSystem: false, sortOrder: 5),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000038")!, type: .income, name: "礼金", iconKey: "gift", colorHex: 0xF472B6, isSystem: false, sortOrder: 6),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000039")!, type: .income, name: "红包", iconKey: "gift", colorHex: 0xF43F5E, isSystem: false, sortOrder: 7),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000040")!, type: .income, name: "投资", iconKey: "wallet", colorHex: 0x8B5CF6, isSystem: false, sortOrder: 8),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000041")!, type: .income, name: "退款", iconKey: "repeat", colorHex: 0x14B8A6, isSystem: false, sortOrder: 9),
        SeedCategory(id: UUID(uuidString: "00000000-0000-0000-0000-000000000042")!, type: .income, name: "其他", iconKey: "currency-cny", colorHex: 0x6366F1, isSystem: false, sortOrder: 10)
    ]

    func seedIfNeeded() throws {
        try ensurePresetCategories()

        if context.hasChanges {
            try context.save()
        }
    }

    func migrateLegacyCategoryColors(userDefaults: UserDefaults = .standard) throws {
        try Self.migrateLegacyCategoryColors(in: context, userDefaults: userDefaults)
    }

    func migrateLegacyIconKeys(userDefaults: UserDefaults = .standard) throws {
        try Self.migrateLegacyIconKeys(in: context, userDefaults: userDefaults)
    }

    static func migrateLegacyCategoryColors(
        in context: NSManagedObjectContext,
        userDefaults: UserDefaults = .standard
    ) throws {
        guard !userDefaults.bool(forKey: colorMigrationFlagKey) else { return }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        let categories = try context.fetch(request)
        for category in categories {
            guard
                let id = category.value(forKey: "id") as? UUID,
                presetCategoryIDs.contains(id),
                let name = category.value(forKey: "name") as? String,
                let colorHex = brandColorHexBySeedCategoryName[name]
            else {
                continue
            }
            category.setValue(Int64(colorHex), forKey: "colorHex")
        }

        if context.hasChanges {
            try context.save()
        }
        userDefaults.set(true, forKey: colorMigrationFlagKey)
    }

    static func migrateLegacyIconKeys(
        in context: NSManagedObjectContext,
        userDefaults: UserDefaults = .standard
    ) throws {
        guard !userDefaults.bool(forKey: iconMigrationFlagKey) else { return }

        let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
        let categories = try context.fetch(request)
        for category in categories {
            guard
                let iconKey = category.value(forKey: "iconKey") as? String,
                let migratedIconKey = legacyIconKeyMap[iconKey]
            else {
                continue
            }
            category.setValue(migratedIconKey, forKey: "iconKey")
        }

        if context.hasChanges {
            try context.save()
        }
        userDefaults.set(true, forKey: iconMigrationFlagKey)
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

    private func ensurePresetCategories() throws {
        for seed in Self.categories {
            let request = NSFetchRequest<NSManagedObject>(entityName: "Category")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", seed.id as CVarArg)
            let objects = try context.fetch(request)
            if let existing = objects.first {
                if seed.isSystem {
                    apply(seed, to: existing)
                }
            } else {
                let object = NSEntityDescription.insertNewObject(forEntityName: "Category", into: context)
                apply(seed, to: object)
            }
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

    private static func brandColorHex(for name: String, fallback: Int) -> Int {
        brandColorHexBySeedCategoryName[name] ?? fallback
    }
}
