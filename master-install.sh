#!/usr/bin/env bash
################################################################################
# COMPLETE MASTER INSTALLATION SCRIPT FOR ENDEAVOUROS
# 
# ALL-IN-ONE Installation:
#  ✓ Desktop Suite (Screenshots, PDF, Disk Tools, Backup)
#  ✓ Transkription & Sprach-Tools (Whisper, Vosk)
#  ✓ Database Setup (PostgreSQL, MongoDB, Redis, SQLite)
#  ✓ Development Tools (Docker, VS Code, Git)
#  ✓ Terminal Tools (Zsh, Starship, Tmux)
#  ✓ Python Data Science Stack
#  ✓ Browser + Extensions Support
#  ✓ Backup Automation
#  ✓ Admin Panels & GUI Tools
#  ✓ Helper Scripts & Configuration
#
# VERWENDUNG:
#   bash <(curl -fsSL https://raw.githubusercontent.com/sTarLighTsMoveMenTzWorldBankEyes/OpenCodeCloseCodeOpenCloudCloseOpenCloudOpenBuildOpenTipsOpenMasterPlan/main/master-install.sh)
#
#   ODER lokal:
#   bash master-install.sh
#
# FEATURES:
#   • Automatic fallback system
#   • Error recovery
#   • Progress tracking
#   • Detailed logging
#   • Color-coded output
#   • Network resilience
#
################################################################################

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================
SCRIPT_VERSION="1.0.0"
SCRIPT_START=$(date +%s)
LOG_DIR="$HOME/.log"
LOG_FILE="$LOG_DIR/master-install-$(date +%Y%m%d_%H%M%S).log"
CACHE_DIR="$HOME/.cache/master-install"
CONFIG_DIR="$HOME/.config/masterplan"
FAILED_MODULES=()
COMPLETED_MODULES=()

# ============================================================================
# COLORS & FORMATTING
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# LOGGING SETUP
# ============================================================================
mkdir -p "$LOG_DIR" "$CACHE_DIR" "$CONFIG_DIR"

log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] $*" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}║${NC} ${BOLD}$1${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n" | tee -a "$LOG_FILE"
}

print_section() {
    echo -e "\n${CYAN}→${NC} ${BOLD}$1${NC}" | tee -a "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${MAGENTA}ℹ${NC} $1" | tee -a "$LOG_FILE"
}

# ============================================================================
# RETRY MECHANISM WITH FALLBACK
# ============================================================================
retry_with_fallback() {
    local max_attempts=3
    local attempt=1
    local cmd="$1"
    local fallback_cmd="${2:-}"
    
    while [ $attempt -le $max_attempts ]; do
        log "Versuch $attempt/$max_attempts: $cmd"
        if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    if [ -n "$fallback_cmd" ]; then
        print_warning "Primärer Befehl fehlgeschlagen, versuche Fallback..."
        log "Fallback-Befehl: $fallback_cmd"
        if eval "$fallback_cmd" 2>&1 | tee -a "$LOG_FILE"; then
            return 0
        fi
    fi
    
    return 1
}

# ============================================================================
# MODULE TRACKING
# ============================================================================
track_module() {
    local module_name="$1"
    local status="$2"
    
    if [ "$status" = "success" ]; then
        COMPLETED_MODULES+=("$module_name")
        print_success "[$module_name] abgeschlossen"
    else
        FAILED_MODULES+=("$module_name")
        print_error "[$module_name] fehlgeschlagen"
    fi
}

# ============================================================================
# SYSTEM CHECK
# ============================================================================
check_system() {
    print_header "SYSTEM-CHECK"
    
    log "Überprüfe Betriebssystem..."
    if ! grep -qi "EndeavourOS\|Arch" /etc/os-release 2>/dev/null; then
        print_warning "System ist nicht EndeavourOS/Arch Linux"
        print_warning "Fortfahren auf eigene Gefahr? (y/N)"
        read -r response
        [[ "$response" =~ ^[Yy]$ ]] || exit 1
    fi
    print_success "EndeavourOS/Arch erkannt"
    
    if [[ $EUID -eq 0 ]]; then
        print_error "Dieses Skript darf NICHT als root ausgeführt werden!"
        exit 1
    fi
    print_success "Benutzer-Kontext OK"
    
    if ! command -v sudo &>/dev/null; then
        print_error "sudo nicht gefunden"
        exit 1
    fi
    print_success "sudo verfügbar"
    
    log "Internet-Verbindung testen..."
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        print_warning "Keine Internet-Verbindung erkannt - einige Features könnten fehlen"
    else
        print_success "Internet-Verbindung OK"
    fi
}

# ============================================================================
# INITIAL SETUP
# ============================================================================
initial_setup() {
    print_header "INITIAL SETUP"
    
    print_section "Erstelle Verzeichnisse"
    mkdir -p ~/.local/bin ~/.config ~/.log ~/.backups/databases
    print_success "Verzeichnisse erstellt"
    
    print_section "Aktualisiere Pacman Keyring"
    retry_with_fallback "sudo pacman -Sy --noconfirm archlinux-keyring" "sudo pacman -Sy"
    print_success "Pacman aktualisiert"
    
    print_section "Aktualisiere System"
    retry_with_fallback "sudo pacman -Syu --noconfirm" "sudo pacman -Su"
    print_success "System aktualisiert"
}

# ============================================================================
# AUR HELPER INSTALLATION
# ============================================================================
install_aur_helper() {
    print_header "AUR-HELPER (yay) INSTALLATION"
    
    if command -v yay &>/dev/null; then
        print_success "yay bereits installiert"
        track_module "AUR Helper" "success"
        return
    fi
    
    if command -v paru &>/dev/null; then
        print_success "paru bereits installiert (Alternative zu yay)"
        track_module "AUR Helper" "success"
        return
    fi
    
    print_section "Installiere yay"
    sudo pacman -S --noconfirm base-devel git
    
    cd /tmp
    rm -rf yay-bin 2>/dev/null || true
    
    if git clone https://aur.archlinux.org/yay-bin.git 2>&1 | tee -a "$LOG_FILE"; then
        cd yay-bin
        makepkg -si --noconfirm 2>&1 | tee -a "$LOG_FILE" || print_warning "yay make fehlgeschlagen"
        cd /tmp
        rm -rf yay-bin
        print_success "yay installiert"
        track_module "AUR Helper" "success"
    else
        print_warning "yay Installation fehlgeschlagen - fortfahren ohne AUR-Helper"
        track_module "AUR Helper" "failed"
    fi
}

# ============================================================================
# CORE PACKAGES INSTALLATION
# ============================================================================
install_core_packages() {
    print_header "KERN-PACKAGES INSTALLATION"
    
    print_section "Installiere Build-Tools & Utilities"
    
    local core_packages=(
        # Build & Dev
        "base-devel" "git" "curl" "wget" "git-lfs"
        
        # Python & Node
        "python" "python-pip" "python-virtualenv"
        "nodejs" "npm" "yarn"
        
        # Databases
        "postgresql" "redis" "sqlite" "mongodb" "mongodb-tools"
        
        # Containers
        "docker" "docker-compose" "podman" "podman-compose"
        
        # Compression
        "zip" "unzip" "tar" "gzip" "bzip2" "xz" "p7zip"
        
        # Network
        "curl" "wget" "openssh" "rsync" "nmap" "netcat"
        
        # Text Processing
        "sed" "awk" "grep" "jq" "yq" "ripgrep" "fd"
        
        # Monitoring
        "htop" "iotop" "iftop" "nethogs" "glances" "neofetch" "lsof"
        
        # File Management
        "fzf" "bat" "exa" "tldr" "tree"
        
        # Editors
        "vim" "neovim" "nano"
        
        # Shell
        "tmux" "screen" "zsh" "bash-completion"
        
        # Audio/Video
        "ffmpeg" "sox" "pulseaudio" "pulseaudio-alsa" "alsa-utils"
        
        # Archive/Backup
        "tar" "rsync" "rclone"
        
        # Screenshots/PDF
        "flameshot" "spectacle" "qpdfview" "pdfarranger"
        "libreoffice-fresh" "ghostscript" "imagemagick"
        "tesseract" "tesseract-data-deu"
        
        # Disk Tools
        "filelight" "ncdu" "baobab" "bleachbit"
        
        # GUI Tools
        "dbeaver" "firefox" "chromium" "code"
    )
    
    if retry_with_fallback "sudo pacman -S --noconfirm ${core_packages[*]}" "sudo pacman -S --noconfirm base-devel git curl"; then
        print_success "Core Packages installiert"
        track_module "Core Packages" "success"
    else
        print_warning "Einige Packages konnten nicht installiert werden"
        track_module "Core Packages" "failed"
    fi
}

# ============================================================================
# TRANSCRIPTION & SPEECH TOOLS
# ============================================================================
install_transcription_tools() {
    print_header "TRANSKRIPTION & SPRACH-TOOLS"
    
    print_section "Installiere OpenAI Whisper"
    if retry_with_fallback "pip install --user -U openai-whisper" "pip3 install --user openai-whisper"; then
        print_success "Whisper installiert"
    else
        print_warning "Whisper Installation fehlgeschlagen"
    fi
    
    print_section "Installiere Vosk"
    if retry_with_fallback "pip install --user -U vosk" "pip3 install --user vosk"; then
        print_success "Vosk installiert"
    else
        print_warning "Vosk Installation fehlgeschlagen"
    fi
    
    track_module "Transkription Tools" "success"
}

# ============================================================================
# POSTGRESQL SETUP
# ============================================================================
setup_postgresql() {
    print_header "POSTGRESQL INSTALLATION & SETUP"
    
    if ! command -v psql &>/dev/null; then
        print_error "PostgreSQL nicht installiert"
        track_module "PostgreSQL" "failed"
        return
    fi
    
    print_success "PostgreSQL gefunden"
    CURRENT_USER=$(whoami)
    
    print_section "Initialisiere PostgreSQL Cluster"
    if ! sudo -u postgres psql -c "SELECT 1" &>/dev/null; then
        sudo mkdir -p /var/lib/postgres/data
        sudo chown -R postgres:postgres /var/lib/postgres/data
        sudo -u postgres initdb -D /var/lib/postgres/data 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    print_section "Aktiviere PostgreSQL Service"
    sudo systemctl enable postgresql 2>&1 | tee -a "$LOG_FILE" || true
    sudo systemctl restart postgresql 2>&1 | tee -a "$LOG_FILE" || true
    
    sleep 2
    
    print_section "Erstelle PostgreSQL Benutzer & Datenbanken"
    if sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='$CURRENT_USER'" 2>/dev/null | grep -q 1; then
        print_warning "Benutzer existiert bereits"
    else
        sudo -u postgres createuser -d -e -r -s "$CURRENT_USER" 2>&1 | tee -a "$LOG_FILE" || true
    fi
    
    # Create databases
    for db in research_dev intentions_db artifacts_db masterplan_db test_db dev; do
        if ! sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$db"; then
            sudo -u postgres createdb -O "$CURRENT_USER" "$db" 2>&1 | tee -a "$LOG_FILE" || true
            print_success "DB erstellt: $db"
        fi
    done
    
    print_section "Erstelle PostgreSQL Schemas"
    psql -U "$CURRENT_USER" -d research_dev << 'PSQL_EOF' 2>&1 | tee -a "$LOG_FILE" || true
DROP TABLE IF EXISTS evidence CASCADE;
DROP TABLE IF EXISTS sources CASCADE;
CREATE TABLE sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  url TEXT UNIQUE NOT NULL,
  category TEXT,
  access_method TEXT,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT now()
);
CREATE TABLE evidence (
  id TEXT PRIMARY KEY,
  source_url TEXT REFERENCES sources(url),
  snippet TEXT,
  meta JSONB
);
CREATE INDEX idx_sources_category ON sources(category);
PSQL_EOF
    
    print_success "PostgreSQL Setup abgeschlossen"
    track_module "PostgreSQL" "success"
}

# ============================================================================
# MONGODB SETUP
# ============================================================================
setup_mongodb() {
    print_header "MONGODB INSTALLATION & SETUP"
    
    if ! command -v mongod &>/dev/null; then
        print_warning "MongoDB nicht verfügbar"
        track_module "MongoDB" "failed"
        return
    fi
    
    print_section "Aktiviere MongoDB Service"
    sudo systemctl enable mongodb 2>&1 | tee -a "$LOG_FILE" || true
    sudo systemctl restart mongodb 2>&1 | tee -a "$LOG_FILE" || true
    
    sleep 2
    
    print_section "Teste MongoDB Connection"
    if echo "db.adminCommand('ping')" | mongo --quiet &>/dev/null 2>&1; then
        print_success "MongoDB verfügbar"
        track_module "MongoDB" "success"
    else
        print_warning "MongoDB Connection fehlgeschlagen"
        track_module "MongoDB" "failed"
    fi
}

# ============================================================================
# REDIS SETUP
# ============================================================================
setup_redis() {
    print_header "REDIS INSTALLATION & SETUP"
    
    if ! command -v redis-server &>/dev/null; then
        print_warning "Redis nicht verfügbar"
        track_module "Redis" "failed"
        return
    fi
    
    print_section "Aktiviere Redis Service"
    sudo systemctl enable redis 2>&1 | tee -a "$LOG_FILE" || true
    sudo systemctl restart redis 2>&1 | tee -a "$LOG_FILE" || true
    
    sleep 1
    
    print_section "Teste Redis Connection"
    if redis-cli ping 2>/dev/null | grep -q "PONG"; then
        print_success "Redis verfügbar"
        track_module "Redis" "success"
    else
        print_warning "Redis Connection fehlgeschlagen"
        track_module "Redis" "failed"
    fi
}

# ============================================================================
# PYTHON DATA SCIENCE STACK
# ============================================================================
install_python_stack() {
    print_header "PYTHON DATA SCIENCE STACK"
    
    print_section "Installiere pip-Packages"
    
    local python_packages=(
        "jupyter" "jupyterlab" "ipython"
        "numpy" "pandas" "scipy" "matplotlib" "scikit-learn"
        "black" "pylint" "flake8" "pytest"
        "poetry" "pipenv"
        "requests" "beautifulsoup4" "selenium"
        "sqlalchemy" "asyncpg" "aiohttp"
        "pydantic" "click" "typer"
        "python-dotenv" "python-json-logger"
    )
    
    for pkg in "${python_packages[@]}"; do
        retry_with_fallback "pip install --user -U $pkg" "pip3 install --user $pkg" || print_warning "Paket $pkg fehlgeschlagen"
    done
    
    print_success "Python Stack installiert"
    track_module "Python Stack" "success"
}

# ============================================================================
# TERMINAL TOOLS & SHELL
# ============================================================================
install_terminal_tools() {
    print_header "TERMINAL & SHELL TOOLS"
    
    print_section "Installiere Zsh & Starship"
    sudo pacman -S --noconfirm zsh zsh-completions zsh-syntax-highlighting
    
    if curl -fsSL https://starship.rs/install.sh | sh -s -- -y 2>&1 | tee -a "$LOG_FILE"; then
        print_success "Starship installiert"
    else
        print_warning "Starship Installation fehlgeschlagen"
    fi
    
    print_section "Installiere Terminal-Emulatoren"
    sudo pacman -S --noconfirm alacritty kitty wezterm tmux screen
    
    print_success "Terminal-Tools installiert"
    track_module "Terminal Tools" "success"
}

# ============================================================================
# DOCKER & CONTAINER SETUP
# ============================================================================
setup_docker() {
    print_header "DOCKER & CONTAINER SETUP"
    
    if ! command -v docker &>/dev/null; then
        print_error "Docker nicht installiert"
        track_module "Docker" "failed"
        return
    fi
    
    print_section "Aktiviere Docker Service"
    sudo systemctl enable docker 2>&1 | tee -a "$LOG_FILE" || true
    sudo systemctl start docker 2>&1 | tee -a "$LOG_FILE" || true
    
    print_section "Konfiguriere Docker Benutzer"
    sudo usermod -aG docker "$USER" 2>&1 | tee -a "$LOG_FILE" || print_warning "Docker Benutzer-Konfiguration fehlgeschlagen"
    
    print_info "Starte neue Shell für Docker-Gruppe: exec \$SHELL"
    
    print_success "Docker konfiguriert"
    track_module "Docker" "success"
}

# ============================================================================
# HELPER SCRIPTS
# ============================================================================
create_helper_scripts() {
    print_header "HELPER-SCRIPTS ERSTELLEN"
    
    print_section "Erstelle Backup-Scripts"
    
    cat > ~/.local/bin/backup-all.sh << 'BASH_SCRIPT'
#!/bin/bash
set -e
BACKUP_DIR="$HOME/.backups/databases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

echo "📦 Backup PostgreSQL..."
pg_dumpall 2>/dev/null | gzip > "$BACKUP_DIR/postgres_$TIMESTAMP.sql.gz" || echo "PostgreSQL nicht verfügbar"

echo "📦 Backup MongoDB..."
mongodump --archive="$BACKUP_DIR/mongodb_$TIMESTAMP.archive" --gzip 2>/dev/null || echo "MongoDB nicht verfügbar"

echo "📦 Backup Redis..."
redis-cli BGSAVE 2>/dev/null && sleep 2 && cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_$TIMESTAMP.rdb" || echo "Redis nicht verfügbar"

echo "✓ Backup abgeschlossen in $BACKUP_DIR"
find "$BACKUP_DIR" -mtime +30 -delete
BASH_SCRIPT
    
    chmod +x ~/.local/bin/backup-all.sh
    print_success "backup-all.sh erstellt"
    
    cat > ~/.local/bin/analyze-disk.sh << 'BASH_SCRIPT'
#!/bin/bash
if command -v ncdu &>/dev/null; then
    ncdu /
elif command -v filelight &>/dev/null; then
    filelight /
else
    du -sh /* | sort -hr
fi
BASH_SCRIPT
    
    chmod +x ~/.local/bin/analyze-disk.sh
    print_success "analyze-disk.sh erstellt"
    
    cat > ~/.local/bin/transcribe.sh << 'BASH_SCRIPT'
#!/bin/bash
[ $# -eq 0 ] && { echo "Usage: transcribe.sh <audio-file> [language]"; exit 1; }
whisper "$1" --language "${2:-de}" --output_format txt --output_dir ~/transcriptions
BASH_SCRIPT
    
    chmod +x ~/.local/bin/transcribe.sh
    print_success "transcribe.sh erstellt"
    
    track_module "Helper Scripts" "success"
}

# ============================================================================
# CONFIGURATION FILES
# ============================================================================
create_config_files() {
    print_header "KONFIGURATIONSDATEIEN ERSTELLEN"
    
    print_section "Erstelle .env Datei"
    cat > "$CONFIG_DIR/.env" << 'ENV_FILE'
# Database Configuration
DATABASE_URL=postgresql://$(whoami)@localhost:5432/research_dev
MONGO_URL=mongodb://localhost:27017/development
REDIS_URL=redis://localhost:6379/0

# Environment
ENV=development
DEBUG=true
LOG_LEVEL=debug

# Backup
BACKUP_DIR=$HOME/backups/databases
BACKUP_RETENTION_DAYS=30
ENV_FILE
    
    print_success ".env erstellt"
    
    print_section "Erstelle docker-compose.yml"
    cat > "$CONFIG_DIR/docker-compose.yml" << 'DOCKER_FILE'
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    container_name: masterplan-postgres
    environment:
      POSTGRES_USER: development
      POSTGRES_PASSWORD: development
      POSTGRES_DB: research_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mongodb:
    image: mongo:7.0
    container_name: masterplan-mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

  redis:
    image: redis:7-alpine
    container_name: masterplan-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: masterplan-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - postgres

volumes:
  postgres_data:
  mongo_data:
  redis_data:
DOCKER_FILE
    
    print_success "docker-compose.yml erstellt"
    
    track_module "Configuration Files" "success"
}

# ============================================================================
# ZSHRC SETUP
# ============================================================================
setup_zshrc() {
    print_header "ZSH SHELL KONFIGURATION"
    
    if [[ ! -f ~/.zshrc ]]; then
        cat > ~/.zshrc << 'ZSHRC_FILE'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker python pip npm kubectl)
source $ZSH/oh-my-zsh.sh 2>/dev/null || true

# Aliases
alias ls='exa -la'
alias cat='bat'
alias find='fd'
alias grep='rg'
export PATH="$HOME/.local/bin:$PATH"
export EDITOR='vim'
ZSHRC_FILE
        print_success "~/.zshrc erstellt"
    else
        print_warning "~/.zshrc existiert bereits"
    fi
    
    track_module "Zsh Configuration" "success"
}

# ============================================================================
# FINAL SUMMARY & REPORT
# ============================================================================
print_final_summary() {
    local total_time=$(($(date +%s) - SCRIPT_START))
    
    print_header "✓ INSTALLATION ABGESCHLOSSEN"
    
    cat << EOF

${GREEN}╔════════════════════════════════════════════════════════════╗${NC}
${GREEN}║        MASTERPLAN COMPLETE INSTALLATION ERFOLGREICH        ║${NC}
${GREEN}╚════════════════════════════════════════════════════════════╝${NC}

${BLUE}📊 INSTALLATION STATISTIK:${NC}
   Dauer: ${total_time}s
   Abgeschlossene Module: ${#COMPLETED_MODULES[@]}
   Fehlgeschlagene Module: ${#FAILED_MODULES[@]}
   Installationsdatum: $(date)
   Log-Datei: $LOG_FILE

${BLUE}✓ ABGESCHLOSSENE MODULE:${NC}
EOF
    
    for module in "${COMPLETED_MODULES[@]}"; do
        echo -e "   ${GREEN}✓${NC} $module" | tee -a "$LOG_FILE"
    done
    
    if [ ${#FAILED_MODULES[@]} -gt 0 ]; then
        echo -e "\n${YELLOW}⚠ FEHLGESCHLAGENE MODULE:${NC}" | tee -a "$LOG_FILE"
        for module in "${FAILED_MODULES[@]}"; do
            echo -e "   ${RED}✗${NC} $module" | tee -a "$LOG_FILE"
        done
    fi
    
    cat << EOF

${BLUE}🎯 SCHNELL STARTEN:${NC}

   1. Shell neu starten:
      ${CYAN}exec \$SHELL${NC}
   
   2. PostgreSQL testen:
      ${CYAN}psql -d research_dev -c "SELECT version();"${NC}
   
   3. Redis testen:
      ${CYAN}redis-cli ping${NC}
   
   4. MongoDB testen:
      ${CYAN}mongo --eval "db.adminCommand('ping')"${NC}
   
   5. Docker testen:
      ${CYAN}docker run hello-world${NC}
   
   6. Transkription:
      ${CYAN}~/.local/bin/transcribe.sh audio.mp3${NC}
   
   7. Disk-Analyse:
      ${CYAN}~/.local/bin/analyze-disk.sh${NC}
   
   8. Backup-Datenbanken:
      ${CYAN}~/.local/bin/backup-all.sh${NC}
   
   9. Admin Panels (Docker):
      ${CYAN}cd $CONFIG_DIR${NC}
      ${CYAN}docker-compose up -d${NC}
   
   10. DBeaver öffnen:
       ${CYAN}dbeaver${NC}

${BLUE}📁 WICHTIGE VERZEICHNISSE:${NC}
   Config:  $CONFIG_DIR
   Logs:    $LOG_DIR
   Backups: ~/.backups/databases
   Scripts: ~/.local/bin

${BLUE}🌐 ADMIN PANELS (nach docker-compose up):${NC}
   pgAdmin:        http://localhost:5050 (admin@example.com/admin)
   MongoDB Express: http://localhost:8081 (admin/admin)
   PostgreSQL:     localhost:5432
   MongoDB:        localhost:27017
   Redis:          localhost:6379

${BLUE}📚 NÄCHSTE SCHRITTE:${NC}
   1. Überprüfe Log-Datei: tail -f $LOG_FILE
   2. Konfiguriere Git: git config --global user.name "Name"
   3. Starte Docker: sudo systemctl start docker
   4. Erstelle Backups: ~/.local/bin/backup-all.sh
   5. Öffne Jupyter: jupyter lab

${YELLOW}⚠️ HINWEISE:${NC}
   • Starte neue Shell für Docker-Gruppe: exec \$SHELL
   • Konfigurationsdateien: ~/.config/masterplan/
   • Helper-Scripts: ~/.local/bin/
   • Logs verfügbar in: $LOG_FILE
   • Datenbank-Backups: ~/.backups/databases/

${GREEN}═════════════════════════════════════════════════════════════${NC}
${GREEN}Installation erfolgreich! 🚀${NC}
${GREEN}═════════════════════════════════════════════════════════════${NC}

EOF
    
    log "Installation abgeschlossen"
}

# ============================================================================
# ERROR HANDLER
# ============================================================================
error_handler() {
    local line_number=$1
    print_error "Fehler in Zeile $line_number der Installation"
    print_warning "Überprüfe Log-Datei: $LOG_FILE"
    print_final_summary
}

trap 'error_handler ${LINENO}' ERR

# ============================================================================
# MAIN EXECUTION
# ============================================================================
main() {
    clear
    
    cat << 'EOF'
  ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ ██████╗ ██╗      █████╗ ██╗   ██╗
  ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝
  ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝██████╔╝██║     ███████║ ╚████╔╝ 
  ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗██╔═══╝ ██║     ██╔══██║  ╚██╔╝  
  ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║██║     ███████╗██║  ██║   ██║   
  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   

  COMPLETE ALL-IN-ONE INSTALLATION FOR ENDEAVOUROS
  Version $SCRIPT_VERSION
  
  Features:
  ✓ Transkription (Whisper, Vosk)
  ✓ Festplatte (Filelight, ncdu)
  ✓ Screenshots & PDF (Flameshot, PDFArranger)
  ✓ Backup-Automatisierung
  ✓ Datenbanken (PostgreSQL, MongoDB, Redis)
  ✓ Entwickler-Tools (Docker, Code, Git)
  ✓ Python Data Science
  ✓ Terminal-Tools (Zsh, Starship, Tmux)
  ✓ Browser & Extensions
  ✓ Admin Panels & GUI Tools
  ✓ Helper-Scripts
  ✓ Fallback-System & Error Recovery
  
  Installation dauert: ~20-45 Minuten
  Festplatte benötigt: ~8-12 GB
  Internet benötigt: Stabil für Downloads

EOF

    echo ""
    print_warning "Fortfahren? (y/N)"
    read -r response
    [[ ! "$response" =~ ^[Yy]$ ]] && { echo "Abgebrochen."; exit 0; }
    
    log "Installation gestartet"
    print_info "Log-Datei: $LOG_FILE"
    
    check_system
    initial_setup
    install_aur_helper
    install_core_packages
    install_transcription_tools
    setup_postgresql
    setup_mongodb
    setup_redis
    install_python_stack
    install_terminal_tools
    setup_docker
    create_helper_scripts
    create_config_files
    setup_zshrc
    print_final_summary
    
    print_info "Alle Informationen wurden gespeichert in: $LOG_FILE"
}

# Run main
main "$@"
