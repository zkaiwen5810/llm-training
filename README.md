# LLM training

A small Python 3.12 / PyTorch CPU workspace for learning tensors, autograd, and language-model training. PyTorch 2.9.1+cpu is a verified available CPU release, not a claim to the latest release. The repository includes a locked environment and a basic training smoke check; it does not download datasets or model weights.

## Start

1. Start Docker Desktop using Linux containers.
2. Open this repository in VS Code with the Dev Containers extension.
3. Run **Dev Containers: Reopen in Container**.
4. In the container terminal, run:

   ```bash
   bash .devcontainer/setup.sh
   ```

The separate setup step downloads PyTorch and notebook dependencies and uses `uv sync --locked`. Later runs reuse the environment and download cache. Select `/opt/venv/bin/python` as the Python interpreter or notebook kernel. Run the smoke check again with:

```bash
uv run --locked python examples/smoke.py
```

Start learning with tensors and gradients, then tokenization, embeddings, causal attention, and a small character-level transformer. CPU is suitable for small educational experiments; large-model training requires a different GPU configuration.

## Downloads and rebuilds

- Debian packages: Tsinghua TUNA Debian and Debian security mirrors over HTTPS, with signature verification retained.
- Python packages: [TUNA PyPI](https://mirrors.tuna.tsinghua.edu.cn/help/pypi/).
- npm packages, including the AI Feature: [npmmirror](https://npmmirror.com/).
- CPU PyTorch: [official CPU index](https://download.pytorch.org/whl/cpu). No suitable mainland CPU-wheel mirror was verified, so torch deliberately uses this explicit upstream index. Other Python dependencies use TUNA.
- Container images and the AI Feature use their upstream registries; this configuration does not alter Docker's global registry settings.

Only `.devcontainer/Dockerfile` enters the image build context. Source edits and Python dependency edits do not invalidate stable image layers. uv 0.13.0 is copied from its official prebuilt image. The required [ai-coding-cli Feature](https://github.com/zkaiwen5810/devcontainer-features/tree/main/src/ai-coding-cli) is pinned to 0.2.7; its apt/npm installer manages its own downloads and does not expose BuildKit cache options. Its installed CLI versions are not pinned by the Feature.

Update dependencies intentionally with `uv lock`, review and commit `uv.lock`, then run setup again. The Python version range and lock target Python 3.12.

## Persistent storage

The local checkout is bind-mounted at `/workspaces/llm-training`. Python packages live in the project-specific `llm-training-py312-venv` volume at `/opt/venv`. uv downloads use `uv-cache` at `/home/vscode/.cache/uv` (`uv cache dir` shows the effective location).

AI state uses the same explicit volume names as other containers on this Docker daemon:

| Volume | Container directory |
| --- | --- |
| `codex-home` | `/home/vscode/.codex` |
| `claude-home` | `/home/vscode/.claude` |
| `claude-code-persist` | `/home/vscode/.persist` |
| `opencode-config` | `/home/vscode/.config/opencode` |
| `opencode-share` | `/home/vscode/.local/share/opencode` |

Claude's `~/.claude.json` is symlinked to a file in `.persist`; migration preserves existing content and backs up replaced files or symlinks. No credentials are stored in the repository or image. Volumes persist across rebuilds on the same Docker daemon; they do not synchronize between hosts.

The container fixes `vscode` to UID:GID 1000:1000 and disables host UID remapping to match shared containers. Before readiness and on each start, `prepare.sh` repairs root-owned entries in the declared volumes, including descendants, checks writes as `vscode`, and rejects incompatible non-root owners. It checks the host workspace without recursively changing its ownership. On native Linux, ensure the bind mount is writable by UID 1000 or choose an agreed identity across all containers sharing these volumes.

## Codex sandbox

The Linux image installs Debian's `bubblewrap`. Docker's default seccomp profile blocks the namespace operations used by Codex on this Docker Desktop host, so this container specifies `--security-opt seccomp=unconfined`. This relaxes the outer Docker syscall filter; Codex still applies its own filesystem and network sandbox. It does not require privileged mode or extra capabilities on the tested host.

Use `codex` normally. Container readiness runs `.devcontainer/check-sandbox.sh` as `vscode`, verifying workspace writes succeed while writes outside the workspace and network access fail. The check uses temporary Codex configuration so shared preferences cannot bypass it; it does not change your shared Codex settings. It needs no model request or login.

After changing the container configuration, run **Dev Containers: Rebuild Container**. To repeat the check inside the container:

```bash
bash .devcontainer/check-sandbox.sh
```

The `claude-code-2_1_88` reference also has an explicit `codex-dfa` launcher that disables the inner sandbox. This repository fixes normal sandbox execution instead. See [OpenAI sandbox documentation](https://learn.chatgpt.com/docs/sandboxing) for the distinction between sandboxing and approvals.
