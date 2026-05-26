# Tally App Store 提交前置条件清单（2026-02-07）

## A. 账号与证书（必须）
- [ ] Apple Developer Program 处于有效状态。
- [ ] App Store Connect 已创建 App 记录（Bundle ID: `com.langya.Tally`）。
- [ ] Distribution 证书可用（建议使用 Automatic Signing + Xcode Managed Profiles）。
- [ ] App Target 与 Widget Target 的签名和 Team 一致。
- [ ] App Group `group.com.langya.Tally` 在 Apple Developer 后台已启用并绑定到两个 Target 的 App ID。

## B. 工程与合规（必须）
- [x] Release 构建可通过（本地已验证）。
- [x] 深链 URL Scheme 已配置（`tally`）。
- [x] 隐私清单文件已添加：`Shared/PrivacyInfo.xcprivacy`。
- [ ] 在 Archive（真机签名）模式下执行 `Validate App` 并通过。
- [ ] Export Compliance（加密合规）在 App Store Connect 回答完成。
- [ ] 若需要，设置 `ITSAppUsesNonExemptEncryption`（或在 ASC 中选择对应加密选项）。

## C. 隐私与权限（必须）
- [ ] App Store Connect -> App Privacy 问卷已完整填写。
- [ ] 隐私政策 URL 已提供且可公开访问。
- [ ] 仅声明实际使用的数据收集/跟踪项，不多报。
- [ ] 检查通知权限触发路径（首次请求时机与文案是否符合预期）。

## D. 元数据（必须）
- [ ] 应用名称、副标题、关键词完成并通过商标风险自检。
- [ ] 描述、更新说明（What’s New）完成。
- [ ] 年龄分级问卷完成。
- [ ] 各设备尺寸截图上传完整（iPhone 必需；若支持 iPad 需补 iPad 截图）。
- [ ] 联系信息、版权信息、审核备注填写完整。

## E. 发布前质量门禁（强烈建议）
- [ ] 执行单测：`TallyTests` 全量通过。
- [ ] 真机回归：新增账单、编辑账单、分类编辑、定时记账补跑、Widget 跳转。
- [ ] 离线/重启场景验证（CoreData 数据一致性）。
- [ ] 跨时区编辑回归验证（日期口径不漂移）。
- [ ] Widget 数据刷新时延与显示一致性检查。
- [ ] 崩溃日志/关键日志可观测性确认。

## F. 提交流程（执行顺序）
1. Xcode `Product -> Archive`（Release + 真机签名）。
2. Organizer 中 `Validate App`。
3. 上传构建到 App Store Connect。
4. 在 ASC 绑定该构建，完成 Metadata + App Privacy + Export Compliance。
5. 提交审核，跟进审核反馈。

## 当前状态结论
- 代码层面主阻断已清除：深链、定时记账闭环、时间口径、最小测试基线。
- 仍需你在 Apple 平台侧完成：签名归档验证、隐私问卷、加密合规与商店元数据。
