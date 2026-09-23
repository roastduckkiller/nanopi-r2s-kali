# Optional Pi agent on the R2S / 可选 Pi agent

The board runs Node and tool execution. Model inference belongs on a remote server
(e.g. DGX Spark, another workstation or a hosted endpoint). A 1 GB R2S is not the
machine to run the 27B model itself.

## Install

On the flashed board, as `pi`, without sudo:

```sh
bash scripts/install-pi.sh
export PATH="$HOME/.local/bin:$PATH"
node --version
pi --version
```

Pinned versions: Node **24.21.0 ARM64**, Pi **0.87.1**
(`@earendil-works/pi-coding-agent`). The installer checks Node's downloaded archive
against the HTTPS-published `SHASUMS256.txt`; it does not verify the detached GPG
signature. npm installs with lifecycle scripts disabled. It refuses to overwrite
an existing local Node/Pi installation. Add `~/.local/bin` to your login PATH if
your shell does not do so already. Python must support tarfile's `data` filter
(the tested Kali Python 3.14 does).

## Connect your own model

Copy the examples only if you do not already have Pi configuration:

```sh
install -d -m 700 "$HOME/.pi/agent"
cp -n examples/models.json examples/settings.json "$HOME/.pi/agent/"
chmod 600 "$HOME/.pi/agent/"*.json
```

Edit `models.json`: replace `MODEL-SERVER`, port and `YOUR-MODEL-ID` with your
actual endpoint and model ID. Also change `defaultModel` in `settings.json`.
Match `contextWindow` and `maxTokens` to the server configuration; the example
64K/8K values do not increase server capacity. Cost fields are placeholders for
an unmetered local server, not price claims. The model needs reliable tool calling.

The `apiKey` uses Pi's `${PI_API_KEY}` interpolation. To keep the value out of shell
history, in Bash:

```sh
read -rs -p 'Model API key: ' PI_API_KEY; echo
export PI_API_KEY
pi
```

For an endpoint with no authentication, use a dummy value if required by Pi.
Use `tmux new -As agent` first if you want the agent to survive an SSH disconnect;
set/export the API key inside the tmux shell. Do not commit credentials or your
live Pi configuration to GitHub.

## Check tools, not just chat

Create a small file containing a marker of your choice. Ask Pi to read that file
with its `read` tool, run `uname -m` using `bash`, and report both outputs. Inspect
the tool results. This tests the full board → model → tool → model loop.

Our original setup completed both calls in about 16 seconds with peak process
RSS about 146 MiB (one test, one model/backend; not a general benchmark). Keep
concurrency low and avoid feeding huge captures/build logs into a 1 GB machine.
The second Ethernet port is independently configurable; no scanning or routing
is automatically enabled by this project.

中文提示：先装 Node/Pi，再填你自己的模型地址和模型 ID。API 密钥通过环境变量传入；
示例的上下文长度必须与服务器一致。建议只运行一个 agent，推理放在远端。

References: [Pi](https://pi.dev/),
[Node ARM64 releases](https://nodejs.org/dist/v24.21.0/).
