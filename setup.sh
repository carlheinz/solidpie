#!/bin/bash
set -e

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     Pi Coding Agent — Setup                  ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# --- Step 1: Check/install Node.js ---
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    echo "✅ Node.js already installed: $NODE_VERSION"
else
    echo "📦 Node.js not found. Installing..."
    echo ""

    # Detect OS
    OS="$(uname -s)"
    case "$OS" in
        Linux*)
            if command -v apt-get &> /dev/null; then
                echo "   Detected: Debian/Ubuntu"
                curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
                sudo apt-get install -y nodejs
            elif command -v dnf &> /dev/null; then
                echo "   Detected: Fedora/RHEL"
                curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash -
                sudo dnf install -y nodejs
            elif command -v pacman &> /dev/null; then
                echo "   Detected: Arch"
                sudo pacman -Sy nodejs npm --noconfirm
            else
                echo "❌ Could not detect package manager."
                echo "   Install Node.js 20+ manually: https://nodejs.org/"
                exit 1
            fi
            ;;
        Darwin*)
            if command -v brew &> /dev/null; then
                echo "   Detected: macOS with Homebrew"
                brew install node
            else
                echo "❌ Install Homebrew first: https://brew.sh"
                echo "   Or download Node.js from: https://nodejs.org/"
                exit 1
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "   Detected: Windows"
            echo "   Download Node.js from: https://nodejs.org/"
            echo "   Or run: winget install OpenJS.NodeJS"
            exit 1
            ;;
        *)
            echo "❌ Unknown OS: $OS"
            echo "   Install Node.js 20+ manually: https://nodejs.org/"
            exit 1
            ;;
    esac

    echo "✅ Node.js installed: $(node -v)"
fi

# --- Step 2: Install Pi ---
echo ""
if command -v pi &> /dev/null; then
    echo "✅ Pi already installed: $(pi --version 2>/dev/null || echo 'installed')"
else
    echo "📦 Installing Pi coding agent..."
    npm install -g @mariozechner/pi-coding-agent
    echo "✅ Pi installed"
fi

# --- Step 3: Install our skill ---
echo ""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_SOURCE="$SCRIPT_DIR/business-automation-devkit"
SKILL_DEST="$HOME/.pi/agent/skills/business-automation-devkit"

if [ -d "$SKILL_DEST" ]; then
    echo "✅ Skill already installed at $SKILL_DEST"
else
    echo "📦 Installing business-automation-devkit skill..."
    mkdir -p "$HOME/.pi/agent/skills"
    cp -r "$SKILL_SOURCE" "$SKILL_DEST"
    echo "✅ Skill installed"
fi

# --- Done ---
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     ✅ Setup complete!                       ║"
echo "╠══════════════════════════════════════════════╣"
echo "║                                              ║"
echo "║  Next steps:                                 ║"
echo "║                                              ║"
echo "║  1. Start pi:                                ║"
echo "║     $ pi                                     ║"
echo "║                                              ║"
echo "║  2. Login with Gemini:                       ║"
echo "║     /login  →  Select 'Google Gemini CLI'    ║"
echo "║     (Opens browser for Google OAuth)         ║"
echo "║                                              ║"
echo "║  3. Pick a model:                            ║"
echo "║     /model  →  Select a Gemini model         ║"
echo "║                                              ║"
echo "║  4. Start coding! Try:                       ║"
echo "║     'Help me design a dunning workflow        ║"
echo "║      for overdue invoices'                   ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
