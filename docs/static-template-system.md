# Static Homepage Template System

## Overview

Pi-Commander uses a **template-based approach** for the static homepage to allow:
- ✅ Per-server customization
- ✅ Git-tracked template updates
- ✅ No conflicts when pulling updates

## How It Works

### Files

```
static/
├── index.html.template   (tracked in git)
├── index.html           (gitignored, per-server)
├── 404.html             (tracked in git)
└── README.md            (tracked in git)
```

### Workflow

**1. First Time Setup (Bootstrap)**

When you run `bootstrap.sh`, it automatically:
```bash
cp static/index.html.template static/index.html
```

**2. Customize Your Page**

Edit your local copy:
```bash
nano static/index.html
# Make changes
# Save
```

Your changes stay local and won't be committed to git.

**3. Pull Updates**

When you `git pull`:
- `index.html.template` gets updated with new features
- Your `index.html` stays unchanged
- No merge conflicts!

**4. Adopt Template Updates (Optional)**

If you want the new template:
```bash
cp static/index.html.template static/index.html
```

Or merge manually:
```bash
# Backup your version
cp static/index.html static/index.html.backup

# Copy new template
cp static/index.html.template static/index.html

# Manually merge your custom changes
nano static/index.html
```

## Why This Design?

### Problem We Solved

**Without template system:**
```
Server A: index.html (customized with company logo)
Server B: index.html (customized with personal branding)
Git: index.html (tracked)

Result: Merge conflicts on every git pull!
```

**With template system:**
```
Server A: index.html (gitignored, custom)
Server B: index.html (gitignored, custom)
Git: index.html.template (tracked)

Result: No conflicts, updates available when needed
```

## For Server Deployment

On your server, `static/index.html` is your custom page that:
- **Will NOT be overwritten** by git pull
- **Will NOT be committed** to the repository
- **Can be customized** without affecting other servers

## Bootstrap Behavior

The bootstrap script (`bootstrap.sh`) includes:

```bash
# Setup static page from template if needed
if [ ! -f "$REPO_DIR/static/index.html" ] && [ -f "$REPO_DIR/static/index.html.template" ]; then
    info "Setting up static homepage from template..."
    cp "$REPO_DIR/static/index.html.template" "$REPO_DIR/static/index.html"
    log "Static homepage created (customize in static/index.html)"
fi
```

**This means:**
- ✅ First install: Creates `index.html` from template
- ✅ Existing install: Keeps your custom `index.html` unchanged
- ✅ Manual update: Run `cp` command yourself

## GitIgnore Configuration

```gitignore
# Static files (custom per server)
static/index.html
static/custom.html

# Keep templates in git
!static/index.html.template
!static/404.html
```

**Result:**
- `index.html` → Never committed
- `index.html.template` → Always tracked
- `404.html` → Always tracked

## Use Cases

### Use Case 1: Standard User
"I just want the default page"

**Action:** Do nothing, bootstrap handles it
**Result:** Beautiful default status page

### Use Case 2: Customizer
"I want to add my own branding"

**Action:**
```bash
nano static/index.html
# Add logo, change colors, etc.
```
**Result:** Custom page, safe from git

### Use Case 3: Multi-Server
"I run 3 servers with different pages"

**Action:**
```bash
# Server 1
nano static/index.html  # Personal branding

# Server 2
nano static/index.html  # Company branding

# Server 3
nano static/index.html  # Test environment
```
**Result:** Each server has unique page, no conflicts

### Use Case 4: Template Updater
"I want the new template features"

**Action:**
```bash
# See what changed
git diff static/index.html.template

# Adopt new template
cp static/index.html.template static/index.html

# Or merge custom changes
vimdiff static/index.html static/index.html.template
```
**Result:** Latest template with optional custom merge

## Testing

**Verify gitignore works:**
```bash
# Create custom page
echo "<h1>Custom</h1>" > static/index.html

# Check git status
git status

# Should NOT show index.html as changed
```

**Verify bootstrap works:**
```bash
# Remove existing page
rm static/index.html

# Run setup portion
if [ ! -f "static/index.html" ] && [ -f "static/index.html.template" ]; then
    cp static/index.html.template static/index.html
    echo "✓ Created from template"
fi
```

## Maintenance

**Update template (maintainers only):**
```bash
# Edit template
nano static/index.html.template

# Commit
git add static/index.html.template
git commit -m "feat: Improve status page template"
git push
```

**Users get update:**
```bash
git pull  # Gets new template
# Their index.html unchanged
```

## Summary

✅ **Template tracked in git** → Everyone gets updates  
✅ **Instance gitignored** → Per-server customization  
✅ **Bootstrap creates copy** → Works out of the box  
✅ **No merge conflicts** → Pull anytime safely  
✅ **Optional updates** → Adopt template when ready  

**Best of both worlds!** 🎉
