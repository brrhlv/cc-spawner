# cc-spawner Architecture Diagrams

Professional architecture diagrams for the cc-spawner project using Mermaid syntax.

---

## 1. Isolation Spectrum

Shows where cc-spawner fits in the isolation landscape.

```mermaid
graph LR
    A[Same User<br/>❌ No Isolation<br/>Shared files<br/>Same config] --> B[Env Var Override<br/>⚠️ Partial Isolation<br/>Same .claude<br/>Different env]
    B --> C[Different User<br/>✅ Full Isolation<br/>Separate home<br/>Separate config]
    C --> D[Different Machine<br/>✅ Complete Isolation<br/>Network separated<br/>Hardware separated]

    C -.->|cc-spawner<br/>operates here| E[cc-spawner]

    style C fill:#7C3AED,stroke:#9061F9,stroke-width:3px,color:#fff
    style E fill:#7C3AED,stroke:#9061F9,stroke-width:2px,color:#fff
    style A fill:#18181B,stroke:#27272A,color:#D4D4D8
    style B fill:#18181B,stroke:#27272A,color:#D4D4D8
    style D fill:#18181B,stroke:#27272A,color:#D4D4D8
```

---

## 2. Spawn Workflow

Six-phase process for creating a spawned user environment.

```mermaid
graph TD
    Start([Start Spawn]) --> Step1[1️⃣ CREATE USER<br/>Windows User Account<br/>Username + Password<br/>Profile Path]
    Step1 --> Step2[2️⃣ INIT PROFILE<br/>User Folders<br/>AppData/, Desktop/<br/>Documents/]
    Step2 --> Step3[3️⃣ INSTALL NVM<br/>nvm-windows v1.2.2<br/>Portable Setup<br/>User AppData]
    Step3 --> Step4[4️⃣ INSTALL NODE<br/>Node.js v22.12.0<br/>Per-User Install<br/>npm ready]
    Step4 --> Step5[5️⃣ INSTALL CLAUDE<br/>Claude Code CLI<br/>npm global install<br/>Isolated]
    Step5 --> Step6[6️⃣ COPY CONFIG<br/>.claude/ Template<br/>API Keys<br/>Settings]
    Step6 --> Ready([✅ READY<br/>User can login])

    style Start fill:#7C3AED,stroke:#9061F9,color:#fff
    style Ready fill:#9CB92C,stroke:#9CB92C,color:#0C0C0F
    style Step1 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step2 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step3 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step4 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step5 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step6 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
```

---

## 3. Environment Categories

Three environment types supported by cc-spawner.

```mermaid
graph TB
    subgraph LAB["🧪 LAB - EXPERIMENTAL"]
        L1[Purpose: Testing, breaking,<br/>exploring configs]
        L2[Template: vanilla default<br/>or any template]
        L3[Lifespan: Short hours/days<br/>Reset often]
        L4[Examples: Lab1, Lab2, Lab3]
    end

    subgraph DEV["🔧 DEV - AUTOMATION"]
        D1[Purpose: Headless automation<br/>Script testing, CI/CD]
        D2[Template: vanilla only<br/>Minimal overhead]
        D3[Lifespan: Medium weeks<br/>Stable baseline]
        D4[Examples: Dev1, AutoTest1]
    end

    subgraph PROD["🚀 PROD - PRODUCTION"]
        P1[Purpose: Main user account<br/>Full PAI setup]
        P2[Template: pai-clone<br/>Full .claude/ with skills]
        P3[Lifespan: Permanent<br/>Never despawn]
        P4[Examples: Admin admin]
    end

    style LAB fill:#18181B,stroke:#7C3AED,stroke-width:2px,color:#D4D4D8
    style DEV fill:#18181B,stroke:#7C3AED,stroke-width:2px,color:#D4D4D8
    style PROD fill:#18181B,stroke:#9CB92C,stroke-width:2px,color:#D4D4D8
```

---

## 4. Templates System

Available templates for spawned environments.

```mermaid
graph LR
    Spawn[spawner spawn Lab4] --> Template{Choose Template}

    Template -->|default| Vanilla[vanilla<br/>Stock Claude Code<br/>No PAI, no hooks]
    Template -->|--template| PaiVanilla[pai-vanilla<br/>Miessler's Original PAI<br/>Upstream version]
    Template -->|--template| PaiStarter[pai-starter<br/>PAI Framework Starter<br/>Generic, no personal data]
    Template -->|--template| PaiClone[pai-clone<br/>Admin PAI Clone<br/>Full production config]

    Vanilla --> Apply[Copy .claude/<br/>to user home]
    PaiVanilla --> Apply
    PaiStarter --> Apply
    PaiClone --> Apply

    style Spawn fill:#7C3AED,stroke:#9061F9,color:#fff
    style Template fill:#18181B,stroke:#27272A,color:#D4D4D8
    style Vanilla fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style PaiVanilla fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style PaiStarter fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style PaiClone fill:#18181B,stroke:#9CB92C,color:#D4D4D8
    style Apply fill:#9CB92C,stroke:#9CB92C,color:#0C0C0F
```

---

## 5. Commands Overview

Core commands and their relationships.

```mermaid
graph TB
    CLI[spawner CLI] --> Spawn[spawn<br/>Create new user]
    CLI --> Respawn[respawn<br/>Recreate existing]
    CLI --> Despawn[despawn<br/>Delete user]
    CLI --> Cospawn[cospawn<br/>Copy from another]

    Spawn --> S1[Create Windows user]
    Spawn --> S2[Install dependencies]
    Spawn --> S3[Apply template]

    Respawn --> R1{Check flag}
    R1 -->|default| R2[Full: despawn + spawn]
    R1 -->|--cli| R3[Config only: backup + reset .claude/]

    Despawn --> D1[Backup .claude/]
    Despawn --> D2[Delete Windows user]
    Despawn --> D3[Update manifest]

    Cospawn --> C1[Spawn new user]
    Cospawn --> C2[Copy source .claude/]

    style CLI fill:#7C3AED,stroke:#9061F9,stroke-width:3px,color:#fff
    style Spawn fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Respawn fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Despawn fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Cospawn fill:#18181B,stroke:#7C3AED,color:#D4D4D8
```

---

## 6. Directory Structure

Project layout and key files.

```mermaid
graph TD
    Root[Spawner/] --> CLI[spawner<br/>Bash wrapper]
    Root --> PS[spawner.ps1<br/>PowerShell core]
    Root --> Config[config.json<br/>Settings]
    Root --> Manifest[manifest.json<br/>User registry]

    Root --> Templates[templates/]
    Templates --> TV[vanilla/]
    Templates --> TPV[pai-vanilla/]
    Templates --> TPS[pai-starter/]
    Templates --> TPC[pai-snapshot/]

    Root --> Deps[dependencies/]
    Deps --> DNvm[nvm-noinstall.zip]
    Deps --> DNode[node-v22.12.0.zip]

    Root --> Backups[backups/]
    Backups --> BFile[Lab4_2026-01-21.zip]

    Root --> Logs[logs/]
    Logs --> LFile[spawn-Lab4.log]

    Root --> CfgDir[_config/]
    CfgDir --> APIKeys[api-keys.env]

    style Root fill:#7C3AED,stroke:#9061F9,stroke-width:2px,color:#fff
    style CLI fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style PS fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Config fill:#18181B,stroke:#A1A1AA,color:#D4D4D8
    style Templates fill:#18181B,stroke:#27272A,color:#D4D4D8
    style Deps fill:#18181B,stroke:#27272A,color:#D4D4D8
    style Backups fill:#18181B,stroke:#27272A,color:#D4D4D8
    style Logs fill:#18181B,stroke:#27272A,color:#D4D4D8
```

---

## 7. User Environment

What gets created in each spawned user's home directory.

```mermaid
graph TB
    UserHome[C:\Users\Lab1\] --> Claude[.claude/<br/>Claude Code config]
    UserHome --> AppData[AppData/]
    UserHome --> Desktop[Desktop/]
    UserHome --> Docs[Documents/]
    UserHome --> Downloads[Downloads/]

    Claude --> Settings[settings.json]
    Claude --> History[history.jsonl]
    Claude --> Env[.env<br/>API keys]
    Claude --> Skills[skills/]
    Claude --> Agents[agents/]
    Claude --> Hooks[hooks/]

    AppData --> Roaming[Roaming/]
    Roaming --> NVM[nvm/<br/>nvm-windows]
    Roaming --> NPM[npm/<br/>global packages]

    NVM --> NodeVer[v22.12.0/]
    NPM --> ClaudeCLI[claude-code-cli]

    AppData --> Local[Local/<br/>Temp files]

    style UserHome fill:#7C3AED,stroke:#9061F9,stroke-width:2px,color:#fff
    style Claude fill:#18181B,stroke:#9CB92C,stroke-width:2px,color:#D4D4D8
    style Settings fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Env fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style NVM fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style NodeVer fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style ClaudeCLI fill:#18181B,stroke:#9CB92C,color:#D4D4D8
```

---

## Usage

### In GitHub README
Copy the Mermaid code blocks directly into markdown files. GitHub renders Mermaid automatically.

### In Other Platforms
- **GitLab**: Native Mermaid support
- **Notion**: Use Mermaid blocks
- **Obsidian**: Mermaid plugin
- **VS Code**: Markdown Preview Mermaid Support extension

### Export as Images
Use tools like:
- [Mermaid Live Editor](https://mermaid.live) - Export PNG/SVG
- `mmdc` CLI - Mermaid CLI for batch conversion
- GitHub Actions - Auto-generate diagrams on commit

### Customization
Edit the style definitions to match your brand:
- `fill`: Background color
- `stroke`: Border color
- `stroke-width`: Border thickness
- `color`: Text color

### Brand Colors Used
- **Purple**: `#7C3AED` - Primary accent, highlights
- **Steel Light**: `#D4D4D8` - Primary text
- **Steel**: `#A1A1AA` - Secondary text
- **Dark Background**: `#0C0C0F` - Main background
- **Elevated**: `#18181B` - Card/box backgrounds
- **Border**: `#27272A` - Borders, dividers
- **Success**: `#9CB92C` - Success states, ready indicators
