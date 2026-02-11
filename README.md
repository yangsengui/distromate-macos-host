# distromate-macos-host

这个仓库只用于创建 GitHub Actions 的 macOS 主机（tmate 会话），不存放 distromate-cli 源码。

## 安全规则

- 不要把 `distromate-cli` 源码提交到这个公开仓库。
- 工作流不执行 `actions/checkout`，避免拉取任何业务代码。
- tmate 使用 `limit-access-to-actor: true`，仅允许触发工作流的账号 SSH key 连接。

## 使用方法

1. 打开 Actions，手动运行 `macOS Host (tmate)`。
2. 选择 macOS 版本和会话超时。
3. 在日志里复制 SSH 命令连接到 tmate。
4. 在会话里手动执行你的打包和测试命令。

## `Verify distromate package (macOS)` 签名校验模式

`macos-package-verify.yml` 支持两种签名校验：

- `production_signature_checks`: 启用后会执行 Developer ID 证书链校验 + `spctl` 信任评估。
- `self_signed_signature_checks`: 启用后使用 ad-hoc（自签）方式做签名完整性校验（不需要 secrets）。
- `expected_team_id`: 可选，建议填写你的 Team ID（例如 `ABCDE12345`），用于强约束签名主体。
- `require_notarization`: 启用后会对生成 DMG 执行 notarization 提交、staple、`spctl --type open` 校验。

`self_signed_signature_checks=true` 时，会额外执行：

- 对生成的 DMG 做 ad-hoc 签名并校验。
- 校验 `distromate package` 日志中的“更新前/更新后签名校验通过”关键信息。
- 校验更新流程“全量DMG自动更新、拉起与签名校验测试通过”关键日志。

说明：

- 自签模式验证的是“签名存在且更新后仍然正确”，不是 Apple 信任链。
- 如果同时开启 `production_signature_checks` 和 `self_signed_signature_checks`，以生产级校验为主。

启用 `production_signature_checks=true` 时，必须配置以下 Secrets：

- `MACOS_CODESIGN_P12_BASE64`: Developer ID 证书（`.p12`）的 base64 内容。
- `MACOS_CODESIGN_P12_PASSWORD`: `.p12` 导出密码。
- `MACOS_CODESIGN_IDENTITY`: 签名身份全名（例如 `Developer ID Application: Your Name (TEAMID)`）。

启用 `require_notarization=true` 时，还需要：

- `MACOS_NOTARY_APPLE_ID`
- `MACOS_NOTARY_TEAM_ID`
- `MACOS_NOTARY_APP_PASSWORD`

通用说明：

- 工作流仍然不 checkout 业务源码，也不会把私有源码上传到公开仓库。
- 生产级模式会额外校验下载的 `distromate` 二进制签名（拒绝 ad-hoc 签名）。
- notarization 步骤会增加执行时间，请按需开启。

## 提示

- 如果需要拉取私有代码，请在 tmate 会话中使用你自己的凭据，不要把凭据写进仓库文件。
- 测试结束后及时退出会话，减少资源占用和暴露窗口。
