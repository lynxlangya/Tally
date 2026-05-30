import Foundation

enum L10nKey: String {
    case about = "about"
    case accountSettings = "account_settings"
    case appLanguage = "app_language"
    case applicationLanguage = "application_language"
    case amount = "amount"
    case averageDaily = "average_daily"
    case balance = "balance"
    case bills = "bills"
    case billCount = "bill_count"
    case billLoadFailed = "bill_load_failed"
    case billDeleteFailed = "bill_delete_failed"
    case billRecordedDays = "bill_recorded_days"
    case cancel = "cancel"
    case categories = "categories"
    case categoryRanking = "category_ranking"
    case categoryCountSummary = "category_count_summary"
    case continueAction = "continue_action"
    case date = "date"
    case dailyReminder = "daily_reminder"
    case delete = "delete"
    case deleteBill = "delete_bill"
    case deleteBillConfirm = "delete_bill_confirm"
    case deleteCategoryConfirm = "delete_category_confirm"
    case detailByDate = "detail_by_date"
    case detail = "detail"
    case done = "done"
    case enabledRecurringCount = "enabled_recurring_count"
    case entryCount = "entry_count"
    case expense = "expense"
    case expenseDetail = "expense_detail"
    case formatPreview = "format_preview"
    case gotIt = "got_it"
    case home = "home"
    case importExport = "import_export"
    case income = "income"
    case incomeDetail = "income_detail"
    case language = "language"
    case languageEnglish = "language_english"
    case languageEnglishCode = "language_english_code"
    case languageEnglishSubtitle = "language_english_subtitle"
    case languageSimplifiedChinese = "language_simplified_chinese"
    case languageSimplifiedChineseCode = "language_simplified_chinese_code"
    case languageSimplifiedChineseSubtitle = "language_simplified_chinese_subtitle"
    case languageSystem = "language_system"
    case languageSystemCode = "language_system_code"
    case languageSystemNative = "language_system_native"
    case languageSystemSubtitle = "language_system_subtitle"
    case moneySymbol = "money_symbol"
    case moneySymbolDollar = "money_symbol_dollar"
    case moneySymbolDollarSubtitle = "money_symbol_dollar_subtitle"
    case moneySymbolYuan = "money_symbol_yuan"
    case moneySymbolYuanSubtitle = "money_symbol_yuan_subtitle"
    case monthlyExpense = "monthly_expense"
    case month = "month"
    case more = "more"
    case newCategory = "new_category"
    case newRecurring = "new_recurring"
    case noCategoryRecords = "no_category_records"
    case noDetails = "no_details"
    case noNote = "no_note"
    case note = "note"
    case operationIncomplete = "operation_incomplete"
    case periodWeekOrdinal = "period_week_ordinal"
    case profile = "profile"
    case quickEntry = "quick_entry"
    case recurring = "recurring"
    case recurringRule = "recurring_rule"
    case recent7Days = "recent_7_days"
    case settings = "settings"
    case summaryTotal = "summary_total"
    case trendCustom = "trend_custom"
    case trendMonth = "trend_month"
    case trendWeek = "trend_week"
    case trendYear = "trend_year"
    case themeSettings = "theme_settings"
    case timeRangeCustom = "time_range_custom"
    case timeRangeMonth = "time_range_month"
    case timeRangeWeek = "time_range_week"
    case timeRangeYear = "time_range_year"
    case today = "today"
    case todayShort = "today_short"
    case transactionCount = "transaction_count"
    case uncategorized = "uncategorized"
    case undoUnavailable = "undo_unavailable"
    case week = "week"
    case widget = "widget"
    case yesterday = "yesterday"
}

enum TallyLocalization {
    static let defaultLocale = Locale(identifier: "zh-Hans-CN")

    static func string(_ key: L10nKey, locale: Locale = Locale.autoupdatingCurrent) -> String {
        localizedString(for: key.rawValue, locale: locale)
    }

    static func string(_ key: String, locale: Locale = Locale.autoupdatingCurrent) -> String {
        localizedString(for: key, locale: locale)
    }

    static func text(_ key: L10nKey, locale: Locale = Locale.autoupdatingCurrent) -> String {
        string(key, locale: locale)
    }

    static func text(_ key: String, locale: Locale = Locale.autoupdatingCurrent) -> String {
        string(key, locale: locale)
    }

    static func format(_ key: L10nKey, locale: Locale = Locale.autoupdatingCurrent, _ arguments: CVarArg...) -> String {
        String(format: string(key, locale: locale), locale: locale, arguments: arguments)
    }

    static func format(_ key: String, locale: Locale = Locale.autoupdatingCurrent, _ arguments: CVarArg...) -> String {
        String(format: string(key, locale: locale), locale: locale, arguments: arguments)
    }

    static func localizedString(for key: String, locale: Locale = Locale.autoupdatingCurrent) -> String {
        let bundle = resourceBundle
        let languageCode = supportedLanguageCode(for: locale)
        let fallback = fallbackText(for: key, languageCode: languageCode) ?? key

        guard let path = bundle.path(forResource: languageCode, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            return fallback
        }

        return languageBundle.localizedString(forKey: key, value: fallback, table: nil)
    }

    static func supportedLanguageCode(for locale: Locale) -> String {
        locale.language.languageCode?.identifier == "en" ? "en" : "zh-Hans"
    }

    static func storedLanguageLocale(rawValue: String?, systemLocale: Locale = Locale.autoupdatingCurrent) -> Locale {
        switch rawValue {
        case "en":
            return Locale(identifier: "en-US")
        case "zhHans":
            return defaultLocale
        default:
            return supportedLanguageCode(for: systemLocale) == "en" ? Locale(identifier: "en-US") : defaultLocale
        }
    }

    static var widgetLocale: Locale {
        storedLanguageLocale(rawValue: TallyLanguageStore.loadSelectedLanguage())
    }

    static func monthYearTitle(for date: Date, locale: Locale = Locale.autoupdatingCurrent) -> String {
        formattedDate(date, locale: locale, template: "yMMMM")
    }

    static func yearTitle(for date: Date, locale: Locale = Locale.autoupdatingCurrent) -> String {
        formattedDate(date, locale: locale, template: "y")
    }

    static func monthTitle(for date: Date, locale: Locale = Locale.autoupdatingCurrent) -> String {
        formattedDate(date, locale: locale, template: "MMM")
    }

    static func monthDayTitle(for date: Date, locale: Locale = Locale.autoupdatingCurrent) -> String {
        formattedDate(date, locale: locale, template: "MMMd")
    }

    static func weekdayTitle(for date: Date, locale: Locale = Locale.autoupdatingCurrent) -> String {
        formattedDate(date, locale: locale, template: "EEE")
    }

    private static func formattedDate(_ date: Date, locale: Locale, template: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = locale
        formatter.timeZone = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }

    private static var resourceBundle: Bundle {
        Bundle.main
    }

    private static func fallbackText(for key: String, languageCode: String) -> String? {
        extraFallbackTextByLanguage[languageCode]?[key]
            ?? extraFallbackTextByLanguage["zh-Hans"]?[key]
            ?? fallbackTextByLanguage[languageCode]?[key]
            ?? fallbackTextByLanguage["zh-Hans"]?[key]
    }

    private static let extraFallbackTextByLanguage: [String: [String: String]] = [
        "en": [
            "back": "Back",
            "save": "Save",
            "close": "Close",
            "enabled": "On",
            "disabled": "Off",
            "try_again_later": "Please try again later.",
            "preparing_ledger": "Preparing your ledger",
            "opening_local_data": "Opening local data. Please wait.",
            "last_7_days": "Last 7 Days",
            "tally_slogan": "A mark for every entry.",
            "yesterday_change_format": "%@ · vs yesterday %@ %d%%",
            "choose_period": "Choose Period",
            "jump_to_week_hint": "Pick any day to jump to that week",
            "custom_range_hint": "The end date cannot be later than today; reversed dates are adjusted automatically.",
            "start_date": "Start Date",
            "end_date": "End Date",
            "year_to_date": "Year to date",
            "full_year": "Full year",
            L10nKey.moneySymbol.rawValue: "Money Symbol",
            L10nKey.moneySymbolDollar.rawValue: "Dollar Symbol",
            L10nKey.moneySymbolDollarSubtitle.rawValue: "Show amounts with $",
            L10nKey.moneySymbolYuan.rawValue: "Yuan Symbol",
            L10nKey.moneySymbolYuanSubtitle.rawValue: "Show amounts with ¥",
            "peak_empty_format": "Peak - %@",
            "peak_format": "Peak %@ %@",
            "summary_total_type": "%@ %@",
            "most": "Most",
            "least": "Least",
            "expense_ranking": "Expense Ranking",
            "income_ranking": "Income Ranking",
            "category_management": "Category Management",
            "theme_appearance": "Theme & Appearance",
            "language_backup_subtitle": "CSV · JSON Backup",
            "widget_profile_subtitle": "Quick Entry · Monthly Trend",
            "notification_permission_title": "Notifications are off",
            "notification_permission_message": "Enable notifications in System Settings before using Daily Reminder.",
            "open_settings": "Open Settings",
            "daily_reminder_time": "Remind daily at 20:00",
            "daily_reminder_body": "Do not forget to record today's bills.",
            "recorded_week_progress": "%d / 7 days tracked",
            "profile_load_failed": "Profile data could not be loaded. Please try again later.",
            "error_not_found": "The data could not be found. Please go back and try again.",
            "error_invalid_data": "Local data is invalid. Please try again later.",
            "about_tally": "About Tally",
            "local_single_currency": "Single-currency local ledger",
            "version": "Version",
            "data_scope": "Data Scope",
            "data_scope_value": "Bills, categories, recurring entries, widget snapshots",
            "privacy_policy": "Privacy",
            "local_by_default": "Local by default",
            "local_by_default_detail": "Bills, categories, preferences, and avatar stay on this device. Widgets only read summary snapshots from App Group storage.",
            "no_network_analytics": "No analytics",
            "no_network_analytics_detail": "This version has no third-party analytics, ad tracking, or remote account sync.",
            "notification_opt_in": "Notifications are opt-in",
            "notification_opt_in_detail": "Daily Reminder asks for notification permission only after you enable it.",
            "data_backup": "Data & Backup",
            "manual_import_export": "Manual import and export",
            "manual_import_export_detail": "Create CSV or JSON backups from Import & Export.",
            "avatar_selection": "Avatar selection",
            "avatar_selection_detail": "Account avatars come from the system photo picker and are only used for local display.",
            "support": "Support",
            "report_issue": "Report Issue",
            "report_issue_detail": "Email issues and suggestions to hey@wangyun.fan.",
            "feedback_email_unavailable_title": "Mail isn't set up",
            "feedback_email_unavailable_detail": "Copy hey@wangyun.fan and send feedback from your mail app.",
            "copy_email": "Copy Email",
            "acknowledgements": "Acknowledgements",
            "apple_platforms": "Apple Platform Technologies",
            "apple_platforms_detail": "Tally is built with SwiftUI, Core Data, and WidgetKit.",
            "current_data": "Current Data",
            "records_unit": "records",
            "export_scope": "Export Scope",
            "recent_records": "Recent Records",
            "no_import_export_logs": "No import or export records yet.",
            "export_csv": "Export CSV",
            "export_csv_subtitle": "For spreadsheet analysis and secondary processing",
            "export_backup_json": "Export Backup JSON",
            "export_backup_json_subtitle": "Full backup of bills and categories",
            "import_backup": "Import Backup",
            "import_backup_subtitle": "Restore data from a backup file",
            "import_csv": "Import CSV",
            "import_csv_subtitle": "Import bills from a standard CSV",
            "import_preflight": "Import Preview",
            "confirm_import": "Confirm Import",
            "import_result": "Import Result",
            "import_export_empty_range": "No record range yet.",
            "import_export_range_subtitle": "Range %@ - %@ · %d days",
            "import_pending_count": "Importable: %d",
            "import_conflict_count": "Conflicts: %d",
            "import_failed_count": "Failed: %d",
            "import_success_count": "Imported: %d",
            "import_skipped_count": "Skipped: %d",
            "import_error_summary": "Error Summary:",
            "export_generated_with_size": "Generated %@ (%d records, %@)",
            "export_generated": "Generated %@ (%d records)",
            "feature_in_development": "%@ is in development",
            "action_failed_try_later": "%@ failed. Please try again later.",
            "import_export_log_meta": "%@ · %@ · %d records · %d errors",
            "count_error_unit": "%d errors",
            "current_month": "Current Month",
            "all_records": "All",
            "theme_title": "Theme & Appearance",
            "icon_switch_unavailable": "Icon cannot be changed now",
            "preview_current_month": "Preview · This Month",
            "preview_quick_entry": "Preview Add Entry",
            "appearance_skin": "Appearance",
            "signature_color": "SIGNATURE Color",
            "accent_usage_hint": "FAB · Income · Accent",
            "app_icon": "App Icon",
            "app_icon_trailing": "Syncs with Home Screen",
            "details": "Details",
            "reduce_motion": "Reduce Motion",
            "reduce_motion_subtitle": "Disable spring and transition animations",
            "haptic_feedback": "Haptic Feedback",
            "haptic_feedback_subtitle": "Light tap for Add Entry and keypad",
            "reset_default_format": "Reset · %@ %@",
            "appearance_dark_title": "Night",
            "appearance_light_title": "Day",
            "appearance_system_title": "Auto",
            "appearance_dark_subtitle": "Ink",
            "appearance_light_subtitle": "Moon",
            "appearance_system_subtitle": "System",
            "appearance_dark_profile": "Dark",
            "appearance_light_profile": "Light",
            "appearance_system_profile": "System",
            "app_icon_vermilion": "Vermilion",
            "app_icon_moon": "Moon",
            "app_icon_ink": "Ink",
            "app_icon_ink_note": "Ink Note",
            "accent_vermilion": "Vermilion",
            "accent_red_ochre": "Red Ochre",
            "accent_pine": "Pine",
            "accent_brass": "Brass",
            "accent_wisteria": "Wisteria",
            "accent_moon": "Moon",
            "widget_intro_title": "Two Home Screen Entries",
            "widget_intro_subtitle": "One opens quick entry, the other shows the monthly trend at a glance.",
            "widget_quick_entry_title": "Today Entry",
            "widget_quick_entry_subtitle": "Tap to open Add Entry",
            "widget_summary_title": "Monthly Trend",
            "widget_summary_subtitle": "Tap to return to the ledger home",
            "widget_add_path": "Add Path",
            "widget_home_screen": "Home Screen",
            "widget_step_hold": "Touch and hold the Home Screen",
            "widget_step_hold_detail": "Enter Home Screen editing",
            "widget_step_plus": "Tap + in the top-left corner",
            "widget_step_plus_detail": "Search for Tally",
            "widget_step_size": "Choose a size",
            "widget_step_size_detail": "Small or Medium",
            "widget_count_unit": "types",
            "quick_entry_widget_name": "Quick Entry",
            "quick_entry_widget_description": "View today's spending and add an entry quickly",
            "summary_trend_widget_name": "Monthly Overview",
            "summary_trend_widget_description": "View this month's balance and trend",
            "no_recurring_bills": "No recurring bills yet.",
            "pause": "Pause",
            "enable": "Enable",
            "enabled_paused_summary": "%d enabled · %d paused",
            "next_fire_format": "Next %@",
            "recurring_load_failed": "Recurring bills could not be loaded. Please try again later.",
            "recurring_enable_failed": "Failed to enable recurring bill. Please try again later.",
            "recurring_pause_failed": "Failed to pause recurring bill. Please try again later.",
            "recurring_delete_failed": "Failed to delete recurring bill. Please try again later.",
            "recurring_save_failed": "Failed to save recurring bill. Please try again later.",
            "repeat_daily": "Daily",
            "repeat_weekly": "Weekly",
            "repeat_monthly_first": "Beginning of month",
            "repeat_monthly_last": "End of month",
            "repeat_rule_daily_title": "Every day",
            "repeat_rule_weekly_monday_title": "Weekly (Monday)",
            "repeat_rule_weekly_sunday_title": "Weekly (Sunday)",
            "repeat_rule_monthly_first_title": "Monthly (start)",
            "repeat_rule_monthly_last_title": "Monthly (end)",
            "category_load_failed": "Categories could not be loaded. Please try again later.",
            "select_category": "Select a category",
            "amount_positive_required": "Amount must be greater than 0",
            "amount_invalid": "Amount is invalid",
            "bill_save_failed": "Failed to save the bill. Please try again later.",
            "first_fire_must_be_future": "First run time must be later than now",
            "optional": "Optional",
            "choose_time": "Choose Time",
            "next_trigger": "Next Trigger",
            "change_avatar": "Change Avatar",
            "use_default_avatar": "Use App Icon",
            "avatar_update_failed": "Avatar update failed. Please try again later.",
            "name": "Name",
            "enter_name": "Enter name",
            "edit_category": "Edit Category",
            "category_name": "Category Name",
            "color": "Color",
            "icon": "Icon",
            "category_limit_message": "You can add up to %d categories",
            "category_name_empty": "Category name cannot be empty",
            "category_name_exists": "Category name already exists",
            "category_not_found": "Category not found",
            "system_category_edit_forbidden": "System categories cannot be edited",
            "system_category_delete_forbidden": "System categories cannot be deleted",
            "category_create_failed": "Failed to create category. Please try again later.",
            "category_update_failed": "Failed to update category. Please try again later.",
            "category_delete_failed": "Failed to delete category. Please try again later.",
            "category_order_save_failed": "Failed to save category order. Please try again later."
        ],
        "zh-Hans": [
            "back": "返回",
            "save": "保存",
            "close": "关闭",
            "enabled": "已开启",
            "disabled": "已关闭",
            "try_again_later": "请稍后再试。",
            "preparing_ledger": "正在准备账本",
            "opening_local_data": "正在打开本地数据，请稍候。",
            "last_7_days": "近 7 日",
            "tally_slogan": "一根刻痕，一笔账。",
            "yesterday_change_format": "%@ · 较昨日 %@ %d%%",
            "choose_period": "选择期间",
            "jump_to_week_hint": "点任意一天，跳到该周",
            "custom_range_hint": "结束日不会晚于今天；起止选反时会自动调整。",
            "start_date": "起始日",
            "end_date": "结束日",
            "year_to_date": "至今",
            "full_year": "全年",
            "peak_empty_format": "峰值 - %@",
            "peak_format": "峰值 %@ %@",
            "summary_total_type": "%@总%@",
            "most": "最多",
            "least": "最少",
            "expense_ranking": "支出排行",
            "income_ranking": "收入排行",
            "category_management": "分类管理",
            "theme_appearance": "主题与外观",
            "language_backup_subtitle": "CSV · JSON 备份",
            "widget_profile_subtitle": "快捷记账 · 月度趋势",
            "notification_permission_title": "通知权限未开启",
            "notification_permission_message": "请在系统设置中开启通知权限后再使用每日提醒。",
            "open_settings": "打开设置",
            "daily_reminder_time": "每天 20:00 提醒",
            "daily_reminder_body": "别忘了记录今天的账单",
            "recorded_week_progress": "已记 %d / 7 天",
            "profile_load_failed": "个人页数据加载失败，请稍后重试",
            "error_not_found": "未找到对应数据，请返回后重试",
            "error_invalid_data": "本地数据异常，请稍后重试",
            "about_tally": "关于 Tally",
            "local_single_currency": "单币种本地记账",
            "version": "版本",
            "data_scope": "数据范围",
            "data_scope_value": "账单、分类、定时记账、Widget 快照",
            "privacy_policy": "隐私政策",
            "local_by_default": "默认留在本机",
            "local_by_default_detail": "账单、分类、偏好设置和头像保存在本机；Widget 仅读取 App Group 中的摘要快照。",
            "no_network_analytics": "不做联网分析",
            "no_network_analytics_detail": "当前版本没有第三方分析、广告追踪或远程账号同步。",
            "notification_opt_in": "通知按需开启",
            "notification_opt_in_detail": "每日提醒只在你手动开启后申请系统通知权限。",
            "data_backup": "数据与备份",
            "manual_import_export": "手动导入导出",
            "manual_import_export_detail": "你可以在“导入与导出”中生成 CSV 或 JSON 备份文件。",
            "avatar_selection": "头像选择",
            "avatar_selection_detail": "账号头像来自系统照片选择器，图片数据只用于本机展示。",
            "support": "支持",
            "report_issue": "反馈问题",
            "report_issue_detail": "通过邮件向 hey@wangyun.fan 反馈问题和建议",
            "feedback_email_unavailable_title": "邮件尚未设置",
            "feedback_email_unavailable_detail": "复制 hey@wangyun.fan，然后在邮件应用里发送反馈。",
            "copy_email": "复制邮箱",
            "acknowledgements": "致谢",
            "apple_platforms": "Apple 平台技术",
            "apple_platforms_detail": "Tally 使用 SwiftUI、Core Data 与 WidgetKit 构建。",
            "current_data": "当前数据",
            "records_unit": "条记录",
            "export_scope": "导出范围",
            "recent_records": "最近记录",
            "no_import_export_logs": "还没有导入导出记录。",
            "export_csv": "导出 CSV",
            "export_csv_subtitle": "用于表格分析与二次处理",
            "export_backup_json": "导出备份 JSON",
            "export_backup_json_subtitle": "完整备份账单与类别数据",
            "import_backup": "导入备份",
            "import_backup_subtitle": "从备份文件恢复数据",
            "import_csv": "导入 CSV",
            "import_csv_subtitle": "从标准 CSV 导入账单",
            "import_preflight": "导入预检",
            "confirm_import": "确认导入",
            "import_result": "导入结果",
            "import_export_empty_range": "还没有记录跨度。",
            "import_export_range_subtitle": "跨度 %@ - %@ · %d 天",
            "import_pending_count": "可导入：%d",
            "import_conflict_count": "冲突：%d",
            "import_failed_count": "失败：%d",
            "import_success_count": "成功：%d",
            "import_skipped_count": "跳过：%d",
            "import_error_summary": "错误摘要：",
            "export_generated_with_size": "已生成%@（%d条，%@）",
            "export_generated": "已生成%@（%d条）",
            "feature_in_development": "%@功能开发中",
            "action_failed_try_later": "%@失败，请稍后重试",
            "import_export_log_meta": "%@ · %@ · %d 条 · %d 错误",
            "count_error_unit": "%d 错误",
            "current_month": "当前月",
            "all_records": "全部",
            "theme_title": "主题与外观",
            "icon_switch_unavailable": "图标暂时无法切换",
            "preview_current_month": "预览 · 本月",
            "preview_quick_entry": "预览记一笔",
            "appearance_skin": "皮肤",
            "signature_color": "SIGNATURE 色",
            "accent_usage_hint": "FAB · 收入 · 强调",
            "app_icon": "APP 图标",
            "app_icon_trailing": "点选后同步主屏图标",
            "details": "细节",
            "reduce_motion": "减少动效",
            "reduce_motion_subtitle": "关闭弹簧与过渡",
            "haptic_feedback": "触感反馈",
            "haptic_feedback_subtitle": "记一笔与拨号盘时轻触",
            "reset_default_format": "恢复默认 · %@ %@",
            "appearance_dark_title": "夜",
            "appearance_light_title": "昼",
            "appearance_system_title": "跟随",
            "appearance_dark_subtitle": "墨色",
            "appearance_light_subtitle": "月白",
            "appearance_system_subtitle": "系统",
            "appearance_dark_profile": "深色",
            "appearance_light_profile": "浅色",
            "appearance_system_profile": "跟随系统",
            "app_icon_vermilion": "朱砂",
            "app_icon_moon": "月白",
            "app_icon_ink": "墨笔",
            "app_icon_ink_note": "砚台",
            "accent_vermilion": "朱砂",
            "accent_red_ochre": "赭石",
            "accent_pine": "松绿",
            "accent_brass": "黄铜",
            "accent_wisteria": "紫藤",
            "accent_moon": "月白",
            "widget_intro_title": "两种桌面入口",
            "widget_intro_subtitle": "一个负责快速记账，一个负责扫一眼本月趋势。",
            "widget_quick_entry_title": "今日入口",
            "widget_quick_entry_subtitle": "轻触后打开记一笔",
            "widget_summary_title": "月度趋势",
            "widget_summary_subtitle": "轻触后回到账本首页",
            "widget_add_path": "添加路径",
            "widget_home_screen": "主屏幕",
            "widget_step_hold": "长按桌面空白处",
            "widget_step_hold_detail": "进入主屏幕编辑",
            "widget_step_plus": "点击左上角 +",
            "widget_step_plus_detail": "搜索 Tally",
            "widget_step_size": "选择尺寸",
            "widget_step_size_detail": "Small 或 Medium",
            "widget_count_unit": "款",
            "quick_entry_widget_name": "快速记账",
            "quick_entry_widget_description": "查看今日支出并快速记账",
            "summary_trend_widget_name": "本月概览",
            "summary_trend_widget_description": "查看本月结余与趋势",
            "no_recurring_bills": "还没有定时账单。",
            "pause": "暂停",
            "enable": "启用",
            "enabled_paused_summary": "已启用 %d 条 · 暂停 %d 条",
            "next_fire_format": "下次 %@",
            "recurring_load_failed": "定时账单加载失败，请稍后重试",
            "recurring_enable_failed": "启用定时账单失败，请稍后重试",
            "recurring_pause_failed": "暂停定时账单失败，请稍后重试",
            "recurring_delete_failed": "删除定时账单失败，请稍后重试",
            "recurring_save_failed": "保存定时账单失败，请稍后重试",
            "repeat_daily": "每日",
            "repeat_weekly": "每周",
            "repeat_monthly_first": "月初",
            "repeat_monthly_last": "月末",
            "repeat_rule_daily_title": "每天",
            "repeat_rule_weekly_monday_title": "每周（周一）",
            "repeat_rule_weekly_sunday_title": "每周（周日）",
            "repeat_rule_monthly_first_title": "每月（月初）",
            "repeat_rule_monthly_last_title": "每月（月末）",
            "category_load_failed": "分类加载失败，请稍后重试",
            "select_category": "请选择分类",
            "amount_positive_required": "金额需大于 0",
            "amount_invalid": "金额输入有误",
            "bill_save_failed": "保存账单失败，请稍后重试",
            "first_fire_must_be_future": "首次执行时间必须晚于当前时间",
            "optional": "选填",
            "choose_time": "选择时间",
            "next_trigger": "下次触发",
            "change_avatar": "更换头像",
            "use_default_avatar": "使用 App 图标",
            "avatar_update_failed": "头像更新失败，请稍后重试",
            "name": "名称",
            "enter_name": "输入名称",
            "edit_category": "编辑分类",
            "category_name": "分类名称",
            "color": "颜色",
            "icon": "图标",
            "category_limit_message": "最多新增 %d 个分类",
            "category_name_empty": "分类名称不能为空",
            "category_name_exists": "分类名称已存在",
            "category_not_found": "未找到分类",
            "system_category_edit_forbidden": "系统分类不可编辑",
            "system_category_delete_forbidden": "系统分类不可删除",
            "category_create_failed": "新增分类失败，请稍后重试",
            "category_update_failed": "更新分类失败，请稍后重试",
            "category_delete_failed": "删除分类失败，请稍后重试",
            "category_order_save_failed": "保存分类排序失败，请稍后重试"
        ]
    ]

    private static let fallbackTextByLanguage: [String: [String: String]] = [
        "en": [
            L10nKey.about.rawValue: "About",
            L10nKey.accountSettings.rawValue: "Account",
            L10nKey.appLanguage.rawValue: "App Language",
            L10nKey.applicationLanguage.rawValue: "Application Language",
            L10nKey.amount.rawValue: "Amount",
            L10nKey.averageDaily.rawValue: "Daily Avg",
            L10nKey.balance.rawValue: "Balance",
            L10nKey.bills.rawValue: "Bills",
            L10nKey.billCount.rawValue: "%d entries",
            L10nKey.billLoadFailed.rawValue: "Bills could not be loaded. Please try again later.",
            L10nKey.billDeleteFailed.rawValue: "Failed to delete the bill. Please try again later.",
            L10nKey.billRecordedDays.rawValue: "%d days tracked",
            L10nKey.cancel.rawValue: "Cancel",
            L10nKey.categories.rawValue: "Categories",
            L10nKey.categoryRanking.rawValue: "Category Ranking",
            L10nKey.categoryCountSummary.rawValue: "%d categories · View all",
            L10nKey.continueAction.rawValue: "Continue",
            L10nKey.date.rawValue: "Date",
            L10nKey.dailyReminder.rawValue: "Daily Reminder",
            L10nKey.delete.rawValue: "Delete",
            L10nKey.deleteBill.rawValue: "Delete",
            L10nKey.deleteBillConfirm.rawValue: "Delete this bill?",
            L10nKey.deleteCategoryConfirm.rawValue: "Bills in this category will move to Uncategorized. Continue?",
            L10nKey.detailByDate.rawValue: "By Date · View all",
            L10nKey.detail.rawValue: "Details",
            L10nKey.done.rawValue: "Done",
            L10nKey.enabledRecurringCount.rawValue: "%d enabled",
            L10nKey.entryCount.rawValue: "%d entries",
            L10nKey.expense.rawValue: "Expense",
            L10nKey.expenseDetail.rawValue: "Expense details",
            L10nKey.formatPreview.rawValue: "Format Preview",
            L10nKey.gotIt.rawValue: "OK",
            L10nKey.home.rawValue: "Home",
            L10nKey.importExport.rawValue: "Import & Export",
            L10nKey.income.rawValue: "Income",
            L10nKey.incomeDetail.rawValue: "Income details",
            L10nKey.language.rawValue: "Language",
            L10nKey.languageEnglish.rawValue: "English",
            L10nKey.languageEnglishCode.rawValue: "EN",
            L10nKey.languageEnglishSubtitle.rawValue: "United States",
            L10nKey.languageSimplifiedChinese.rawValue: "Simplified Chinese",
            L10nKey.languageSimplifiedChineseCode.rawValue: "ZH",
            L10nKey.languageSimplifiedChineseSubtitle.rawValue: "Mainland China",
            L10nKey.languageSystem.rawValue: "System",
            L10nKey.languageSystemCode.rawValue: "SYS",
            L10nKey.languageSystemNative.rawValue: "System",
            L10nKey.languageSystemSubtitle.rawValue: "Use device language",
            L10nKey.moneySymbol.rawValue: "Money Symbol",
            L10nKey.moneySymbolDollar.rawValue: "Dollar Symbol",
            L10nKey.moneySymbolDollarSubtitle.rawValue: "Show amounts with $",
            L10nKey.moneySymbolYuan.rawValue: "Yuan Symbol",
            L10nKey.moneySymbolYuanSubtitle.rawValue: "Show amounts with ¥",
            L10nKey.monthlyExpense.rawValue: "Monthly Expense",
            L10nKey.month.rawValue: "Month",
            L10nKey.more.rawValue: "More",
            L10nKey.newCategory.rawValue: "New Category",
            L10nKey.newRecurring.rawValue: "New Recurring",
            L10nKey.noCategoryRecords.rawValue: "No category records.",
            L10nKey.noDetails.rawValue: "No details.",
            L10nKey.noNote.rawValue: "No note",
            L10nKey.note.rawValue: "Note",
            L10nKey.operationIncomplete.rawValue: "Operation Incomplete",
            L10nKey.periodWeekOrdinal.rawValue: "Week %2$d of %1$@",
            L10nKey.profile.rawValue: "Me",
            L10nKey.quickEntry.rawValue: "Add Entry",
            L10nKey.recurring.rawValue: "Recurring",
            L10nKey.recurringRule.rawValue: "Repeat Rule",
            L10nKey.recent7Days.rawValue: "Last 7 Days",
            L10nKey.settings.rawValue: "Settings",
            L10nKey.summaryTotal.rawValue: "Total",
            L10nKey.trendCustom.rawValue: "Period %@",
            L10nKey.trendMonth.rawValue: "Current %@",
            L10nKey.trendWeek.rawValue: "This Week %@",
            L10nKey.trendYear.rawValue: "Full Year %@",
            L10nKey.themeSettings.rawValue: "Theme",
            L10nKey.timeRangeCustom.rawValue: "C",
            L10nKey.timeRangeMonth.rawValue: "M",
            L10nKey.timeRangeWeek.rawValue: "W",
            L10nKey.timeRangeYear.rawValue: "Y",
            L10nKey.today.rawValue: "Today",
            L10nKey.todayShort.rawValue: "Now",
            L10nKey.transactionCount.rawValue: "%d records",
            L10nKey.uncategorized.rawValue: "Uncategorized",
            L10nKey.undoUnavailable.rawValue: "This action cannot be undone.",
            L10nKey.week.rawValue: "This Week",
            L10nKey.widget.rawValue: "Widgets",
            L10nKey.yesterday.rawValue: "Yesterday"
        ],
        "zh-Hans": [
        L10nKey.about.rawValue: "关于",
        L10nKey.accountSettings.rawValue: "账号设置",
        L10nKey.appLanguage.rawValue: "应用语言",
        L10nKey.applicationLanguage.rawValue: "应用语言",
        L10nKey.amount.rawValue: "金额",
        L10nKey.averageDaily.rawValue: "日均",
        L10nKey.balance.rawValue: "结余",
        L10nKey.bills.rawValue: "账本",
        L10nKey.billCount.rawValue: "%d 笔",
        L10nKey.billLoadFailed.rawValue: "账单加载失败，请稍后重试",
        L10nKey.billDeleteFailed.rawValue: "删除账单失败，请稍后重试",
        L10nKey.billRecordedDays.rawValue: "已记 %d 天",
        L10nKey.cancel.rawValue: "取消",
        L10nKey.categories.rawValue: "分类",
        L10nKey.categoryRanking.rawValue: "分类排名",
        L10nKey.categoryCountSummary.rawValue: "共 %d 项 · 看全部",
        L10nKey.continueAction.rawValue: "继续",
        L10nKey.date.rawValue: "日期",
        L10nKey.dailyReminder.rawValue: "每日提醒",
        L10nKey.delete.rawValue: "删除",
        L10nKey.deleteBill.rawValue: "确定删除",
        L10nKey.deleteBillConfirm.rawValue: "确定删除该账单？",
        L10nKey.deleteCategoryConfirm.rawValue: "该类别下所有账单归类到未分类，是否继续？",
        L10nKey.detailByDate.rawValue: "按日期 · 看全部",
        L10nKey.detail.rawValue: "明细",
        L10nKey.done.rawValue: "完成",
        L10nKey.enabledRecurringCount.rawValue: "%d 条已启用",
        L10nKey.entryCount.rawValue: "%d 笔",
        L10nKey.expense.rawValue: "支出",
        L10nKey.expenseDetail.rawValue: "支出明细",
        L10nKey.formatPreview.rawValue: "格式预览",
        L10nKey.gotIt.rawValue: "知道了",
        L10nKey.home.rawValue: "首页",
        L10nKey.importExport.rawValue: "导入导出",
        L10nKey.income.rawValue: "收入",
        L10nKey.incomeDetail.rawValue: "收入明细",
        L10nKey.language.rawValue: "语言",
        L10nKey.languageEnglish.rawValue: "English",
        L10nKey.languageEnglishCode.rawValue: "EN",
        L10nKey.languageEnglishSubtitle.rawValue: "United States",
        L10nKey.languageSimplifiedChinese.rawValue: "简体中文",
        L10nKey.languageSimplifiedChineseCode.rawValue: "简",
        L10nKey.languageSimplifiedChineseSubtitle.rawValue: "中国大陆",
        L10nKey.languageSystem.rawValue: "跟随系统",
        L10nKey.languageSystemCode.rawValue: "系",
        L10nKey.languageSystemNative.rawValue: "System",
        L10nKey.languageSystemSubtitle.rawValue: "使用设备语言",
        L10nKey.moneySymbol.rawValue: "金额符号",
        L10nKey.moneySymbolDollar.rawValue: "美元符号",
        L10nKey.moneySymbolDollarSubtitle.rawValue: "金额前显示 $",
        L10nKey.moneySymbolYuan.rawValue: "人民币符号",
        L10nKey.moneySymbolYuanSubtitle.rawValue: "金额前显示 ¥",
        L10nKey.monthlyExpense.rawValue: "本月支出",
        L10nKey.month.rawValue: "月份",
        L10nKey.more.rawValue: "更多",
        L10nKey.newCategory.rawValue: "新分类",
        L10nKey.newRecurring.rawValue: "新建定时",
        L10nKey.noCategoryRecords.rawValue: "没有分类记录。",
        L10nKey.noDetails.rawValue: "没有明细。",
        L10nKey.noNote.rawValue: "无备注",
        L10nKey.note.rawValue: "备注",
        L10nKey.operationIncomplete.rawValue: "操作未完成",
        L10nKey.periodWeekOrdinal.rawValue: "%1$@第 %2$d 周",
        L10nKey.profile.rawValue: "我",
        L10nKey.quickEntry.rawValue: "记一笔",
        L10nKey.recurring.rawValue: "定时记账",
        L10nKey.recurringRule.rawValue: "重复规则",
        L10nKey.recent7Days.rawValue: "近 7 日",
        L10nKey.settings.rawValue: "通用设置",
        L10nKey.summaryTotal.rawValue: "合计",
        L10nKey.trendCustom.rawValue: "区间%@",
        L10nKey.trendMonth.rawValue: "本期%@",
        L10nKey.trendWeek.rawValue: "本周%@",
        L10nKey.trendYear.rawValue: "全年%@",
        L10nKey.themeSettings.rawValue: "主题设置",
        L10nKey.timeRangeCustom.rawValue: "自定",
        L10nKey.timeRangeMonth.rawValue: "月",
        L10nKey.timeRangeWeek.rawValue: "周",
        L10nKey.timeRangeYear.rawValue: "年",
        L10nKey.today.rawValue: "今天",
        L10nKey.todayShort.rawValue: "今",
        L10nKey.transactionCount.rawValue: "%d 笔记录",
        L10nKey.uncategorized.rawValue: "未分类",
        L10nKey.undoUnavailable.rawValue: "该操作不可撤销",
        L10nKey.week.rawValue: "本周",
        L10nKey.widget.rawValue: "桌面小组件",
            L10nKey.yesterday.rawValue: "昨天"
        ]
    ]
}

enum TallyLanguageStore {
    static let selectedLanguageKey = "language.selected"
    private static let appGroupId = "group.com.langya.Tally"

    static func saveSelectedLanguage(_ rawValue: String) {
        sharedDefaults()?.set(rawValue, forKey: selectedLanguageKey)
    }

    static func loadSelectedLanguage() -> String? {
        sharedDefaults()?.string(forKey: selectedLanguageKey)
    }

    private static func sharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }
}
