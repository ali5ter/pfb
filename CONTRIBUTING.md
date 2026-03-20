# Contributing to pfb

Thank you for your interest in contributing to pfb. This document describes how to get started and
what to keep in mind when submitting changes.

## Getting Started

1. Fork the repository on GitHub: <https://github.com/ali5ter/pfb>
2. Clone your fork locally
3. Create a feature branch from `main`: `git checkout -b feat/your-feature`
4. Make your changes
5. Test with the interactive demo: `source ./pfb.sh && pfb test`
6. Push your branch and open a pull request

## Development Workflow

### Testing

Run the interactive demo to verify all components work correctly:

```bash
source ./pfb.sh && pfb test
```

This showcases all pfb features including all 18 spinner styles. There is no automated test runner;
the interactive demo is the primary verification mechanism.

### Generating Example GIFs

pfb uses [vhs](https://github.com/charmbracelet/vhs) for terminal recordings in `examples/`.
Always use `run_vhs.sh` — never call `vhs` directly:

```bash
cd examples
./run_vhs.sh select.tape   # Regenerate a single GIF
./run_vhs.sh               # Regenerate all GIFs
```

The `run_vhs.sh` script unsets `PROMPT_COMMAND` before invoking vhs, which prevents shell prompt
hooks (e.g. starship) from producing errors inside recordings.

### Reviewing GIF Output

Do not rely on reading a GIF directly — only the first frame is visible. Use ffmpeg to extract a
frame near the end for visual review:

```bash
count=$(ffprobe -v error -select_streams v:0 -count_frames \
  -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 file.gif 2>/dev/null)
ffmpeg -y -i file.gif -vf "select=eq(n\,$((count * 95 / 100))),scale=1024:-1" \
  -frames:v 1 /tmp/review.png 2>/dev/null
```

## Code Guidelines

pfb is a single-file Bash library (`pfb.sh`). All contributions must:

- Maintain the single-file design constraint — no additional runtime files
- Work on Bash 4.0+ with zero external dependencies (standard UNIX utilities only)
- Follow the function namespace convention: internal functions use a `_` prefix
- Keep interactive UI (prompts, spinners) writing to **stderr**; return values via **stdout**
- Never call `_pfb_set_ansi_vars` inside `pfb()` — it must run only once at source time
- Maintain backward compatibility: existing public commands must continue to work

### Architectural Principles

- **stdout for results, stderr for interactive UI** — `pfb select`, `pfb input`, and `pfb confirm`
  write prompts to stderr so `result=$(pfb command)` capture patterns work correctly
- **Absolute spinner row positioning** — use `get_cursor_row` before launching background processes;
  background loops must use `cursor_to "$row"` for absolute positioning, not relative movement
- **Source-time ANSI init** — `_pfb_set_ansi_vars` must not be called inside a subshell context

Refer to `CLAUDE.md` for a detailed architectural overview.

## Pull Request Guidelines

- Keep PRs focused — one feature or fix per PR
- Update `CHANGELOG.md` with a brief description of your change under an `[Unreleased]` heading
- If you add a new public command, document it in `README.md`
- If you change spinner behavior or interactive UI, regenerate the affected GIFs

## Reporting Issues

Open an issue on GitHub: <https://github.com/ali5ter/pfb/issues>

Please include:

- A minimal reproduction script
- Your Bash version (`bash --version`)
- Your OS and terminal emulator
- Whether you are using `NO_COLOR` or `PFB_NON_INTERACTIVE`

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
