#!/usr/bin/env bash
################################################################################
# COMPLETE DESKTOP SUITE INSTALLATION FOR ENDEAVOUROS
# ONE-SCRIPT COPY-PASTE INSTALLATION
# 
# Installation für:
#  ✓ Live-Transkription & Sprache-zu-Sprache (Whisper, Vosk)
#  ✓ Screenshot + PDF-Tools (Flameshot, PDFArranger, qpdfview)
#  ✓ Festplattenanalyse (Filelight, ncdu, Diskhoji, Baobab)
#  ✓ Backup-Automatisierung (Kopia, restic, BorgBackup, Back In Time)
#  ✓ Entwickler-Suite (Docker, PostgreSQL, VS Code, Git)
#  ✓ Browser + Extensions-Support (Firefox, Chromium)
#  ✓ Terminal-Tools (Zsh, Starship, Tmux, Alacritty)
#  ✓ Python Data Science Stack (Jupyter, NumPy, Pandas, Scikit-learn)
#  ✓ System-Utilities (htop, Glances, ripgrep, fzf, bat, exa)
#
# VERWENDUNG:
#   bash <(curl -fsSL https://raw.githubusercontent.com/sTarLighTsMoveMenTzWorldBankEyes/OpenCodeCloseCodeOpenCloudCloseOpenCloudOpenBuildOpenTipsOpenMasterPlan/main/install-desktop-suite-complete.sh)
#
#   ODER lokal:
#   bash install-desktop-suite-complete.sh
#
# REQUIREMENTS: EndeavourOS/Arch Linux, Sudo-Rechte, Internet
################################################################################

set -e

# ============================================================================
# COLORS & FORMATTING
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

print_section() {
    echo -e "\n${CYAN}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${MAGENTA}ℹ${NC} $1"
}

pause_confirm() {
    read -p "$(echo -e ${YELLOW}Weiter? [ENTER]${NC})" -r
}

# ============================================================================
# SYSTEM CHECK
# ============================================================================
check_system() {
    print_header "SYSTEM-CHECK"
    
    if ! grep -qi "EndeavourOS\|Arch" /etc/os-release 2>/dev/null; then
        print_error "System ist nicht EndeavourOS/Arch Linux!"
        print_warning "Fortfahren auf eigene Gefahr? (y/N)"
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] || exit 1
    fi
    print_success "EndeavourOS/Arch erkannt"
    
    if [[ $EUID -eq 0 ]]; then
        print_error "Dieses Skript darf NICHT als root ausgeführt werden!"
        exit 1
    fi
    print_success "Benutzer-Kontext überprüft"
    
    if ! command -v sudo &>/dev/null; then
        print_error "sudo nicht gefunden!"
        exit 1
    fi
    print_success "sudo verfügbar"
}

# ============================================================================
# INITIAL SETUP
# ============================================================================
initial_setup() {
    print_header "INITIAL-SETUP"
    
    print_section "Erstelle ~/.local/bin falls nicht vorhanden"
    mkdir -p ~/.local/bin
    mkdir -p ~/.config
    mkdir -p ~/.config/backup
    mkdir -p ~/.config/intentions
    mkdir -p ~/.config/research-engine
    print_success "Verzeichnisse erstellt"
    
    print_section "Aktualisiere Pacman & Keyring"
    sudo pacman -Sy --noconfirm archlinux-keyring
    sudo pacman -Syu --noconfirm
    print_success "Pacman aktualisiert"
}

# ============================================================================
# AUR HELPER INSTALLATION (yay)
# ============================================================================
install_aur_helper() {
    print_header "AUR-HELPER INSTALLATION (yay)"
    
    if command -v yay &>/dev/null; then
        print_success "yay bereits installiert ($(yay --version | head -1))"
        return
    fi
    
    if command -v paru &>/dev/null; then
        print_success "paru bereits installiert"
        return
    fi
    
    print_section "Installiere base-devel und git"
    sudo pacman -S --noconfirm base-devel git
    
    print_section "Klone yay von AUR"
    cd /tmp
    rm -rf yay-bin 2>/dev/null || true
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd /tmp
    rm -rf yay-bin
    
    print_success "yay installiert ($(yay --version | head -1))"
}

# ============================================================================
# CORE PACMAN PACKAGES
# ============================================================================
install_core_packages() {
    print_header "KERN-PACKAGES (Pacman)"
    
    local packages=(
        # Build & Dev Tools
        "base-devel" "git" "curl" "wget" "git-lfs"
        
        # Python & Node
        "python" "python-pip" "python-virtualenv"
        "nodejs" "npm" "yarn"
        
        # Databases & Services
        "postgresql" "redis" "sqlite"
        
        # Containers & Virt
        "docker" "docker-compose" "podman" "podman-compose"
        
        # Compression & Archives
        "zip" "unzip" "tar" "gzip" "bzip2" "xz" "p7zip"
        
        # Network Tools
        "curl" "wget" "openssh" "rsync" "nmap" "netcat"
        
        # Text Processing
        "sed" "awk" "grep" "jq" "yq" "ripgrep" "fd"
        
        # Monitoring & Info
        "htop" "iotop" "iftop" "nethogs" "glances"
        "neofetch" "inxi" "lsof" "strace"
        
        # File Management
        "fzf" "bat" "exa" "tldr" "tree"
        
        # Editors
        "vim" "neovim" "nano"
        
        # System Utilities
        "tmux" "screen" "zsh" "bash-completion"
        
        # Audio & Video
        "ffmpeg" "sox" "pulseaudio" "pulseaudio-alsa" "alsa-utils"
        
        # Archive & Backup
        "tar" "rsync" "rclone"
    )
    
    print_section "Installiere ${#packages[@]} Pacman-Packages..."
    sudo pacman -S --noconfirm "${packages[@]}"
    print_success "Core Packages installiert"
}

# ============================================================================
# TRANSCRIPTION & SPEECH TOOLS
# ============================================================================
install_transcription_tools() {
    print_header "TRANSKRIPTION & SPRACH-TOOLS"
    
    print_section "Python Transkriptions-Packages"
    pip install --user -U openai-whisper vosk pydub 2>&1 | grep -v "already satisfied" || true
    print_success "Whisper & Vosk installiert"
    
    print_section "System-Audio-Packages"
    sudo pacman -S --noconfirm \
        pulseaudio pulseaudio-alsa ffmpeg sox \
        python-pydub alsa-lib
    print_success "Audio-Stack installiert"
}

# ============================================================================
# SCREENSHOT & PDF TOOLS
# ============================================================================
install_screenshot_pdf_tools() {
    print_header "SCREENSHOT & PDF-TOOLS"
    
    print_section "Installiere Screenshot-Tools"
    sudo pacman -S --noconfirm flameshot spectacle
    print_success "Flameshot & Spectacle installiert"
    
    print_section "Installiere PDF-Tools"
    sudo pacman -S --noconfirm \
        qpdfview pdfarranger ghostscript imagemagick
    print_success "PDF-Tools installiert"
    
    print_section "Installiere LibreOffice"
    sudo pacman -S --noconfirm libreoffice-fresh libreoffice-fresh-de
    print_success "LibreOffice installiert"
    
    print_section "Installiere OCR (Tesseract)"
    sudo pacman -S --noconfirm tesseract tesseract-data-deu tesseract-data-eng
    print_success "OCR installiert"
}

# ============================================================================
# DISK ANALYSIS & CLEANUP
# ============================================================================
install_disk_tools() {
    print_header "FESTPLATTEN-ANALYSE & VISUALISIERUNG"
    
    print_section "Installiere TreeMap-Tools"
    sudo pacman -S --noconfirm filelight ncdu baobab
    print_success "Filelight, ncdu, Baobab installiert"
    
    print_section "Installiere Disk Cleanup Tools"
    sudo pacman -S --noconfirm bleachbit
    print_success "BleachBit installiert"
    
    print_section "Versuche Diskhoji aus AUR zu installieren (optional)"
    if command -v yay &>/dev/null; then
        yay -S --noconfirm diskhoji 2>&1 || print_warning "Diskhoji konnte nicht aus AUR installiert werden (optional)"
    else
        print_warning "Diskhoji erfordert yay (übersprungen)"
    fi
}

# ============================================================================
# BACKUP & STORAGE TOOLS
# ============================================================================
install_backup_tools() {
    print_header "BACKUP- & SPEICHER-TOOLS"
    
    print_section "Installiere Kopia"
    if command -v yay &>/dev/null; then
        yay -S --noconfirm kopia 2>&1 || sudo pacman -S --noconfirm kopia 2>&1 || true
    else
        sudo pacman -S --noconfirm kopia 2>&1 || true
    fi
    print_success "Kopia installiert (falls verfügbar)"
    
    print_section "Installiere restic"
    sudo pacman -S --noconfirm restic
    print_success "restic installiert"
    
    print_section "Installiere BorgBackup"
    sudo pacman -S --noconfirm borgbackup
    print_success "BorgBackup installiert"
    
    print_section "Installiere Back In Time"
    sudo pacman -S --noconfirm backintime
    print_success "Back In Time installiert"
    
    print_section "Installiere Clonezilla (optional)"
    if command -v yay &>/dev/null; then
        yay -S --noconfirm clonezilla 2>&1 || print_warning "Clonezilla konnte nicht installiert werden (optional)"
    fi
}

# ============================================================================
# DEVELOPMENT TOOLS
# ============================================================================
install_dev_tools() {
    print_header "ENTWICKLER-TOOLS"
    
    print_section "Installiere Editoren"
    sudo pacman -S --noconfirm code vim neovim
    print_success "VS Code, Vim, Neovim installiert"
    
    print_section "Installiere Database-Tools"
    sudo pacman -S --noconfirm postgresql dbeaver redis mongodb
    print_success "PostgreSQL, DBeaver, Redis, MongoDB installiert"
    
    print_section "Installiere Programmiersprachen"
    sudo pacman -S --noconfirm go rust ruby perl lua
    print_success "Go, Rust, Ruby, Perl, Lua installiert"
    
    print_section "Installiere Git-Tools"
    sudo pacman -S --noconfirm git-lfs gitk
    print_success "Git LFS, Gitk installiert"
    
    print_section "Installiere API-Tools"
    if command -v yay &>/dev/null; then
        yay -S --noconfirm insomnia 2>&1 || print_warning "Insomnia konnte nicht installiert werden (optional)"
    fi
}

# ============================================================================
# BROWSER INSTALLATION
# ============================================================================
install_browsers() {
    print_header "BROWSER & EXTENSIONS-SUPPORT"
    
    print_section "Installiere Firefox"
    sudo pacman -S --noconfirm firefox firefox-i18n-de
    print_success "Firefox installiert"
    
    print_section "Installiere Chromium"
    sudo pacman -S --noconfirm chromium
    print_success "Chromium installiert"
    
    print_info "Browser-Extensions müssen manuell über die UI installiert werden:"
    echo ""
    echo "    Firefox: https://addons.mozilla.org/firefox/"
    echo "    - Nimbus Screenshot"
    echo "    - Web Captioner"
    echo ""
    echo "    Chrome/Chromium: https://chromewebstore.google.com/"
    echo "    - Fireshot"
    echo "    - GoFullPage"
    echo ""
}

# ============================================================================
# PYTHON DATA SCIENCE STACK
# ============================================================================
install_python_stack() {
    print_header "PYTHON DATA SCIENCE STACK"
    
    print_section "Installiere System-Packages"
    sudo pacman -S --noconfirm \
        python-numpy python-pandas python-scipy \
        python-matplotlib python-scikit-learn
    print_success "NumPy, Pandas, SciPy, Matplotlib, Scikit-learn installiert"
    
    print_section "Installiere pip-Packages"
    pip install --user -U \
        jupyter jupyterlab ipython \
        black pylint flake8 \
        pytest pytest-cov \
        poetry pipenv \
        pandas numpy scipy matplotlib scikit-learn \
        tensorflow keras torch \
        requests beautifulsoup4 selenium \
        sqlalchemy asyncpg aiohttp \
        pydantic click typer \
        dotenv python-json-logger
    print_success "Python Data Science Stack installiert"
}

# ============================================================================
# TERMINAL & SHELL TOOLS
# ============================================================================
install_terminal_tools() {
    print_header "TERMINAL & SHELL-TOOLS"
    
    print_section "Installiere Terminal-Emulatoren"
    sudo pacman -S --noconfirm alacritty kitty wezterm
    print_success "Alacritty, Kitty, WezTerm installiert"
    
    print_section "Installiere Shell-Enhancements"
    sudo pacman -S --noconfirm zsh zsh-completions zsh-syntax-highlighting
    print_success "Zsh & Extensions installiert"
    
    print_section "Installiere Starship Prompt"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    print_success "Starship Prompt installiert"
    
    print_section "Installiere Terminal-Utilities"
    sudo pacman -S --noconfirm \
        tmux screen mc htop bottom lsd ripgrep fd bat exa fzf \
        tldr tree jq yq duf dust hyperfine
    print_success "Terminal-Utilities installiert"
}

# ============================================================================
# CONTAINER & VIRTUALIZATION
# ============================================================================
install_container_tools() {
    print_header "CONTAINER & VIRTUALISIERUNG"
    
    print_section "Installiere Docker"
    sudo pacman -S --noconfirm docker docker-compose docker-buildx
    print_success "Docker & Docker-Compose installiert"
    
    print_section "Installiere Podman (Docker-Alternative)"
    sudo pacman -S --noconfirm podman podman-compose podman-docker
    print_success "Podman installiert"
    
    print_section "Konfiguriere Docker-Benutzer-Gruppe"
    sudo usermod -aG docker "$USER"
    print_success "Benutzer zur docker-Gruppe hinzugefügt"
    print_warning "Starte Shell neu für Änderungen: exec \$SHELL"
    
    print_section "Aktiviere Docker-Service"
    sudo systemctl enable docker
    sudo systemctl start docker
    print_success "Docker-Service aktiviert"
}

# ============================================================================
# CONFIGURATION & SETUP
# ============================================================================
setup_configurations() {
    print_header "KONFIGURATIONEN ERSTELLEN"
    
    print_section "Erstelle Kopia-Backup-Konfiguration"
    cat > ~/.config/backup/kopia-policy.json << 'EOF'
{
  "retention": {
    "keepDaily": 7,
    "keepWeekly": 4,
    "keepMonthly": 12,
    "keepAnnual": 3
  },
  "compression": "pgzip",
  "encryption": "AES256-GCM",
  "scheduling": {
    "interval": "24h",
    "timeOfDay": "02:00"
  }
}
EOF
    print_success "Kopia-Policy erstellt"
    
    print_section "Erstelle Research-Engine-Seed-Config"
    cat > ~/.config/research-engine/sources.json << 'EOF'
{
  "version": "1.0",
  "categories": {
    "code_archives": [
      {"name":"GitHub","url":"https://api.github.com","access":"api"},
      {"name":"GitLab","url":"https://gitlab.com/api/v4","access":"api"}
    ],
    "package_repos": [
      {"name":"PyPI","url":"https://pypi.org/pypi","access":"api"},
      {"name":"NPM","url":"https://registry.npmjs.org","access":"api"},
      {"name":"DockerHub","url":"https://hub.docker.com/v2","access":"api"}
    ],
    "models_and_datasets": [
      {"name":"HuggingFace","url":"https://huggingface.co/api","access":"api"},
      {"name":"Kaggle","url":"https://www.kaggle.com/api","access":"api"}
    ],
    "policy_and_standards": [
      {"name":"EUR-Lex","url":"https://eur-lex.europa.eu","access":"manual"},
      {"name":"NIST","url":"https://www.nist.gov","access":"manual"}
    ]
  }
}
EOF
    print_success "Research-Engine-Config erstellt"
    
    print_section "Erstelle Intentions-Konfiguration"
    cat > ~/.config/intentions/config.json << 'EOF'
{
  "version": "1.0",
  "auto_analyze": true,
  "clarification_threshold": 0.45,
  "timeout_hours": 24,
  "pipeline_defaults": ["spec", "scaffold", "ci", "patchgen", "review"],
  "tags": ["feature", "bugfix", "research", "spike", "documentation"],
  "priorities": ["P0", "P1", "P2", "P3"]
}
EOF
    print_success "Intentions-Config erstellt"
}

# ============================================================================
# HELPER SCRIPTS
# ============================================================================
create_helper_scripts() {
    print_header "HELPER-SCRIPTS ERSTELLEN"
    
    print_section "Erstelle backup-system.sh"
    cat > ~/.local/bin/backup-system.sh << 'EOF'
#!/bin/bash
set -e
echo "🔄 Starte System-Backup..."

BACKUP_DIR="/mnt/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

if command -v kopia &>/dev/null; then
    echo "📦 Kopia Backup..."
    kopia snapshot create
elif command -v restic &>/dev/null; then
    echo "📦 Restic Backup..."
    restic backup ~
else
    echo "⚠️  Kein Backup-Tool verfügbar"
    exit 1
fi

echo "✓ Backup abgeschlossen: $TIMESTAMP"
EOF
    chmod +x ~/.local/bin/backup-system.sh
    print_success "backup-system.sh erstellt"
    
    print_section "Erstelle analyze-disk.sh"
    cat > ~/.local/bin/analyze-disk.sh << 'EOF'
#!/bin/bash
echo "💾 Festplatten-Analyse..."
if command -v ncdu &>/dev/null; then
    ncdu /
elif command -v filelight &>/dev/null; then
    filelight /
elif command -v baobab &>/dev/null; then
    baobab /
else
    du -sh /*
fi
EOF
    chmod +x ~/.local/bin/analyze-disk.sh
    print_success "analyze-disk.sh erstellt"
    
    print_section "Erstelle transcribe-audio.sh"
    cat > ~/.local/bin/transcribe-audio.sh << 'EOF'
#!/bin/bash
if [[ $# -eq 0 ]]; then
    echo "Usage: transcribe-audio.sh <audio-file> [language]"
    echo "Examples:"
    echo "  transcribe-audio.sh meeting.mp3"
    echo "  transcribe-audio.sh video.mp4 de"
    exit 1
fi

AUDIO_FILE="$1"
LANGUAGE="${2:-de}"

echo "🎤 Transkribiere: $AUDIO_FILE (Sprache: $LANGUAGE)"

if command -v whisper &>/dev/null; then
    whisper "$AUDIO_FILE" --language "$LANGUAGE" --output_format txt --output_dir ~/transcriptions
    echo "✓ Transkription fertig in ~/transcriptions/"
else
    echo "✗ Whisper nicht installiert"
    exit 1
fi
EOF
    chmod +x ~/.local/bin/transcribe-audio.sh
    print_success "transcribe-audio.sh erstellt"
    
    print_section "Erstelle screenshot.sh"
    cat > ~/.local/bin/screenshot.sh << 'EOF'
#!/bin/bash
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

if command -v flameshot &>/dev/null; then
    flameshot gui
elif command -v spectacle &>/dev/null; then
    spectacle -r -s "$SCREENSHOT_DIR"
else
    echo "✗ Screenshot-Tool nicht verfügbar"
    exit 1
fi
EOF
    chmod +x ~/.local/bin/screenshot.sh
    print_success "screenshot.sh erstellt"
    
    print_section "Erstelle pdf-merge.sh"
    cat > ~/.local/bin/pdf-merge.sh << 'EOF'
#!/bin/bash
if [[ $# -lt 2 ]]; then
    echo "Usage: pdf-merge.sh output.pdf input1.pdf input2.pdf ..."
    exit 1
fi

OUTPUT="$1"
shift

if command -v pdfarranger &>/dev/null; then
    pdfarranger "$@" -o "$OUTPUT"
    echo "✓ PDFs zusammengeführt: $OUTPUT"
else
    echo "✗ pdfarranger nicht installiert"
    exit 1
fi
EOF
    chmod +x ~/.local/bin/pdf-merge.sh
    print_success "pdf-merge.sh erstellt"
    
    print_section "Erstelle docker-cleanup.sh"
    cat > ~/.local/bin/docker-cleanup.sh << 'EOF'
#!/bin/bash
echo "🐳 Bereinige Docker..."
docker system prune -a --volumes -f
echo "✓ Docker bereinigt"
EOF
    chmod +x ~/.local/bin/docker-cleanup.sh
    print_success "docker-cleanup.sh erstellt"
}

# ============================================================================
# ZSHRC CONFIGURATION
# ============================================================================
setup_zshrc() {
    print_header "ZSH-KONFIGURATION"
    
    if [[ ! -f ~/.zshrc ]]; then
        print_section "Erstelle ~/.zshrc"
        cat > ~/.zshrc << 'EOF'
# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker python pip npm kubectl helm)
source $ZSH/oh-my-zsh.sh

# Starship Prompt (optional)
# eval "$(starship init zsh)"

# Aliases
alias ls='exa -la'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias du='dust'
alias htop='glances'
alias docker='podman'

# Path
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Python
export PYTHONPATH="$HOME/.local/lib/python3.11/site-packages:$PYTHONPATH"

# Node
export NODE_PATH="$HOME/.local/lib/node_modules:$NODE_PATH"

# Editor
export EDITOR='vim'
export VISUAL='code'

# Git
git config --global core.editor vim
git config --global pull.rebase false

# Autocomplete
source <(kubectl completion zsh 2>/dev/null || true)
source <(docker completion zsh 2>/dev/null || true)
EOF
        print_success "~/.zshrc erstellt"
    else
        print_warning "~/.zshrc existiert bereits (nicht überschrieben)"
    fi
}

# ============================================================================
# FINAL SUMMARY
# ============================================================================
print_final_summary() {
    print_header "✓ INSTALLATION ABGESCHLOSSEN"
    
    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════════╗${NC}
${GREEN}║           DESKTOP SUITE ERFOLGREICH INSTALLIERT            ║${NC}
${GREEN}╚════════════════════════════════════════════════════════════╝${NC}

${BLUE}📁 TRANSKRIPTION & SPRACHE:${NC}
   whisper --help                 # OpenAI Whisper
   python -m vosk                 # Offline Sprach-zu-Text
   ~/.local/bin/transcribe-audio.sh audio.mp3

${BLUE}📸 SCREENSHOT & PDF:${NC}
   flameshot gui                  # Screenshot mit GUI
   spectacle                      # KDE Screenshot-Tool
   qpdfview document.pdf          # PDF-Viewer
   pdfarranger                    # PDF-Bearbeitung
   ~/.local/bin/screenshot.sh     # Screenshot-Shortcut
   ~/.local/bin/pdf-merge.sh output.pdf in1.pdf in2.pdf

${BLUE}💾 FESTPLATTE & ANALYSE:${NC}
   filelight /                    # Visuelle Analyse (kreisförmig)
   ncdu /                         # Terminal TreeMap-Analyse
   baobab                         # GNOME Disk Usage Analyzer
   ~/.local/bin/analyze-disk.sh   # Schnelle Analyse

${BLUE}💿 BACKUP-AUTOMATISIERUNG:${NC}
   kopia ui                       # Kopia Backup UI (http://localhost:51515)
   restic init                    # Restic Backup initialisieren
   borg init                      # BorgBackup initialisieren
   backintime                     # Back In Time GUI
   ~/.local/bin/backup-system.sh  # Automatisches Backup

${BLUE}🔧 ENTWICKLER-TOOLS:${NC}
   docker run hello-world         # Docker Test
   psql                           # PostgreSQL Client
   code .                         # VS Code
   git lfs install                # Git LFS aktivieren
   go version                     # Go Version
   rustc --version                # Rust Version
   ruby --version                 # Ruby Version

${BLUE}🌐 BROWSER & EXTENSIONS:${NC}
   firefox                        # Firefox starten
   chromium                       # Chromium starten
   
   Extensions installieren:
   • Nimbus Screenshot (Firefox)
   • Fireshot (Chrome)
   • Web Captioner
   • Otter.ai Meeting Notes

${BLUE}💻 TERMINAL & SHELL:${NC}
   exec zsh                       # Zu Zsh wechseln
   starship config edit           # Starship konfigurieren
   tmux new-session               # Tmux starten
   alacritty                      # Alacritty Terminal

${BLUE}🐳 CONTAINER:${NC}
   docker ps                      # Docker Container auflisten
   podman ps                      # Podman Container auflisten
   docker-compose up              # Docker Compose starten
   ~/.local/bin/docker-cleanup.sh # Docker aufräumen

${BLUE}📊 PYTHON DATA SCIENCE:${NC}
   jupyter lab                    # Jupyter Lab starten
   python -m pip list --user      # Installierte Packages
   poetry new myproject           # Neues Poetry-Projekt

${BLUE}⚡ SYSTEM-MONITORING:${NC}
   htop                           # Prozess-Monitor
   glances                        # System-Monitor (erweitert)
   iotop                          # Disk I/O Monitor
   nethogs                        # Netzwerk-Monitor
   nvtop                          # GPU-Monitor

${BLUE}🛠️  ZUSÄTZLICHE COMMANDS:${NC}
   which lsd                      # Besseres ls
   which bat                      # Besserer cat
   which fd                       # Besseres find
   which rg                       # Besseres grep
   which dust                     # Besseres du
   which fzf                      # Fuzzy Finder
   which tldr                     # Schnelle Hilfe

${YELLOW}⚠️  WICHTIGE NÄCHSTE SCHRITTE:${NC}

   1. Starte neue Shell:
      ${CYAN}exec \$SHELL${NC}

   2. Überprüfe Docker-Zugriff:
      ${CYAN}groups | grep docker${NC}
      (Falls nicht drin: Logout/Login erforderlich)

   3. Konfiguriere Backups:
      ${CYAN}kopia ui${NC}        # oder restic, oder backintime

   4. Installiere Browser-Extensions:
      Firefox: Addons → Nimbus Screenshot, Web Captioner
      Chrome: Chrome Web Store → Fireshot, GoFullPage

   5. Konfiguriere Git:
      ${CYAN}git config --global user.name "Dein Name"${NC}
      ${CYAN}git config --global user.email "deine@email.com"${NC}

   6. Aktiviere Zsh als Standard-Shell:
      ${CYAN}chsh -s /bin/zsh${NC}

   7. Starte Docker Service (falls noch nicht aktiv):
      ${CYAN}sudo systemctl start docker${NC}

   8. Erstelle PostgreSQL-Datenbank:
      ${CYAN}createdb research_dev${NC}

${MAGENTA}📚 DOKUMENTATION & LINKS:${NC}

   Flameshot        https://flameshot.org
   Kopia            https://kopia.io
   Whisper          https://github.com/openai/whisper
   Vosk             https://alphacephei.com/vosk
   Arch Wiki        https://wiki.archlinux.org
   EndeavourOS Docs https://discovery.endeavouros.com
   Docker Docs      https://docs.docker.com
   PostgreSQL Docs  https://www.postgresql.org/docs

${MAGENTA}📖 ERSTE SCHRITTE MIT DEN TOOLS:${NC}

   Whisper Transkription:
      ${CYAN}whisper video.mp4 --language de --output_format txt${NC}

   Disk-Analyse:
      ${CYAN}ncdu / --exclude /mnt --exclude /media${NC}

   Backup mit Kopia:
      ${CYAN}kopia repository create filesystem --path /mnt/backup${NC}
      ${CYAN}kopia snapshot create${NC}

   Python Jupyter:
      ${CYAN}jupyter lab ~/.local/lib/python3.11/site-packages${NC}

   Docker Container:
      ${CYAN}docker run -it ubuntu:latest bash${NC}

${GREEN}═════════════════════════════════════════════════════════════${NC}
${GREEN}Viel Erfolg! 🚀${NC}
${GREEN}═════════════════════════════════════════════════════════════${NC}

EOF
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
main() {
    clear
    
    cat << 'EOF'
  ██████╗ ███████╗███████╗██╗  ██╗████████╗ ██████╗ ██████╗ 
  ██╔══██╗██╔════╝██╔════╝██║ ██╔╝╚══██╔══╝██╔════╝██╔═══██╗
  ██║  ██║█████╗  ███████╗██████╔╝   ██║   ██║     ██║   ██║
  ██║  ██║██╔══╝  ╚════██║██╔═██╗   ██║   ██║     ██║   ██║
  ██████╔╝███████╗███████║██║  ██╗  ██║   ╚██████╗╚██████╔╝
  ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝  ╚═╝    ╚═════╝ ╚═════╝ 
                                                              
  COMPLETE DESKTOP SUITE FOR ENDEAVOUROS
  One-Script Installation für alle TOP-Tools 2026
  
  Features:
  ✓ Transkription (Whisper, Vosk)
  ✓ Screenshots & PDF (Flameshot, PDFArranger)
  ✓ Festplatte (Filelight, ncdu, Diskhoji)
  ✓ Backup (Kopia, restic, BorgBackup)
  ✓ Entwickler (Docker, PostgreSQL, Code)
  ✓ Python Data Science (Jupyter, NumPy, Pandas)
  ✓ Terminal Tools (Zsh, Starship, Tmux)
  ✓ Browser (Firefox, Chromium)
EOF

    echo ""
    print_warning "Dieses Skript wird:"
    echo "  • Pacman aktualisieren"
    echo "  • yay (AUR Helper) installieren"
    echo "  • 80+ Packages installieren"
    echo "  • ~10-30 Minuten dauern"
    echo "  • ~5-10 GB Festplatte benötigen"
    echo ""
    
    print_warning "Fortfahren? (y/N)"
    read -r response
    [[ ! "$response" =~ ^[Yy]$ ]] && { echo "Abgebrochen."; exit 0; }
    
    check_system
    initial_setup
    install_aur_helper
    install_core_packages
    install_transcription_tools
    install_screenshot_pdf_tools
    install_disk_tools
    install_backup_tools
    install_dev_tools
    install_browsers
    install_python_stack
    install_terminal_tools
    install_container_tools
    setup_configurations
    create_helper_scripts
    setup_zshrc
    print_final_summary
    
    print_info "Installation abgeschlossen!"
    print_warning "Starte neue Shell: exec \$SHELL"
}

# Catch errors
trap 'print_error "Fehler bei Installation"; exit 1' ERR

# Run main
main "$@"
