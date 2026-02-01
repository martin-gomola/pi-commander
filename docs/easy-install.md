# Easy Installation Methods

## For Fresh Servers

### Method 1: One Command (No Git Required)

**Use this on a truly fresh server:**
```bash
curl -fsSL tinyurl.com/picommander-install|bash
```

**What happens:**
1. Installs git automatically
2. Clones repository to ~/pi-commander
3. Runs installation


---

### Method 2: Clone & Run (Requires Git)

**If git is already installed:**
```bash
git clone https://tinyurl.com/picommander
cd pi-commander
./install.sh
```

**Or with full URL:**
```bash
git clone https://github.com/martin-gomola/pi-commander.git
cd pi-commander
./install.sh
```

**Note:** The script detects it's already in the repo and won't try to clone again.

---

---

## For Your Local Network

If you're setting up multiple servers on your local network, keep the setup script on your laptop:

**On your laptop:**
```bash
cd ~/Downloads
wget https://raw.githubusercontent.com/martin-gomola/pi-commander/main/setup
python3 -m http.server 8000
```

**On any new server:**
```bash
curl YOUR-LAPTOP-IP:8000/setup | bash
```

---
