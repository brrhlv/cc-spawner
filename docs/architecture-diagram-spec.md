# cc-spawner Architecture Diagram Specifications

## Brand Context
- **Aesthetic**: Cyberpunk Goth (from brrhlv brand)
- **Primary Color**: #7C3AED (Purple) - highlights, accents, interactive elements
- **Background**: #0C0C0F (Dark) - primary background
- **Text**: #D4D4D8 (Steel Light) - primary text
- **Secondary Text**: #A1A1AA (Steel) - secondary/body text
- **Borders**: #27272A (Border Gray)
- **Cards/Elevated**: #18181B (Elevated background)
- **Success**: #9CB92C (Peridot) - success indicators

## Diagram 1: Isolation Spectrum

### Layout
- Horizontal flow, left to right
- 4 boxes representing isolation levels
- Arrow progression between boxes
- cc-spawner position highlighted

### Content

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        ISOLATION SPECTRUM                                │
└─────────────────────────────────────────────────────────────────────────┘

┌───────────────┐    ┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  SAME USER    │───▶│  ENV VAR      │───▶│  DIFFERENT    │───▶│  DIFFERENT    │
│               │    │  OVERRIDE     │    │  USER         │    │  MACHINE      │
│               │    │               │    │               │    │               │
│ ❌ No         │    │ ⚠️  Partial   │    │ ✅ Full       │    │ ✅ Complete   │
│ Isolation     │    │ Isolation     │    │ Isolation     │    │ Isolation     │
│               │    │               │    │               │    │               │
│ Shared files  │    │ Same .claude  │    │ Separate:     │    │ Network       │
│ Same config   │    │ Different env │    │ • Home dir    │    │ separated     │
│ Same globals  │    │ Risky         │    │ • .claude     │    │               │
│               │    │               │    │ • npm globals │    │ Hardware      │
│               │    │               │    │ • Node/nvm    │    │ separated     │
└───────────────┘    └───────────────┘    └───────────────┘    └───────────────┘
                                                    ▲
                                                    │
                                          ┌─────────┴─────────┐
                                          │   cc-spawner      │
                                          │  operates here    │
                                          └───────────────────┘
```

### Styling Notes
- Purple (#7C3AED) highlight box around "Different User" level
- Purple arrow pointing to cc-spawner position indicator
- Checkmarks in success color (#9CB92C) for full/complete isolation
- Warning symbol in steel (#A1A1AA) for partial
- X mark in steel dark for no isolation

---

## Diagram 2: Spawn Workflow

### Layout
- Vertical or horizontal flow
- 6 sequential steps
- Each step: number → action → result
- Arrows connecting phases

### Content

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SPAWN WORKFLOW                                    │
└─────────────────────────────────────────────────────────────────────────┘

1️⃣  CREATE USER                    2️⃣  INIT PROFILE
    ┌─────────────────┐                 ┌─────────────────┐
    │ Windows User    │                 │ User Folders    │
    │ Account Created │────────────────▶│ Initialized     │
    │                 │                 │                 │
    │ • Username      │                 │ • AppData/      │
    │ • Password      │                 │ • Desktop/      │
    │ • Profile path  │                 │ • Documents/    │
    └─────────────────┘                 └─────────────────┘
             │                                   │
             └───────────────┬───────────────────┘
                             ▼

3️⃣  INSTALL NVM                    4️⃣  INSTALL NODE
    ┌─────────────────┐                 ┌─────────────────┐
    │ nvm-windows     │                 │ Node.js v22     │
    │ Portable Setup  │────────────────▶│ Per-User        │
    │                 │                 │                 │
    │ • No admin      │                 │ • nvm use 22    │
    │ • User AppData  │                 │ • npm ready     │
    │ • v1.2.2        │                 │ • Isolated      │
    └─────────────────┘                 └─────────────────┘
             │                                   │
             └───────────────┬───────────────────┘
                             ▼

5️⃣  INSTALL CLAUDE                 6️⃣  COPY CONFIG
    ┌─────────────────┐                 ┌─────────────────┐
    │ Claude Code CLI │                 │ .claude/        │
    │ Global Install  │────────────────▶│ Template Applied│
    │                 │                 │                 │
    │ • npm i -g      │                 │ • Template pick │
    │ • claude ready  │                 │ • API key       │
    │ • Isolated npm  │                 │ • Ready to test │
    └─────────────────┘                 └─────────────────┘
                                                 │
                                                 ▼
                                        ┌─────────────────┐
                                        │  ✅ READY       │
                                        │  User can login │
                                        └─────────────────┘
```

### Styling Notes
- Purple background for step numbers (1️⃣ -6️⃣ )
- Steel light text for headings
- Steel text for details
- Success color (#9CB92C) for final "READY" state
- Arrows in purple (#7C3AED)
- Card backgrounds in elevated color (#18181B)
- Borders in #27272A

---

## Diagram 3: Directory Structure

### Layout
- Traditional file tree
- Icons for folders/files
- Annotations on right side

### Content

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     DIRECTORY STRUCTURE                                  │
└─────────────────────────────────────────────────────────────────────────┘

Spawner/
├── 📄 spawner                  # Bash CLI wrapper (executable)
├── 📄 spawner.ps1              # PowerShell core script (runs elevated)
├── ⚙️  config.json              # Configuration (templates, passwords, deps)
├── 📋 manifest.json            # User registry (tracks spawned users)
│
├── 📁 templates/               # Environment templates
│   ├── 📁 vanilla/             # Stock Claude Code - no PAI
│   │   └── 📁 .claude/
│   ├── 📁 pai-vanilla/         # Original PAI from Miessler
│   │   └── 📁 .claude/
│   ├── 📁 pai-starter/         # PAI framework starter kit
│   │   └── 📁 .claude/
│   └── 📁 pai-snapshot/        # Clone of admin's production PAI
│       └── 📁 .claude/
│
├── 📁 dependencies/            # Cached installers
│   ├── 📦 nvm-noinstall.zip
│   ├── 📦 node-v22.12.0-win-x64.zip
│   └── ✓  .downloaded
│
├── 📁 backups/                 # Auto-backups on despawn/respawn
│   └── 📦 Lab4_2026-01-21_14-30-00.zip
│
├── 📁 logs/                    # Operation logs
│   └── 📝 spawn-Lab4-2026-01-21.log
│
└── 📁 _config/                 # Legacy config
    └── 🔑 api-keys.env         # Anthropic API keys
```

### Styling Notes
- Folder icons in purple (#7C3AED)
- Executable files in steel light (#D4D4D8)
- Config files in steel (#A1A1AA)
- Comments/annotations in steel dark (#52525B)
- Monospace font (Fira Code style)
- Tree lines in border color (#27272A)

---

## Diagram 4: Environment Categories

### Layout
- 3 boxes side-by-side
- Each category with icon, name, description, details

### Content

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     ENVIRONMENT CATEGORIES                               │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│   🧪 LAB            │  │   🔧 DEV            │  │   🚀 PROD           │
│   EXPERIMENTAL      │  │   AUTOMATION        │  │   PRODUCTION        │
├─────────────────────┤  ├─────────────────────┤  ├─────────────────────┤
│                     │  │                     │  │                     │
│ Purpose:            │  │ Purpose:            │  │ Purpose:            │
│ Testing, breaking,  │  │ Headless automation │  │ Main user account   │
│ exploring configs   │  │ Script testing      │  │ Full PAI setup      │
│                     │  │ CI/CD runners       │  │                     │
│ Template:           │  │                     │  │ Template:           │
│ • vanilla (default) │  │ Template:           │  │ • pai-clone         │
│ • or any template   │  │ • vanilla only      │  │ • Full .claude/     │
│                     │  │ • Minimal overhead  │  │ • All skills/agents │
│ Lifespan:           │  │                     │  │                     │
│ Short (hours/days)  │  │ Lifespan:           │  │ Lifespan:           │
│ Reset often         │  │ Medium (weeks)      │  │ Permanent           │
│                     │  │ Stable baseline     │  │ Never despawn       │
│ Examples:           │  │                     │  │                     │
│ Lab1, Lab2, Lab3... │  │ Examples:           │  │ Examples:           │
│                     │  │ Dev1, AutoTest1     │  │ Admin (admin)     │
└─────────────────────┘  └─────────────────────┘  └─────────────────────┘
```

### Styling Notes
- Category icons in purple (#7C3AED)
- Card backgrounds in elevated (#18181B)
- Borders in #27272A
- Headings in steel light (#D4D4D8)
- Body text in steel (#A1A1AA)
- Purple accent on active/important items

---

## Diagram 5: What Gets Created (User Environment)

### Layout
- User home directory tree showing spawned environment
- Highlights key directories and files

### Content

```
┌─────────────────────────────────────────────────────────────────────────┐
│              WHAT GETS CREATED: C:\Users\Lab1\                          │
└─────────────────────────────────────────────────────────────────────────┘

C:\Users\Lab1\                          # New Windows user profile
│
├── 📁 .claude/                         # Claude Code configuration
│   ├── ⚙️  settings.json                # Claude settings
│   ├── 📋 history.jsonl                # Conversation history
│   ├── 🔑 .env                          # API keys (copied)
│   │
│   ├── 📁 skills/                      # Capabilities (if PAI template)
│   ├── 📁 agents/                      # Subagents (if PAI template)
│   ├── 📁 hooks/                       # Event triggers (if PAI template)
│   ├── 📁 commands/                    # Slash commands (if PAI template)
│   └── 📁 memory/                      # Session memory (if PAI template)
│
├── 📁 AppData/                         # User application data
│   ├── 📁 Local/
│   │   └── 📁 Temp/                    # Temp files
│   └── 📁 Roaming/
│       ├── 📁 nvm/                     # nvm-windows (portable)
│       │   ├── 📄 settings.txt
│       │   └── 📁 v22.12.0/            # Node.js installation
│       └── 📁 npm/                     # npm global packages
│           └── 📦 @anthropic-ai/claude-code-cli
│
├── 📁 Desktop/                         # Empty desktop
├── 📁 Documents/                       # Empty documents
└── 📁 Downloads/                       # Empty downloads

ENVIRONMENT VARIABLES SET:
• NVM_HOME = C:\Users\Lab1\AppData\Roaming\nvm
• NVM_SYMLINK = C:\Users\Lab1\AppData\Roaming\nodejs
• PATH += nvm directories
```

### Styling Notes
- Folder structure in monospace font
- Purple (#7C3AED) highlights on .claude/ directory
- Steel light text for paths and names
- Steel text for comments
- Success color (#9CB92C) for key files like settings.json, .env
- Tree lines in border color (#27272A)

---

## Diagram 6: Commands Overview

### Layout
- Command reference table with examples

### Content

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          COMMANDS                                        │
└─────────────────────────────────────────────────────────────────────────┘

╔════════════╦═══════════════════════════════════════════════════════════╗
║  COMMAND   ║  WHAT IT DOES                                             ║
╠════════════╬═══════════════════════════════════════════════════════════╣
║            ║                                                           ║
║  spawn     ║  Create a ready-to-use Windows user with Claude Code     ║
║            ║  • Windows account                                        ║
║            ║  • Node.js (via nvm)                                      ║
║            ║  • Claude CLI                                             ║
║            ║  • .claude config from template                           ║
║            ║                                                           ║
║            ║  Example: ./spawner spawn Lab4                            ║
║            ║  Example: ./spawner spawn Lab4 --template pai-clone       ║
║            ║                                                           ║
╠════════════╬═══════════════════════════════════════════════════════════╣
║            ║                                                           ║
║  respawn   ║  Recreate user fresh (full or config-only)               ║
║            ║  • Full: despawn + spawn (default)                        ║
║            ║  • CLI only: backup + reset .claude/ (--cli flag)         ║
║            ║                                                           ║
║            ║  Example: ./spawner respawn Lab4                          ║
║            ║  Example: ./spawner respawn Lab4 --cli                    ║
║            ║                                                           ║
╠════════════╬═══════════════════════════════════════════════════════════╣
║            ║                                                           ║
║  despawn   ║  Delete Windows user and cleanup                          ║
║            ║  • Auto-backup before delete                              ║
║            ║  • Confirmation prompt (skip with --force)                ║
║            ║  • Removes from manifest                                  ║
║            ║                                                           ║
║            ║  Example: ./spawner despawn Lab4                          ║
║            ║  Example: ./spawner despawn Lab4 --force                  ║
║            ║                                                           ║
╠════════════╬═══════════════════════════════════════════════════════════╣
║            ║                                                           ║
║  cospawn   ║  Copy .claude config from another spawned user            ║
║            ║  • Spawn new user                                         ║
║            ║  • Copy source user's .claude/ directory                  ║
║            ║  • Useful for testing variations                          ║
║            ║                                                           ║
║            ║  Example: ./spawner cospawn Lab5 --from Lab4              ║
║            ║                                                           ║
╚════════════╩═══════════════════════════════════════════════════════════╝
```

### Styling Notes
- Table borders in #27272A
- Command names in purple (#7C3AED), bold
- Descriptions in steel (#A1A1AA)
- Examples in steel light (#D4D4D8) with monospace font
- Section separators in border color

---

## Implementation Notes

### For Mermaid Diagrams
These specs can be converted to Mermaid syntax for GitHub markdown rendering.

### For Manual Design Tools
Use these specs in:
- Figma
- Excalidraw
- draw.io
- Canva

### For AI Image Generation
Use the detailed descriptions and styling notes as prompts for:
- Midjourney
- DALL-E
- Stable Diffusion
- Google Imagen

### Export Formats
- PNG (transparent background for dark mode)
- SVG (scalable, editable)
- PDF (print-ready)

### File Naming Convention
```
cc-spawner-diagram-[name]-[variant].ext

Examples:
- cc-spawner-diagram-isolation-dark.png
- cc-spawner-diagram-workflow-light.svg
- cc-spawner-diagram-structure.pdf
```
