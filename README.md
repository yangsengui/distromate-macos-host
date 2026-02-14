# distromate-macos-host

这个仓库只用于创建 GitHub Actions 的 macOS 主机（tmate 会话），不存放 distromate-cli 源码。

## 安全规则

- 不要把 `distromate-cli` 源码提交到这个公开仓库。
- 仅允许上传 `libs/mac-squirrel-agent` 目录，其他私有代码一律不上传。
- tmate 使用 `limit-access-to-actor: true`，仅允许触发工作流的账号 SSH key 连接。

## 使用方法

1. 打开 Actions，手动运行 `macOS Host (tmate)`。
2. 选择 macOS 版本和会话超时。
3. 在日志里复制 SSH 命令连接到 tmate。
4. 在会话里手动执行你的打包和测试命令。

## 本地组装后 push

1. 在本地只复制 `libs/mac-squirrel-agent` 到这个公开仓库。
2. 检查 `git status`，确认不存在其他私有目录或文件。
3. 提交并 push。

这样仓库里只有 `mac_squirrel_agent` 相关文件，不会上传你的其他代码。

## 在 Actions 编译 `mac_squirrel_agent`

1. 手动运行 `Build mac_squirrel_agent (macOS)` 工作流。
2. 选择 macOS runner 和依赖版本。
3. 构建成功后，在 Artifacts 下载 `mac-squirrel-agent-*` 二进制。

## 提示

- 如果需要拉取私有代码，请在 tmate 会话中使用你自己的凭据，不要把凭据写进仓库文件。
- 测试结束后及时退出会话，减少资源占用和暴露窗口。
