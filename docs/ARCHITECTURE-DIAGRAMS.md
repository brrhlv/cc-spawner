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

## 2. Spawn Workflow (v4 - Native Install)

Six-phase process for creating a spawned user environment.

```mermaid
graph TD
    Start([Start Spawn]) --> Step1[1️⃣ CREATE USER<br/>Windows User Account<br/>Username + Password<br/>Profile Path]
    Step1 --> Step2[2️⃣ INIT PROFILE<br/>User Folders<br/>.local/, .claude/<br/>projects/]
    Step2 --> Step3[3️⃣ INSTALL CLAUDE<br/>Native Binary<br/>~/.local/bin/claude.exe<br/>No npm required]
    Step3 --> Step4{Template needs Python?}
    Step4 -->|Yes| Step5[4️⃣ INSTALL PYTHON<br/>Python 3.12 Embeddable<br/>~/.python/<br/>pip included]
    Step4 -->|No| Step6
    Step5 --> Step6[5️⃣ COPY CONFIG<br/>.claude/ Template<br/>API Keys<br/>Hooks if any]
    Step6 --> Step7[6️⃣ SET PATH<br/>User Environment<br/>.local/bin in PATH<br/>.python in PATH if needed]
    Step7 --> Ready([✅ READY<br/>User can login])

    style Start fill:#7C3AED,stroke:#9061F9,color:#fff
    style Ready fill:#9CB92C,stroke:#9CB92C,color:#0C0C0F
    style Step1 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step2 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step3 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step4 fill:#18181B,stroke:#27272A,color:#D4D4D8
    style Step5 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step6 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Step7 fill:#18181B,stroke:#7C3AED,color:#D4D4D8
```

---

## 3. Templates System (v4)

Available templates for spawned environments.

```mermaid
graph LR
    Spawn[spawner spawn Lab4] --> Template{Choose Template}

    Template -->|default| Vanilla[cc-vanilla<br/>Stock Claude Code<br/>No hooks, minimal]
    Template -->|--template| Python[cc-python<br/>Python Hooks<br/>Anthropic patterns]
    Template -->|--template| Legacy[cc-vanilla-legacy<br/>npm-based install<br/>Node.js required]

    Vanilla --> Apply[Copy .claude/<br/>to user home]
    Python --> Apply
    Legacy --> Apply

    style Spawn fill:#7C3AED,stroke:#9061F9,color:#fff
    style Template fill:#18181B,stroke:#27272A,color:#D4D4D8
    style Vanilla fill:#18181B,stroke:#9CB92C,color:#D4D4D8
    style Python fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Legacy fill:#18181B,stroke:#27272A,color:#71717A
    style Apply fill:#9CB92C,stroke:#9CB92C,color:#0C0C0F
```

---

## 4. User Environment (v4)

What gets created in each spawned user's home directory.

```mermaid
graph TB
    UserHome[C:\Users\Lab1\] --> Local[.local/]
    UserHome --> Claude[.claude/<br/>Claude Code config]
    UserHome --> Python[.python/<br/>if template needs it]
    UserHome --> Projects[projects/]

    Local --> Bin[bin/]
    Local --> Share[share/]
    Bin --> ClaudeExe[claude.exe<br/>Native binary]
    Share --> ClaudeData[claude/<br/>Version data]

    Claude --> Settings[settings.json]
    Claude --> Hooks[hooks/<br/>Python hooks]
    Claude --> Env[.env<br/>API keys]

    Python --> PyExe[python.exe]
    Python --> Scripts[Scripts/<br/>pip, etc.]

    style UserHome fill:#7C3AED,stroke:#9061F9,stroke-width:2px,color:#fff
    style Local fill:#18181B,stroke:#9CB92C,stroke-width:2px,color:#D4D4D8
    style Claude fill:#18181B,stroke:#9CB92C,stroke-width:2px,color:#D4D4D8
    style ClaudeExe fill:#18181B,stroke:#9CB92C,color:#D4D4D8
    style Settings fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Hooks fill:#18181B,stroke:#7C3AED,color:#D4D4D8
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
    Spawn --> S2[Install Claude native]
    Spawn --> S3[Install Python if needed]
    Spawn --> S4[Apply template]

    Respawn --> R1{Check flag}
    R1 -->|default| R2[Full: despawn + spawn]
    R1 -->|--cli| R3[Config only: reset .claude/]

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

## 6. Directory Structure (v4)

Project layout and key files.

```mermaid
graph TD
    Root[Spawner/] --> PS[spawner.ps1<br/>PowerShell core]
    Root --> Config[config.json<br/>Settings v4]
    Root --> Manifest[manifest.json<br/>User registry]

    Root --> Templates[templates/]
    Templates --> TV[cc-vanilla/<br/>Default minimal]
    Templates --> TP[cc-python/<br/>Python hooks]
    Templates --> TL[cc-vanilla-legacy/<br/>npm-based]

    Root --> Deps[dependencies/]
    Deps --> DClaude[claude-code/<br/>Native binary]
    Deps --> DPython[python/<br/>Embeddable]

    Root --> Identities[identities/]
    Identities --> IDev[developer/]
    Identities --> IRes[researcher/]

    Root --> Backups[backups/]
    Root --> Logs[logs/]

    style Root fill:#7C3AED,stroke:#9061F9,stroke-width:2px,color:#fff
    style PS fill:#18181B,stroke:#7C3AED,color:#D4D4D8
    style Config fill:#18181B,stroke:#A1A1AA,color:#D4D4D8
    style Templates fill:#18181B,stroke:#27272A,color:#D4D4D8
    style Deps fill:#18181B,stroke:#27272A,color:#D4D4D8
```

---

## Usage

### In GitHub README
Copy the Mermaid code blocks directly into markdown files. GitHub renders Mermaid automatically.

### Brand Colors Used
- **Purple**: `#7C3AED` - Primary accent, highlights
- **Steel Light**: `#D4D4D8` - Primary text
- **Dark Background**: `#0C0C0F` - Main background
- **Elevated**: `#18181B` - Card/box backgrounds
- **Border**: `#27272A` - Borders, dividers
- **Success**: `#9CB92C` - Success states, ready indicators
