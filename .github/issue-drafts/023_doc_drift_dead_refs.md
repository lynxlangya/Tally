# [P2] 修复文档断链：AGENTS / CLAUDE / README 指向已删文件

> 关联：上线前只读扫描 P2-3 · 建议分支 `issue/023-doc-drift` · 工作量 S
> 范围：`AGENTS.md` / `CLAUDE.md` / `README.md`（文档，无代码）。
> 性质：需先决策"删引用 vs 恢复文件"，再执行。

## 背景 / Why

项目根的规则/说明文档反复引用一批发布流程文件，但它们已不在工作区——在 commit `ecf9ff8 chore: clean legacy artifacts` 被删除，且**未**被 gitignore。结果：新协作者（含 codex / claude）按文档去读这些文件会扑空，发布自查也无据可依。

## 证据 / Evidence

被引用但缺失的路径：`loadmap.md`、`Tasks/`（含 `Tasks/21_Release_risk_cleanup.md`）、`review/`、`bugs/`、`app_store_submission_checklist_20260207.md`、`project_deep_review_20260207.md`。

- 引用位置：[AGENTS.md:64-68](../../AGENTS.md)、[CLAUDE.md](../../CLAUDE.md)（"任务与 Review 流程"段）、[README.md:54-70](../../README.md)（目录结构里的 `Tasks/` `review/`）。
- 缺失确认：
  ```bash
  ls loadmap.md Tasks/ review/ bugs/ app_store_submission_checklist_20260207.md 2>&1   # No such file
  git check-ignore loadmap.md Tasks/ 2>&1 || echo "未被 ignore，纯属删除"
  git log --oneline --all -- loadmap.md "Tasks/*" app_store_submission_checklist_20260207.md   # 可见历史
  ```

## 决策点 / codex 先判断

- 这些文件是**该删**（流程已废弃）→ 走方案 A；还是**误删**（发布清单仍需要）→ 走方案 B？
- 关键参考：删除它们的 commit `ecf9ff8` 的意图（"clean legacy artifacts ahead of UI / architecture refactor"）。

## 修复 / Do（择一）

- 方案 A（文档收口，推荐若流程确废弃）：从 `AGENTS.md` / `CLAUDE.md` / `README.md` 删除/改写对这些路径的引用，使文档与现状一致（保留 `.gemini/skills/task-code-review/SKILL.md` 等仍存在的引用）。
- 方案 B（恢复清单，若仍要用）：`git show ecf9ff8~1:app_store_submission_checklist_20260207.md` 取回需要的文件，再让文档引用成立。

## 验收 / Done when

- [ ] 三份文档中不再有指向不存在文件的链接/路径（或被引用文件已恢复）
- [ ] `grep -rnoE "loadmap\.md|Tasks/|review/|bugs/|app_store_submission_checklist|project_deep_review" AGENTS.md CLAUDE.md README.md` 的每条命中都能对应到真实存在的路径
- [ ] PR 写明选了 A 还是 B 及理由

## Don't

- 不动这三份文档里仍然正确的内容（架构规则、命令、口径）。
- 不顺手改其他无关文档。
