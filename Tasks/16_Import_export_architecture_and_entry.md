# 16 导入导出：架构与入口（基础任务）

## 目标

- 在个人中心增加「导入导出」入口与页面骨架，建立后续可扩展的导入/导出架构。
- 明确导入导出的统一模型与服务边界，避免业务逻辑散落在 View 层。
- 先打通“页面可进入 + 动作可触发 + 占位反馈”闭环，不引入真实导入写库逻辑。

## 开发步骤

1. 页面入口与导航
   - 在个人中心设置区域新增「导入导出」入口。
   - 新建页面：`Features/Settings/ImportExportView.swift`。
   - 页面包含 4 个主动作入口：
     - 导出 CSV
     - 导出备份（JSON）
     - 导入备份（JSON）
     - 导入 CSV

2. 服务协议与模型
   - 新建目录：`Core/Services/ImportExport/`
   - 新建协议：
     - `ImportExportService`
   - 新建基础模型（先定义不实现完整逻辑）：
     - `ExportRequest`（范围、类型）
     - `ExportResult`（文件 URL、记录数）
     - `ImportPreview`（待导入条数、失败条数、错误摘要）
     - `ImportResult`（成功/跳过/失败）

3. 依赖注入
   - 在 `AppEnvironment/DIContainer` 中注册 `ImportExportService`。
   - ViewModel 只依赖协议，不直接依赖 CoreData。

4. 交互骨架
   - 4 个按钮先接 ViewModel 方法，给出统一轻提示（例如“功能开发中”或“下一步可用”）。
   - 使用统一页面样式（暗色主题 + 现有组件）。

5. 边界与约束声明（代码注释 + 任务文档）
   - 金额口径：CNY，2 位小数，导入时禁止负数。
   - 时间口径：按 `occurredAtUTC + occurredLocalDate`，避免跨时区分组漂移。

## 验收标准

- ✅ 个人中心可进入导入导出页面。
- ✅ 页面有 4 个明确动作入口，交互反馈正常。
- ✅ 服务协议、模型、DI 已建立，后续任务可直接扩展。
- ✅ View/ViewModel 未直接访问 CoreData 细节，架构边界符合项目规范。

