#!/bin/zsh
# ─────────────────────────────────────────────────────────────────────────────
# 환경점검 — 맥에서 「스킬·에이전트를 만들고 고칠 수 있는 상태」인지 재고 안내서를 만든다
#
#   쓰는 법:  ⭐ **같은 폴더의 `맥에서_두번누르기.command`를 두 번 누르십시오.** 그게 이 파일을 부릅니다.
#            (터미널을 쓰시는 분은 이 폴더에서  zsh 환경점검.sh )
#            🚫 경로를 타이핑하게 만들지 않는다 — 이 파일은 자기가 있는 폴더를 스스로 찾는다.
#   나오는 것: 같은 폴더에 `환경점검_결과.html` (자동으로 열립니다)
#
# ⭐ 왜 셸인가 — 이 점검기를 파이썬으로 만들면 **파이썬이 없을 때 못 돈다.**
#    없는 것을 알려 주려는 도구가 그 없음 때문에 죽으면 안 된다. zsh는 맥에 항상 있다.
#
# ⚠️ 변수·함수 이름만 영문이다 — **셸은 한글 이름을 못 쓴다**(파이썬과 다르다).
#    사람이 읽는 글은 전부 한글이다.
# ⚠️ 글자 다루기·찍기는 **zsh 붙박이 기능만** 쓴다(sed·cat을 부르지 않는다).
#    실사고 2026-09-08: 바깥 명령을 많이 부르는 판이 중간에 「명령을 찾을 수 없다」로 끊겼다.
#
# 🚫 토큰·비밀번호·계정 값을 절대 읽거나 찍지 않는다. **이름이 있나/없나만** 본다.
# 🚫 아무것도 설치하지 않는다. 재기만 한다. 무엇을 어떻게 깔지는 사람이 고른다.
# ─────────────────────────────────────────────────────────────────────────────
set -u
HERE="${0:A:h}"
OUT="$HERE/환경점검_결과.html"

# ⭐ 인텔 맥이냐 — 설치 방법이 통째로 갈린다 (2026-09-22 신설)
#    Homebrew 7.0.0(2026-09-13)이 인텔 x86_64를 3등급으로 내렸다. 미리 빌드된 바이너리를
#    더 이상 갱신하지 않아서 `brew install`이 소스 컴파일로 넘어가거나(몇 시간)
#    「no bottle available」로 실패한다. 실제 배포에서 이 벽에 막혔다.
#    ⚠️ 로제타로 돌면 uname이 x86_64라고 거짓말한다 — proc_translated로 걸러 낸다.
ARCH="$(uname -m)"
INTEL=0
if [[ "$ARCH" == "x86_64" && "$(sysctl -n sysctl.proc_translated 2>/dev/null)" != "1" ]]; then
  INTEL=1
fi
# 🙋 인텔 맥이 없어도 인텔용 안내서를 미리 볼 수 있게 한다 — 보내기 전에 확인하는 용도다.
#    터미널에서  FORCE_INTEL=1 zsh 환경점검.sh  로 돌리면 인텔 판이 나온다.
#    🚫 재는 대상(무엇이 깔려 있나)은 이 컴퓨터 그대로다. 바뀌는 것은 **설치 안내 문구**뿐이다.
[[ "${FORCE_INTEL:-}" == "1" ]] && INTEL=1
BUF=""              # 만들 HTML을 여기 모은다 (붙박이 문자열 이어붙이기)
MISSING=0
ROWS=()             # "갈래|이름|상태|찾은것|왜|어떻게" — 구분자는 개행 없는 |

w()   { BUF="${BUF}$1
"; }
esc() { local s="$1"; s="${s//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; print -r -- "$s"; }
have(){ command -v "$1" >/dev/null 2>&1 }

row() {   # row <갈래> <이름> <상태> <찾은것> <왜> <어떻게>
  ROWS+=("$1|$2|$3|$4|$5|$6")
  [[ "$1" == "필수" && "$3" == "없음" ]] && MISSING=$((MISSING + 1))
  return 0
}

probe() { # probe <갈래> <이름> <명령> <버전인자> <왜> <어떻게>
  local found state
  if have "$3"; then
    found="${$("$3" ${=4} 2>&1)[(f)1]}"
    state="있음"
  else
    found="찾지 못했습니다"; state="없음"
  fi
  row "$1" "$2" "$state" "$found" "$5" "$6"
}

# ═══ ⓪ 설치 방법을 아키텍처별로 정해 둔다 ══════════════════════════════════
# 🚫 각 항목에서 if를 치지 않는다 — 한 자리에 모아 두어야 다음에 고칠 때 빠뜨리지 않는다.
WHY_BREW='맥에서 아래 것들을 깔아 주는 손입니다. 이것부터 있어야 나머지가 한 줄로 깔립니다'
HOW_BREW='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

if (( INTEL )); then
  WHY_BREW='🙋 인텔 맥이라 이 점검은 Homebrew를 쓰지 않는 길로 안내합니다. 없어도 괜찮습니다'
  HOW_BREW='⚠️ 인텔 맥에는 권하지 않습니다.
Homebrew가 2026년 9월부터 인텔을 3등급으로 내려, brew install 이
몇 시간씩 컴파일하거나 「no bottle available」로 실패합니다.
아래 항목들은 Homebrew 없이 받는 길로 적어 두었으니 그대로 하시면 됩니다.
🙋 이미 brew가 깔려 있고 잘 돌아간다면 그대로 쓰셔도 됩니다.'
  HOW_CLAUDE='curl -fsSL https://claude.ai/install.sh | bash
그다음 터미널 창을 닫고 새로 여십시오.
🙋 연동을 안 붙일 거면 이건 없어도 됩니다.'
  HOW_NODE='mkdir -p ~/.local
curl -fsSL https://nodejs.org/dist/v24.21.0/node-v24.21.0-darwin-x64.tar.gz | tar -xz -C ~/.local --strip-components=1
grep -q .local/bin ~/.zprofile 2>/dev/null || echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> ~/.zprofile
그다음 터미널 창을 닫고 새로 연 뒤  node --version  으로 확인합니다.
🙋 홈 폴더 안에만 깔립니다 — 비밀번호를 묻지 않습니다.
🙋 더 새 판이 필요하면 https://nodejs.org/dist/ 에서 판 번호만 바꾸시면 됩니다.
🚫 brew install node 는 인텔에서 실패하거나 몇 시간 걸립니다.'
  HOW_NPX='위 Node.js를 깔면 함께 들어옵니다'
  HOW_PY='Xcode 명령줄 도구를 깔면 함께 들어옵니다.
그래도 없으면 https://www.python.org/downloads/macos/ 에서 설치본을 받아 두 번 누르십시오.'
  HOW_UV='curl -LsSf https://astral.sh/uv/install.sh | sh
그다음 터미널 창을 닫고 새로 여십시오.'
  HOW_BUN='⚠️ 인텔 맥에는 권하지 않습니다.
구형 인텔 CPU(AVX2 미지원)에서 「Illegal instruction」으로 죽는 사례가 보고돼 있습니다.
피그마는 중계 방식 대신 공식 연동을 쓰시는 편이 안전합니다 — 담당자에게 물어보십시오.
꼭 필요하면:  curl -fsSL https://bun.sh/install | bash'
  HOW_GH='① https://github.com/cli/cli/releases 를 엽니다
② 최신 판에서  gh_…_macOS_universal.pkg  를 받아 두 번 누릅니다
③ 그다음:  gh auth login
⚠️ 이 설치본은 관리자 비밀번호를 물어봅니다 — 사람이 직접 하셔야 합니다.
🙋 없어도 시작은 됩니다. 나중에 보태셔도 됩니다.'
  HOW_CODE='curl -fsSL -o /tmp/vscode.zip https://update.code.visualstudio.com/latest/darwin/stable
mkdir -p ~/Applications && unzip -qo /tmp/vscode.zip -d ~/Applications && rm /tmp/vscode.zip
🙋 홈 폴더 안 「응용 프로그램」에 깔립니다 — 비밀번호를 묻지 않습니다.
code 명령은 VS Code를 열고 ⌘⇧P → "shell command" 로 켭니다.'
  HOW_FIGMA_BUN='① curl -fsSL https://bun.sh/install | bash      ⚠️ 인텔에서는 실패할 수 있습니다'
  HOW_GA_SDK='① https://cloud.google.com/sdk/docs/install-sdk 에서 macOS 64-bit (x86_64) 판을 받아
   압축을 푼 뒤  ./google-cloud-sdk/install.sh  를 실행합니다
② curl -LsSf https://astral.sh/uv/install.sh | sh        (uv가 없으면)'
else
  HOW_CLAUDE='brew install --cask claude-code
(Homebrew를 먼저 깔아야 합니다)
🙋 연동을 안 붙일 거면 이건 없어도 됩니다.'
  HOW_NODE='brew install node'
  HOW_NPX='brew install node   (Node에 딸려 옵니다)'
  HOW_PY='brew install python'
  HOW_UV='brew install uv'
  HOW_BUN='brew install oven-sh/bun/bun'
  HOW_GH='brew install gh
그다음:  gh auth login'
  HOW_CODE='brew install --cask visual-studio-code'
  HOW_FIGMA_BUN='① brew install oven-sh/bun/bun'
  HOW_GA_SDK='① brew install --cask google-cloud-sdk
② brew install uv        (uv가 없으면)'
fi

# ═══ ① 반드시 필요한 것 — 이게 없으면 시작을 못 한다 ══════════════════════
# ⚠️ 순서가 있다 — Xcode 명령줄 도구가 먼저고, 그다음 Homebrew, 그다음 나머지.
if xcode-select -p >/dev/null 2>&1; then
  row "필수" "Xcode 명령줄 도구" "있음" "$(xcode-select -p)" \
    "git을 비롯한 기본 개발 도구가 여기서 옵니다. Homebrew도 이것이 먼저 있어야 깔립니다" \
    "xcode-select --install"
else
  row "필수" "Xcode 명령줄 도구" "없음" "찾지 못했습니다" \
    "git을 비롯한 기본 개발 도구가 여기서 옵니다. Homebrew도 이것이 먼저 있어야 깔립니다" \
    "xcode-select --install"
fi
# ⛔ 인텔에서는 Homebrew가 **필수가 아니다**(2026-09-22). 기본 완료 기준(스킬을 만들고 고치기)에
#    필요한 것은 Xcode 명령줄 도구와 데스크탑 앱뿐이고, 그 둘 다 brew를 거치지 않는다.
#    필수로 두면 brew가 막힌 사람이 「준비 실패」로 판정되어 실제로는 되는 일을 못 하게 된다.
if (( INTEL )); then
  if have brew; then
    row "있으면 좋은" "Homebrew" "있음" "${$(brew --version 2>&1)[(f)1]}" "$WHY_BREW" "이미 있습니다"
  else
    row "있으면 좋은" "Homebrew" "안 써도 됩니다" "인텔 맥이라 건너뜁니다" "$WHY_BREW" "$HOW_BREW"
  fi
else
  probe "필수" "Homebrew" "brew" "--version" "$WHY_BREW" "$HOW_BREW"
fi
probe "필수" "git" "git" "--version" \
  "스킬을 받아 오고, 고친 것을 기록으로 남길 때 씁니다" \
  "Xcode 명령줄 도구를 깔면 함께 들어옵니다"
# ⛔ claude 터미널 명령은 **필수가 아니다**(2026-09-08 교정).
#    데스크탑 앱의 Code로 스킬을 만들고 고치는 데는 이 명령이 필요 없다.
#    ⚠️ 한 번 반대로 고쳤다가 되돌렸다 — 「없으면 준비 끝이 나온다」를 고치려다
#    **필수로 올려 버려서**, Code가 멀쩡히 되는 사람을 「준비 실패」로 판정하게 됐다.
#    회사 컴퓨터에서 설치가 정책에 막히면 실제로는 되는 사람이 못 하게 된다.
#    → 필수가 아니라 **연동을 등록할 때 쓰는 것**으로 둔다.
probe "연동에 쓰는 것" "claude 터미널 명령" "claude" "--version" \
  "연동(MCP)을 명령으로 등록할 때 씁니다. 🙋 스킬을 만들고 고치는 데는 없어도 됩니다 — 데스크탑 앱의 Code로 됩니다" \
  "$HOW_CLAUDE"

# ═══ ② 무엇을 하려는지에 따라 필요한 것 ════════════════════════════════════
# ⛔ 옛 판은 이 둘을 「필수」에 넣고 「없으면 연동이 하나도 안 붙는다」고 적었다 — **사실이 아니다**
#    (2026-09-08 · Codex 검토 지적). 웹 주소로 붙는 연동(화면 그리기 도구·볼트)은 Node가 없어도 된다.
#    Node가 필요한 것은 **내 컴퓨터에서 프로그램으로 도는 연동**(피그마 같은 것)이다.
probe "골라 쓰는 것" "Node.js" "node" "--version" \
  "내 컴퓨터에서 프로그램으로 도는 연동(피그마 같은 것)에 필요합니다. 웹 주소로 바로 붙는 연동은 이것 없이도 됩니다" \
  "$HOW_NODE"
probe "골라 쓰는 것" "npx" "npx" "--version" \
  "위와 같은 연동을 받아 띄우는 명령입니다. Node를 깔면 함께 들어옵니다" \
  "$HOW_NPX"
probe "골라 쓰는 것" "Python 3" "python3" "--version" \
  "스킬에 파이썬 도구가 딸려 오는 경우가 있습니다. 그것을 돌릴 때 필요합니다" \
  "$HOW_PY"
probe "골라 쓰는 것" "uv (uvx)" "uvx" "--version" \
  "파이썬으로 만든 연동(구글 애널리틱스 같은 것)을 깔 때 씁니다" \
  "$HOW_UV"
probe "골라 쓰는 것" "bun" "bun" "--version" \
  "피그마 연동의 중계 프로그램이 이것으로 돕니다" \
  "$HOW_BUN"

# ═══ ③ 있으면 훨씬 편한 것 ═════════════════════════════════════════════════
probe "있으면 좋은" "GitHub CLI" "gh" "--version" \
  "GitHub 로그인과 저장소 내려받기가 명령 한 줄이 됩니다" \
  "$HOW_GH"
probe "있으면 좋은" "VS Code" "code" "--version" \
  "스킬 파일을 편하게 고칩니다" \
  "$HOW_CODE"

# ═══ ④ 스킬·에이전트를 두는 자리 ═══════════════════════════════════════════
for pair in "스킬을 두는 곳:$HOME/.claude/skills" "에이전트를 두는 곳:$HOME/.claude/agents"; do
  label="${pair%%:*}"; dir="${pair#*:}"
  if [[ -d "$dir" ]]; then
    n=(${dir}/*(N))
    row "Claude Code" "$label" "있음" "${#n}개 들어 있습니다" \
      "자기 스킬·에이전트를 여기에 둡니다" "이미 있습니다"
  else
    row "Claude Code" "$label" "아직 없음" "만들면 됩니다" \
      "자기 스킬·에이전트를 여기에 둡니다. 아직 없는 것은 잘못이 아닙니다" "mkdir -p $dir"
  fi
done

# ═══ ⑤ 연동(MCP) — 이름만 본다 (🚫 값·토큰은 읽지 않는다) ══════════════════
# ⚠️ 연동은 여러 자리에 등록될 수 있다 — 홈 설정 · 전역 설정 · **꾸러미 루트** · 지금 폴더.
#    ⛔ 두 번 누르기로 돌면 지금 폴더가 `맥/`이라 꾸러미 루트를 못 본다(2026-09-08 · Codex 지적).
#       그래서 `$HERE/..`도 함께 본다.
#    🚫 여기서 못 본 것을 「없다」로 단정하지 않는다 — 프로젝트 폴더는 셀 수 없이 많다.
CFGS=("$HOME/.claude.json" "$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json" \
      "$HERE/../.mcp.json" "$HERE/.mcp.json" "$PWD/.mcp.json")
# ⚠️ 변수 이름은 영문만 — **셸은 한글 이름을 못 쓴다**(실사고 2026-09-08: 두 번 걸렸다).
mcp_has() {   # mcp_has <등록이름…>  →  아는 자리 어디에든 그 이름 중 하나가 있나 (값은 안 본다)
  local f key
  for f in "${CFGS[@]}"; do
    [[ -f "$f" ]] || continue
    for key in "$@"; do
      grep -q "\"$key\"" "$f" 2>/dev/null && return 0
    done
  done
  return 1
}
mcp_row() {   # mcp_row <보일이름> <왜> <어떻게> <등록이름…>
  local label="$1" why="$2" how="$3"; shift 3
  # ⛔ 「이름이 있다」와 「실제로 붙었다」는 다르다(2026-09-08 · Codex 지적).
  #    옛 판은 이름만 보고 「이미 됩니다」라고 적었다 — 인증 만료·서버 죽음·승인 대기를 못 본다.
  if mcp_has "$@"; then
    row "연동" "$label" "설정에 이름 있음" "실제로 붙었는지는 아래 확인이 필요합니다" "$why" \
        "이미 등록은 되어 있습니다. 실제로 붙었는지는 Claude Code에서 /mcp 로 확인하십시오"
  else
    row "연동" "$label" "여기선 못 찾음" "아래 「이렇게」대로 등록하십시오" \
        "$why · 🙋 다른 프로젝트 폴더에 등록해 두었다면 이 점검이 그것을 못 봅니다" "$how"
  fi
}

mcp_row "Claude Design" \
  "화면을 그리는 데 씁니다. 웹 주소로 붙으니 Node.js가 없어도 됩니다" \
  "claude mcp add --scope user --transport http claude-design https://api.anthropic.com/v1/design/mcp
그다음 Claude Code를 닫고 다시 여십시오." \
  "claude-design"
mcp_row "바이널씨 볼트" \
  "사내에 모아 둔 프롬프트·스킬 저장소를 Claude가 직접 뒤져 씁니다. 웹 주소로 붙으니 Node.js가 없어도 됩니다" \
  "claude mcp add --scope user --transport sse vinylc-vault https://vault.vinylc.com/mcp
그다음 Claude Code를 닫고 다시 여십시오.
🙋 처음 붙을 때 로그인을 요구할 수 있습니다 — 그러면 사내 계정으로 하십시오." \
  "vinylc-vault"
mcp_row "피그마 (중계 방식)" \
  "Claude가 피그마 파일을 직접 읽고 고칩니다. ⚠️ 이것은 내 컴퓨터에서 프로그램으로 도는 방식이라 Node.js와 bun이 필요합니다" \
  "⛔ 이건 사내가 만든 것이 아니라 **바깥 사람이 공개한 프로그램**입니다.
   회사 방침을 먼저 확인하시고, 아래 정해진 자리에만 받으십시오.
$HOW_FIGMA_BUN
② mkdir -p ~/Developer && cd ~/Developer          ← 자리를 정해 둡니다(여기저기 받지 않게)
③ git clone https://github.com/jayd2g/claude-talk-to-figma-mcp
④ cd claude-talk-to-figma-mcp
⑤ git log -1 --format=%H                          ← 받은 판의 지문을 적어 두십시오
   그 지문을 담당자에게 알려 확인받은 뒤 다음으로 가십시오.
⑥ bun install
⑦ bun run dist/socket.js                            (3055번 문을 씁니다)
⑧ claude mcp add --scope user claude-talk-to-figma -- node ~/Developer/claude-talk-to-figma-mcp/dist/server.js
⑨ Claude Code를 닫고 다시 여십시오.
⑩ 피그마에서 플러그인 불러오기 — 「직접_해야_하는_것」 8번을 보십시오." \
  "claude-talk-to-figma" "ClaudeTalkToFigma"
mcp_row "구글 애널리틱스" \
  "고객사 사이트 방문 수치를 Claude가 직접 읽어 분석합니다. 팀이 하나의 고객사 계정을 함께 씁니다" \
  "$HOW_GA_SDK
③ uv tool install analytics-mcp
④ gcloud auth application-default login
   ← 창이 뜨면 담당자에게 받은 고객사 계정으로 로그인하십시오(개인 계정이 아닙니다)
⑤ 아래 「구글 애널리틱스 연동」 절의 설정을 그대로 붙여 넣습니다" \
  "google-analytics"

# ═══ ⑤ 안내서 ══════════════════════════════════════════════════════════════
w '<!doctype html><html lang="ko"><head><meta charset="utf-8">'
w '<meta name="viewport" content="width=device-width,initial-scale=1">'
w '<title>환경 점검 결과</title>'
w '<style>'
w ' :root{--ink:#1c1b19;--dim:#6b6862;--line:#e2ded6;--bg:#faf8f4;--card:#fff;'
w '       --good:#1d6f42;--bad:#b3261e;--warn:#8a6d1f;--code:#f3efe7;--note:#fff8ea;--noteline:#ecd9a8}'
w ' *{box-sizing:border-box}'
w ' body{margin:0;background:var(--bg);color:var(--ink);'
w '      font:16px/1.65 -apple-system,"Apple SD Gothic Neo","Segoe UI",system-ui,sans-serif}'
w ' .wrap{max-width:900px;margin:0 auto;padding:40px 24px 80px}'
w ' h1{font-size:30px;letter-spacing:-.02em;margin:0 0 6px;text-wrap:balance}'
w ' .when{color:var(--dim);font-size:14px;margin:0 0 30px}'
w ' .sum{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:22px 24px;margin-bottom:16px}'
w ' .sum b{font-size:21px;display:block;margin-bottom:4px}'
w ' h2{font-size:20px;margin:40px 0 4px;padding-bottom:8px;border-bottom:1px solid var(--line)}'
w ' .lead{color:var(--dim);font-size:14px;margin:0 0 16px}'
w ' .item{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:16px 18px;margin-bottom:10px}'
w ' .head{display:flex;align-items:baseline;gap:10px;flex-wrap:wrap}'
w ' .name{font-weight:700;font-size:17px}'
w ' .tag{font-size:12px;font-weight:700;padding:2px 9px;border-radius:20px;white-space:nowrap}'
w ' .ok{background:#e7f2ea;color:var(--good)} .no{background:#fbeae9;color:var(--bad)}'
w ' .mid{background:#fbf3e0;color:var(--warn)}'
w ' .found{color:var(--dim);font-size:13px;font-variant-numeric:tabular-nums}'
w ' .why{margin:9px 0 0;font-size:14.5px}'
w ' .how{margin-top:11px}'
w ' .how .lb{font-size:12px;color:var(--dim);display:block;margin-bottom:5px}'
w ' code{display:block;background:var(--code);border:1px solid var(--line);border-radius:8px;'
w '      padding:10px 12px;font:13px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace;'
w '      overflow-x:auto;white-space:pre}'
w ' .order{background:var(--note);border:1px solid var(--noteline);border-radius:12px;padding:18px 20px;margin:0 0 26px}'
w ' .order ol{margin:8px 0 0;padding-left:22px} .order li{margin-bottom:5px}'
w ' .nothing{background:var(--card);border:1px dashed var(--line);border-radius:12px;
      padding:14px 18px;margin:0 0 18px;font-size:15px;color:var(--dim)}
 .nothing b{color:var(--ink)}
 .end{margin-top:44px;padding-top:18px;border-top:1px solid var(--line);color:var(--dim);font-size:13px}'
w ' @media (prefers-color-scheme:dark){:root:not([data-theme="light"]){'
w '   --ink:#eceae5;--dim:#a5a19a;--line:#332f2a;--bg:#151412;--card:#1e1c1a;--code:#252320;'
w '   --good:#6fcf97;--bad:#f2837c;--warn:#e0bc6a;--note:#221d13;--noteline:#3d3524}'
w '   .ok{background:#1b2c22} .no{background:#2e1c1a} .mid{background:#2b2517}}'
w '</style></head><body><div class="wrap">'

w '<h1>환경 점검 결과</h1>'
w '<div class="nothing"><b>이 점검은 아무것도 설치하지 않았습니다.</b>'
w '무엇이 있고 없는지만 <b>재서</b> 알려 드립니다. 아래 명령을 실행하는 방법은 <b>두 가지</b>입니다.'
w '<br><br><b>① Claude에게 맡기기</b> — 이 폴더를 Claude 앱에서 열고 <b>/환경세팅-도우미</b> 를 부르십시오.'
w '아래 명령을 <b>하나씩 물어보며</b> 대신 돌려 줍니다. 무엇을 왜 하는지 매번 알려 드립니다.'
w '<br><b>② 직접 하기</b> — 명령을 복사해 터미널에 붙여 넣으십시오.'
w '회사 방침상 명령 실행을 맡길 수 없을 때는 이쪽입니다.'
w '<br><br>어느 쪽이든 <b>무엇이 도는지는 이 화면에 그대로 적혀 있습니다.</b>'
w '비밀번호를 묻는 설치와 창을 띄우는 로그인은 <b>어느 쪽이든 사람이 직접</b> 하셔야 합니다.</div>'
if (( INTEL )); then
  w "<p class=\"when\">$(date '+%Y년 %-m월 %-d일 %H:%M') · 이 컴퓨터: <b>인텔 맥</b> ($ARCH)</p>"
  w '<div class="order"><b>이 컴퓨터는 인텔 맥입니다 — Homebrew를 거치지 않는 길로 안내합니다</b>'
  w '<p style="margin:8px 0 0;font-size:14.5px">Homebrew가 2026년 9월부터 인텔 맥을 <b>3등급</b>으로 내렸습니다.'
  w '미리 만들어 둔 꾸러미를 더 이상 갱신하지 않아서, <b>brew install 이 몇 시간씩 컴파일하거나'
  w '「no bottle available」로 실패합니다.</b> 그래서 아래 항목은 전부 <b>직접 받는 길</b>로 적어 두었습니다.<br>'
  w '🙋 Homebrew가 이미 깔려 있고 잘 돌아간다면 그대로 쓰셔도 됩니다 — 지금 지우실 필요는 없습니다.</p></div>'
else
  w "<p class=\"when\">$(date '+%Y년 %-m월 %-d일 %H:%M') · 이 컴퓨터: 맥 ($ARCH)</p>"
fi

if (( MISSING == 0 )); then
  w '<div class="sum"><b>반드시 필요한 것은 다 있습니다.</b>'
  w '스킬과 에이전트를 만들고 고칠 수 있는 상태입니다. 아래에서 「있으면 좋은」 것과 「연동」만 골라 보태면 됩니다.</div>'
else
  w "<div class=\"sum\"><b>반드시 필요한 것 ${MISSING}가지가 없습니다.</b>"
  w '아래 순서대로 위에서부터 하시면 됩니다. <b>순서가 중요합니다</b> — 앞의 것이 뒤의 것을 깔아 줍니다.</div>'
  w '<div class="order"><b>이 순서로 하십시오</b>'
  w '<ol><li><b>Xcode 명령줄 도구</b> — 이것이 있어야 다음이 깔립니다</li>'
  (( INTEL )) || w '<li><b>Homebrew</b> — 나머지를 깔아 주는 손입니다</li>'
  w '<li><b>git</b> — Xcode 명령줄 도구를 깔면 함께 들어옵니다</li>'
  w '<li>⭐ <b>여기까지면 스킬을 만들고 고칠 수 있습니다.</b> 아래 「무엇을 하려는지에 따라 필요한 것」은'
  w '    <b>붙일 연동을 고른 뒤</b> 그것이 요구하는 것만 깔면 됩니다 — 전부 깔 필요 없습니다.</li>'
  w '<li>무언가를 깔았으면 <b>터미널 창을 닫고 새로 열어</b> 이 점검을 다시 돌리십시오</li></ol>'
  w '<p style="margin:12px 0 0;font-size:14px">막히면 그 자리에서 멈추고 물어보십시오. 다음 칸으로 넘어가도 안 됩니다.</p></div>'
fi

PREV=""
for r in "${ROWS[@]}"; do
  g="${r%%|*}";  rest="${r#*|}"
  nm="${rest%%|*}"; rest="${rest#*|}"
  st="${rest%%|*}"; rest="${rest#*|}"
  fd="${rest%%|*}"; rest="${rest#*|}"
  wy="${rest%%|*}"; hw="${rest#*|}"
  if [[ "$g" != "$PREV" ]]; then
    case "$g" in
      "필수")        t="반드시 필요한 것"; l="이것이 없으면 스킬·에이전트 작업을 시작할 수 없습니다.";;
      "골라 쓰는 것") t="무엇을 하려는지에 따라 필요한 것"; l="전부 깔 필요는 없습니다. 아래 「연동」에서 붙일 것을 고른 뒤, 그것이 요구하는 것만 깔면 됩니다.";;
      "연동에 쓰는 것") t="연동을 붙일 때만 필요한 것"; l="연동을 안 붙일 거면 없어도 됩니다. 스킬을 만들고 고치는 데는 필요하지 않습니다.";;
      "있으면 좋은")  t="있으면 훨씬 편한 것"; l="없어도 시작은 됩니다. 나중에 보태도 괜찮습니다.";;
      "Claude Code") t="Claude Code 쪽"; l="앱은 이미 깔려 있다고 보고, 그 주변만 봅니다.";;
      "연동")        t="연동(MCP)"; l="Claude가 바깥 도구를 직접 부를 수 있게 잇는 것입니다. 붙이려면 Node.js가 먼저 있어야 합니다.";;
      *)             t="$g"; l="";;
    esac
    w "<h2>$(esc "$t")</h2><p class=\"lead\">$(esc "$l")</p>"
    PREV="$g"
  fi
  case "$st" in
    "있음") c="ok";; "없음") c="no";; *) c="mid";;
  esac
  w "<div class=\"item\"><div class=\"head\"><span class=\"name\">$(esc "$nm")</span>"
  w "<span class=\"tag $c\">$(esc "$st")</span><span class=\"found\">$(esc "$fd")</span></div>"
  w "<p class=\"why\">$(esc "$wy")</p>"
  if [[ "$st" != "있음" ]]; then
    w "<div class=\"how\"><span class=\"lb\">이렇게 하면 됩니다 — 터미널에 붙여 넣으십시오</span><code>$(esc "$hw")</code></div>"
  fi
  w '</div>'
done

# ⭐ 그 사람의 실제 경로를 채워 넣어 준다 — 손으로 고칠 자리를 없앤다.
#    실사고 대비: 대괄호를 남겨 두면 그 자리를 안 바꾸고 붙여 넣어 안 되는 일이 잦다.
if have analytics-mcp; then
  AMC="$(command -v analytics-mcp)"
  AMC_NOTE="이 컴퓨터에서 찾은 자리를 그대로 넣었습니다"
else
  AMC="$HOME/.local/bin/analytics-mcp"
  AMC_NOTE="아직 안 깔려 있어 **깔면 생길 자리**로 적었습니다 — 위 ③번을 먼저 하십시오"
fi
ADC="$HOME/.config/gcloud/application_default_credentials.json"

w '<h2>구글 애널리틱스 연동</h2>'
w '<p class="lead">이것만은 전역이 아니라 <b>일할 프로젝트 폴더</b>에 적습니다.</p>'

w '<div class="item"><div class="head"><span class="name">계정 하나를 팀이 함께 씁니다</span>'
w '<span class="tag mid">먼저 읽어 주십시오</span></div>'
w '<p class="why">이 연동은 <b>고객사 계정 하나를 팀이 함께</b> 쓰기로 정해져 있습니다.'
w '개인 계정을 따로 만들지 않습니다 — <b>계정 정보를 담당자에게 받으십시오.</b></p>'
w '<p class="why"><b>✅ 그 계정으로 각자 직접 로그인하십시오</b>(위 ④번).'
w '그러면 자기 컴퓨터에 자기 열쇠가 새로 만들어집니다.<br>'
w '<b>🚫 남의 컴퓨터에 있는 열쇠 파일을 복사해 오지는 마십시오.</b> 같은 계정이어도 그렇습니다 —'
w '복사한 파일은 기한이 지나거나 회수되면 <b>통째로 멈추고</b>, 어느 컴퓨터에 퍼졌는지 알 수 없게 됩니다.'
w '직접 로그인하면 그 자리에서 새로 만들어지니 복사할 이유가 없습니다.</p></div>'
w '<div class="item"><div class="head"><span class="name">계정을 함께 쓰면 이런 일이 따라옵니다</span>'
w '<span class="tag mid">알아 두기</span></div>'
w '<p class="why">정해진 방식이니 그대로 쓰시면 됩니다. 다만 <b>알고 쓰시는 편</b>이 좋습니다.<br>'
w '· 누가 무엇을 봤는지 <b>사람별로 구분되지 않습니다</b> — 기록이 한 계정으로 남습니다.<br>'
w '· 그 계정의 비밀번호가 바뀌면 <b>쓰는 사람 전원이 한꺼번에 멈춥니다</b>. 그때는 각자 다시 로그인합니다.<br>'
w '· 2단계 인증이 걸려 있으면 <b>인증 코드를 받는 사람</b>을 거쳐야 로그인이 됩니다.</p></div>'

w '<div class="item"><div class="head"><span class="name">붙여 넣을 설정</span>'
w "<span class=\"found\">$(esc "$AMC_NOTE")</span></div>"
w '<p class="why">일할 프로젝트 폴더에 <b>.mcp.json</b>이라는 이름으로 두십시오.'
w '이미 그 파일이 있으면 <b>mcpServers 안에 google-analytics 한 덩이만</b> 보태십시오.</p>'
w '<div class="how"><span class="lb">.mcp.json — 이 컴퓨터에 맞게 채워 뒀습니다. 고칠 곳 없습니다</span><code>{'
w '  "mcpServers": {'
w '    "google-analytics": {'
w "      \"command\": \"$(esc "$AMC")\","
w '      "env": {'
w "        \"GOOGLE_APPLICATION_CREDENTIALS\": \"$(esc "$ADC")\","
w '        "GOOGLE_PROJECT_ID": "vinylc-ga-mcp",'
w '        "GOOGLE_CLOUD_PROJECT": "vinylc-ga-mcp"'
w '      }'
w '    }'
w '  }'
w '}</code></div>'
w '<p class="why" style="margin-top:12px">🙋 <b>vinylc-ga-mcp</b>는 우리 팀이 함께 쓰는 이름입니다 —'
w '이건 바꾸지 마십시오. 두 줄 다 같은 값이 들어가는 것이 맞습니다.<br>'
w '⚠️ 붙여 넣은 뒤 <b>Claude Code를 닫고 다시</b> 열어야 붙습니다.</p></div>'

w '<div class="item"><div class="head"><span class="name">설치는 됐는데 수치가 안 보이면</span>'
w '<span class="tag mid">흔한 일</span></div>'
w '<p class="why">거의 항상 <b>어느 계정으로 로그인했나</b>의 문제입니다. 설치를 잘못한 게 아닙니다.'
w '④번에서 <b>자기 개인 구글 계정으로</b> 로그인했으면 아무것도 안 보입니다 — 그 계정에는 볼 권한이 없습니다.'
w '<b>담당자에게 받은 고객사 계정</b>으로 로그인했는지 확인하십시오. 다시 로그인하려면 위 ④번 명령을 한 번 더 돌리면 됩니다. 🚫 다시 깔지는 마십시오.</p></div>'

w '<h2>꼭 지켜 주실 것</h2>'
w '<div class="item"><div class="head"><span class="name">남의 설정 파일을 복사해 쓰지 마십시오</span><span class="tag no">주의</span></div>'
w '<p class="why">연동 설정 파일에는 <b>그 사람의 접근 열쇠</b>가 들어 있습니다.'
w '복사해 쓰면 남의 권한으로 접속하는 것이 되고, 그 사람이 열쇠를 바꾸는 순간 멈춥니다.'
w '연동은 <b>반드시 각자 자기 계정으로</b> 등록하십시오.'
w '이 점검기가 열쇠 값을 읽지 않는 것도 같은 이유입니다 — 이름이 있나 없나만 봅니다.</p></div>'
w '<div class="item"><div class="head"><span class="name">무언가를 깐 뒤에는 창을 새로 여십시오</span><span class="tag mid">알아 두기</span></div>'
w '<p class="why">터미널은 열릴 때 한 번만 둘러봅니다. 새로 깐 것은 <b>새 창</b>에서야 보입니다.'
w '연동을 등록했을 때도 마찬가지로 <b>Claude Code를 닫고 다시</b> 열어야 보입니다.</p></div>'

w '<p class="end">이 문서는 <b>이 컴퓨터를 실제로 재서</b> 만든 것입니다. 짐작으로 적은 항목은 없습니다.<br>'
w '무언가를 깐 뒤에는 이 점검을 <b>다시 돌리십시오</b>.</p>'
w '</div></body></html>'

print -rn -- "$BUF" > "$OUT"

print -r -- ""
print -r -- "  재기 끝났습니다.  (🚫 아무것도 설치하지 않았습니다 — 재기만 했습니다)"
print -r -- "  반드시 필요한 것 중 없는 것: ${MISSING}가지"
print -r -- "  안내서: $OUT"
print -r -- ""
open "$OUT" 2>/dev/null || print -r -- "  (브라우저로 위 파일을 열어 보십시오)"
