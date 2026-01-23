# cc-spawner Image Generation Guide

## Brand Context: brrhlv

**Aesthetic:** Cyberpunk Goth - dark, moody, purple-accented
**Version:** v4 Clarity Edition

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Background | #0C0C0F | Primary dark background |
| Elevated | #18181B | Cards, elevated surfaces |
| Border | #27272A | Dividers, borders |
| Purple Light | #9061F9 | Interactive elements, text |
| Purple | #7C3AED | Accents, brand color |
| Purple Dark | #5B21B6 | Pressed states, depth |
| Steel Light | #D4D4D8 | Headlines, primary text |
| Steel | #A1A1AA | Body text, secondary |
| Steel Dark | #52525B | Muted text |
| Success/Peridot | #9CB92C | Green success states |
| Error | #EF4444 | Red error states |
| Warning | #F59E0B | Orange warnings |

### Style Guidelines

- **Background:** Always use deep dark #0C0C0F
- **Glow Effects:** Subtle purple glows on interactive elements
- **Typography:** Bebas Neue for titles, Fira Sans for body
- **Minecraft Element:** Only the monster spawner cage is allowed
- **Atmosphere:** Dark, technical, professional cyberpunk

---

## Image Specifications

All images are **1920x1080** (16:9) unless otherwise specified.

### 1. problem.png - The Chaos of Testing in Production

**Concept:** Show the pain point - a developer overwhelmed by conflicting environments

**Detailed Prompt:**
```
SUBJECT: Chaotic developer workspace showing the problem of testing in production
STYLE: Cyberpunk goth, dark moody atmosphere, technical nightmare visualization
COLORS: Background #0C0C0F, error indicators #EF4444, warning glow in orange, multiple overlapping Claude 'C' logos glitching
COMPOSITION: Single overwhelmed developer desk with multiple monitors, tangled dependency lines crossing the scene, floating error messages, red warning triangles, frustrated developer silhouette in shadow
TECHNICAL: Dark background #0C0C0F, red error glow effects, glitch aesthetic on logos
AVOID: Bright colors, cheerful mood, organized workspace, blue tones
```

**Key Elements:**
- Multiple monitors showing conflicting states
- Claude "C" logos glitching/overlapping (representing context conflicts)
- Red error indicators (#EF4444)
- Tangled dependency lines
- Frustrated developer silhouette
- Dark moody atmosphere

**Design Rationale:** Establish the problem space. User immediately sees the chaos that cc-spawner solves.

**Best For:** README hero section, problem statement, landing page "before" state

---

### 2. spawn.png - Creating a New Environment

**Concept:** Clean visualization of the spawning process - components assembling into a fresh environment

**Detailed Prompt:**
```
SUBJECT: Minecraft monster spawner cage spawning development environment components into a new user profile
STYLE: Cyberpunk tech visualization, clean assembly process, purple particle effects
COLORS: Spawner cage in dark metal with purple glow #7C3AED inside, components with purple accent #9061F9, success indicator #9CB92C, background #0C0C0F
COMPOSITION: Top third shows Minecraft-style metal cage spawner with purple glow, middle shows components dropping down (folder icon, Node.js hexagon, Claude C logo, gear icon, key icon), bottom shows newly formed Lab1 user profile with green success glow
TECHNICAL: Purple particle effects flowing downward, dark background #0C0C0F, green success state #9CB92C
AVOID: Bright backgrounds, realistic rendering, cluttered composition, multiple spawners
```

**Key Elements:**
- Minecraft monster spawner cage (top center) - dark metal bars with purple glow
- Components flowing downward:
  - Folder icon (filesystem)
  - Node.js hexagon (dependencies)
  - Claude "C" logo (CLI instance)
  - Gear icon (configuration)
  - Key icon (credentials)
- "Lab1" user profile materializing at bottom with green success glow (#9CB92C)
- Purple particle effects (#9061F9) showing assembly process

**Design Rationale:** Core feature visualization. Shows the magic of instant environment creation.

**Best For:** Command documentation, feature showcase, "spawn" command section

---

### 3. respawn.png - Resetting an Environment

**Concept:** Before/after transformation showing environment reset

**Detailed Prompt:**
```
SUBJECT: Split-screen before and after reset transformation visualization
STYLE: Cyberpunk UI, clean technical diagram, transformation process
COLORS: Left panel orange warning #F59E0B, center mechanism purple #7C3AED, right panel green success #9CB92C, background #0C0C0F
COMPOSITION: Three vertical panels - LEFT corrupted environment with orange glow and wear marks, CENTER reset mechanism showing --cli and --full option badges with circular refresh arrow, RIGHT pristine fresh environment with green success glow
TECHNICAL: Dark background #0C0C0F, subtle panel dividers in #27272A, transformation flow from left to right
AVOID: Cluttered interface, realistic textures, multiple reset options, confusing layout
```

**Key Elements:**
- **LEFT panel:** Corrupted "Lab2" with orange warning glow (#F59E0B), visible wear/corruption
- **CENTER panel:** Reset mechanism with:
  - `--cli` badge (reset CLI only)
  - `--full` badge (full reset)
  - Circular refresh arrow in purple (#7C3AED)
- **RIGHT panel:** Fresh clean "Lab2" with green success glow (#9CB92C)
- Panel dividers in subtle #27272A

**Design Rationale:** Shows the non-destructive reset capability. Users can recover from mistakes.

**Best For:** "respawn" command documentation, troubleshooting guide, recovery procedures

---

### 4. despawn.png - Removing an Environment

**Concept:** Elegant dissolution showing peaceful environment removal

**Detailed Prompt:**
```
SUBJECT: User profile dissolving peacefully into particles
STYLE: Cyberpunk goth, elegant dissolution, peaceful removal aesthetic
COLORS: Profile labeled Lab2 dissolving into purple particles #7C3AED and #9061F9, platform below in #18181B, void space in #0C0C0F, optional backup chest in steel #A1A1AA
COMPOSITION: Center focus on Lab2 user profile breaking into purple particles floating upward, platform retracting downward, backup chest in bottom right catching data, empty void space below indicating complete cleanup
TECHNICAL: Purple particle effect with glow, dark void background #0C0C0F, subtle platform texture
AVOID: Violent destruction, fire effects, bright colors, cluttered scene
```

**Key Elements:**
- "Lab2" profile center stage, dissolving into purple particles
- Purple particles (#7C3AED, #9061F9) floating upward gracefully
- Platform (#18181B) retracting/disappearing below
- Optional backup chest (#A1A1AA) in corner catching data
- Deep void (#0C0C0F) below showing complete removal
- Peaceful, controlled aesthetic (NOT violent)

**Design Rationale:** Shows complete cleanup without data loss. Reassures users the removal is safe and reversible.

**Best For:** "despawn" command documentation, cleanup guide, safety assurances

---

### 5. cospawn.png - Cloning Configuration

**Concept:** Data transfer visualization between two profiles

**Detailed Prompt:**
```
SUBJECT: Configuration cloning between two user profiles
STYLE: Cyberpunk technical visualization, data transfer process, clean tech aesthetic
COLORS: Lab1 source with green #9CB92C status, scanning mechanism with blue scan lines, Lab2 target materializing, data flow particles in purple #9061F9, background #0C0C0F
COMPOSITION: LEFT shows established Lab1 profile with green checkmark, CENTER shows scanning/copying mechanism with blue holographic scan lines, RIGHT shows Lab2 materializing as config items duplicate, purple data flow particles between profiles
TECHNICAL: Dark background #0C0C0F, blue scan effect, purple data particles with glow
AVOID: Complex UI, realistic rendering, multiple profiles, confusing data flow
```

**Key Elements:**
- **LEFT:** "Lab1" source profile with green checkmark (#9CB92C) - established
- **CENTER:** Scanning mechanism with blue holographic scan lines
- **RIGHT:** "Lab2" target profile materializing, receiving configs
- Purple data flow particles (#9061F9) showing transfer
- Clear left-to-right flow

**Design Rationale:** Shows the power of configuration cloning. Users can duplicate working setups instantly.

**Best For:** "cospawn" command documentation, workflow examples, template usage

---

### 6. architecture.png - System Architecture

**Concept:** Cross-section diagram showing isolation and structure

**Detailed Prompt:**
```
SUBJECT: System architecture cross-section showing Windows OS with isolated user environments
STYLE: Cyberpunk technical diagram, clean architecture visualization, isometric or side-view
COLORS: MAIN user with gold crown #F59E0B and protected glow, Lab1 green #9CB92C, Lab2 blue accent, spawner hub purple #7C3AED, isolation walls #27272A, background #0C0C0F, shared kernel #18181B
COMPOSITION: Cross-section view showing Windows container with three side-by-side user environments (MAIN left with gold crown icon labeled protected, Lab1 center green labeled testing, Lab2 right blue labeled experimental), Minecraft spawner cage in center top as cc-spawner hub with purple connection lines to each user, isolation walls between users, shared kernel layer at bottom
TECHNICAL: Dark background #0C0C0F, subtle depth with elevated surfaces #18181B, purple connection glows
AVOID: Flat 2D layout, cluttered labels, realistic Windows UI, too many users
```

**Key Elements:**
- **MAIN user (left):** Gold crown icon (#F59E0B), labeled "Protected", safe zone
- **Lab1 (center):** Green (#9CB92C), labeled "Testing"
- **Lab2 (right):** Blue accent, labeled "Experimental"
- **cc-spawner hub (top center):** Minecraft spawner cage in purple (#7C3AED)
- Purple connection lines from hub to each user
- Isolation walls (#27272A) between users
- Shared kernel layer at bottom (#18181B)
- Clean isometric or side-view perspective

**Design Rationale:** Technical users need to understand the isolation architecture. Shows how MAIN stays protected.

**Best For:** README architecture section, technical documentation, security explanation

---

### 7. templates.png - Template Selection

**Concept:** UI mockup showing template choices

**Detailed Prompt:**
```
SUBJECT: Template selection UI grid showing four template cards
STYLE: Cyberpunk UI design, clean card layout, modern interface
COLORS: Selected card with purple glow #7C3AED, unselected cards #18181B with border #27272A, text in steel #D4D4D8, icons purple #9061F9, background #0C0C0F
COMPOSITION: 2x2 grid of template cards (vanilla/default top-left with checkmark icon, minimal top-right with simplified icon, pai/advanced bottom-left with gear icon, custom bottom-right with wrench icon), selected vanilla card has purple glow border, command shown below: ./spawner spawn Lab1 --template vanilla
TECHNICAL: Dark background #0C0C0F, card elevation #18181B, purple selection glow, clean icons
AVOID: Cluttered cards, realistic shadows, too many templates, complex icons
```

**Key Elements:**
- **2x2 grid of cards:**
  - **Vanilla (top-left):** Checkmark icon, purple glow (#7C3AED) - SELECTED
  - **Minimal (top-right):** Simplified icon, unselected
  - **PAI (bottom-left):** Gear icon, unselected
  - **Custom (bottom-right):** Wrench icon, unselected
- Card background: #18181B (elevated)
- Card border: #27272A
- Text: #D4D4D8 (steel light)
- Icons: #9061F9 (purple light)
- Command below grid: `./spawner spawn Lab1 --template vanilla`

**Design Rationale:** Shows template options clearly. Users understand they can start with different base configurations.

**Best For:** Template documentation, getting started guide, customization section

---

### 8. hero.png - Project Hero Image

**Concept:** Dramatic branded title card for project

**Detailed Prompt:**
```
SUBJECT: Hero title image for cc-spawner project with centerpiece spawner cage
STYLE: Cyberpunk goth, dramatic hero composition, purple accent lighting, moody atmosphere
COLORS: Title cc-spawner in steel light #D4D4D8 with purple glow #7C3AED, spawner cage metal dark with purple inner glow #9061F9, Lab avatars in green #9CB92C, blue accent, orange #F59E0B, background deep dark #0C0C0F
COMPOSITION: Large cc-spawner title at top with purple glow effect, Minecraft monster spawner cage as centerpiece with Claude C logo spinning inside purple glow, three spawned user avatars below in a row (Lab1 green glowing, Lab2 blue glowing, Lab3 orange glowing), tagline at bottom: Isolated Claude Code test environments for Windows
TECHNICAL: Dark cyberpunk atmosphere #0C0C0F background, subtle purple accent lighting from spawner, glow effects on title and avatars
AVOID: Bright colors, cluttered composition, realistic rendering, too many elements, busy background
```

**Key Elements:**
- **Top:** Large "cc-spawner" title (#D4D4D8) with purple glow (#7C3AED)
- **Center:** Minecraft monster spawner cage (dark metal) with purple inner glow (#9061F9)
- Claude "C" logo spinning inside the cage
- **Bottom row:** Three user avatars:
  - Lab1 (green #9CB92C)
  - Lab2 (blue accent)
  - Lab3 (orange #F59E0B)
- **Tagline:** "Isolated Claude Code test environments for Windows"
- Moody atmosphere, subtle purple accent lighting

**Design Rationale:** Project identity. Immediate visual recognition and brand association.

**Best For:** README header, social media sharing, project logo/banner

---

## Generation Methods

### Method 1: Gemini CLI (Interactive)

```bash
# Run gemini CLI in interactive mode
gemini

# Then use prompts like:
> Generate an image: [paste prompt from above]
```

### Method 2: Imagen API (If available)

```bash
node generate-images.js
```

Requires valid Imagen API access and proper API key configuration.

### Method 3: Manual Generation

Use any AI image generation tool (Midjourney, DALL-E, Stable Diffusion) with the detailed prompts above.

**Recommended Settings:**
- Aspect ratio: 16:9 (1920x1080)
- Style: Technical illustration, UI design, cyberpunk
- Quality: High
- Seed: Use same seed for consistency across images

---

## Brand Compliance Checklist

Before finalizing any image, verify:

- [ ] Background is #0C0C0F (deep dark)
- [ ] Purple accents use #7C3AED or #9061F9
- [ ] Text elements use steel colors (#D4D4D8, #A1A1AA)
- [ ] Success states use #9CB92C (peridot green)
- [ ] Error states use #EF4444 (red)
- [ ] Warning states use #F59E0B (orange)
- [ ] Glow effects are subtle, not overpowering
- [ ] Only Minecraft spawner cage used (no other Minecraft elements)
- [ ] Composition is clean, not cluttered
- [ ] Atmosphere is dark cyberpunk goth
- [ ] No bright backgrounds or cheerful vibes

---

## Next Steps

1. **Review Prompts:** Ensure each prompt matches the intended concept
2. **Generate Images:** Use preferred method (CLI, API, or manual)
3. **Verify Brand:** Check each image against compliance checklist
4. **Iterate:** Refine any images that don't match brand guidelines
5. **Finalize:** Save all images to this directory
6. **Update README:** Add images to project README with appropriate context

---

## File Manifest

| File | Purpose | Status |
|------|---------|--------|
| problem.png | Show chaos of testing in production | Pending |
| spawn.png | Visualize environment creation | Pending |
| respawn.png | Show reset/recovery process | Pending |
| despawn.png | Show safe environment removal | Pending |
| cospawn.png | Show configuration cloning | Pending |
| architecture.png | System architecture diagram | Pending |
| templates.png | Template selection UI | Pending |
| hero.png | Project hero/banner image | Pending |

---

**Generated:** 2026-01-21
**Brand Version:** brrhlv v4 Clarity Edition
**Project:** cc-spawner
