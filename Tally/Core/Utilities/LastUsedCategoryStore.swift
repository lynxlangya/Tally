import Foundation

/// 记住用户在快速记账里上次选用的分类，按收 / 支分别存储，作为下次打开时的默认选中。
/// 首次使用或该分类已被删除时返回 nil，由调用方决定不预选（而非强制选列表第一个）。
enum LastUsedCategoryStore {
    /// 仅 App 进程内使用，无需 App Group。`static var` 便于测试注入独立 suite 做隔离。
    static var defaults: UserDefaults = .standard

    private static func key(for type: BillType) -> String {
        "quickEntry.lastCategory.\(type.rawValue)"
    }

    static func categoryID(for type: BillType) -> UUID? {
        defaults.string(forKey: key(for: type)).flatMap(UUID.init(uuidString:))
    }

    static func record(_ id: UUID, for type: BillType) {
        defaults.set(id.uuidString, forKey: key(for: type))
    }
}
