# Tally

Tally 是一个 iOS / iPadOS 单币种记账 App，使用 SwiftUI、Core Data 和 WidgetKit 构建。

改代码前先读 [AGENTS.md](AGENTS.md)、[CLAUDE.md](CLAUDE.md) 和 [Tally/Core/ArchitectureRules.md](Tally/Core/ArchitectureRules.md)。

本地构建：

```bash
xcodebuild -project Tally.xcodeproj -scheme Tally \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
