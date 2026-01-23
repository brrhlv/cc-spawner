# cc-spawner Assets Directory

Professional branded imagery and design assets for the cc-spawner project.

**Brand:** brrhlv v4 Clarity Edition (Cyberpunk Goth)
**Date:** 2026-01-21
**Agent:** Gemini Designer (Claude Code)

---

## Quick Start

### Option 1: Copy & Paste (Fastest)
1. Open [QUICK-PROMPTS.txt](./QUICK-PROMPTS.txt)
2. Copy the prompt for the image you want
3. Paste into Midjourney, DALL-E, Leonardo.ai, or any AI image generator
4. Add recommended settings for your tool
5. Generate and save

### Option 2: Detailed Generation (Best Results)
1. Read [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md)
2. Follow the complete specifications for each image
3. Use the brand compliance checklist before finalizing
4. Generate all 8 images using your preferred tool

### Option 3: Automated (Requires API Access)
1. Ensure Gemini Imagen API is configured
2. Set `GEMINI_API_KEY` environment variable
3. Run: `node generate-images.js`
4. Wait for batch generation to complete

---

## Files Overview

| File | Purpose | Use This When... |
|------|---------|------------------|
| [QUICK-PROMPTS.txt](./QUICK-PROMPTS.txt) | Copy/paste ready prompts | You want to generate images quickly |
| [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md) | Complete specifications | You need detailed context and brand guidelines |
| [GENERATION-SESSION-SUMMARY.md](./GENERATION-SESSION-SUMMARY.md) | Session documentation | You want to understand the design decisions |
| [generate-images.js](./generate-images.js) | Automation script | You have Imagen API access and want batch generation |
| **README.md** | This file | You're getting oriented |

---

## Required Images

| Image | Concept | Status | Use In |
|-------|---------|--------|--------|
| problem.png | Chaos of testing in prod | 🔴 Pending | README problem section |
| spawn.png | Environment creation | 🔴 Pending | Spawn command docs |
| respawn.png | Environment reset | 🔴 Pending | Respawn command docs |
| despawn.png | Environment removal | 🔴 Pending | Despawn command docs |
| cospawn.png | Config cloning | 🔴 Pending | Cospawn command docs |
| architecture.png | System diagram | 🔴 Pending | README architecture |
| templates.png | Template selection | 🔴 Pending | Template docs |
| hero.png | Project banner | 🔴 Pending | README header |

🔴 Pending = Not yet generated
🟡 In Progress = Generation started
🟢 Complete = Generated and verified

---

## Brand Guidelines Applied

### Color Palette (brrhlv v4)

```
Background:   #0C0C0F  (deep black)
Elevated:     #18181B  (dark grey)
Border:       #27272A  (medium grey)
Purple Light: #9061F9  (interactive)
Purple:       #7C3AED  (brand accent)
Purple Dark:  #5B21B6  (depth)
Steel Light:  #D4D4D8  (headlines)
Steel:        #A1A1AA  (body text)
Success:      #9CB92C  (peridot green)
Error:        #EF4444  (red)
Warning:      #F59E0B  (orange)
```

### Style Constraints

✓ **Aesthetic:** Cyberpunk Goth - dark, moody, purple-accented
✓ **Backgrounds:** Always #0C0C0F (deep dark)
✓ **Glow Effects:** Subtle purple glows only
✓ **Minecraft Element:** Only monster spawner cage allowed
✓ **Atmosphere:** Professional technical, not playful

---

## Recommended Tools

### Tier 1: Best Quality
- **Midjourney** (subscription required, $10-60/mo)
  - Best: `--v 6 --ar 16:9 --style raw`
  - Use same `--seed` for consistency
- **DALL-E 3** (via ChatGPT Plus, $20/mo)
  - Request "wide format 1920x1080"
  - Specify "clean digital illustration"

### Tier 2: Free Alternatives
- **Leonardo.ai** (free tier: 150 tokens/day)
  - Use "Illustration" model
  - Set aspect ratio to 16:9
- **Stable Diffusion** (free, local)
  - SDXL model recommended
  - Use negative prompts from QUICK-PROMPTS.txt

### Tier 3: Interactive
- **Gemini CLI** (installed, interactive)
  - Run: `gemini`
  - Prompt: "Generate an image: [paste prompt]"
  - Save manually

---

## Quality Checklist

Before finalizing any image:

### Technical
- [ ] Resolution: 1920x1080 (16:9)
- [ ] Format: PNG
- [ ] File size: < 1MB (optimized)
- [ ] Clear, crisp rendering

### Brand Compliance
- [ ] Background is #0C0C0F (deep dark)
- [ ] Purple accents use #7C3AED or #9061F9
- [ ] Success states use #9CB92C
- [ ] Glow effects are subtle
- [ ] Only spawner cage (no other Minecraft elements)
- [ ] Cyberpunk goth aesthetic

### Functional
- [ ] Clearly communicates concept
- [ ] Readable at various sizes
- [ ] Professional polish
- [ ] Not cluttered

---

## Generation Order

**Recommended sequence for consistency:**

1. **hero.png** - Generate first to establish style
2. **spawn.png** - Core feature, set the visual language
3. **architecture.png** - Technical diagram, reference for others
4. **templates.png** - UI mockup, establishes card style
5. **problem.png** - Set the "chaos" aesthetic
6. **respawn.png** - Use established panel style
7. **cospawn.png** - Similar to spawn.png
8. **despawn.png** - Generate last, peaceful contrast

---

## Tips for Best Results

### General
- Use the **same seed** across all generations for consistency
- Start with hero.png to set the style, then match it
- If colors are off, explicitly add hex codes to prompt
- If too realistic, add "flat illustration" or "UI design mockup"

### Midjourney Specific
```
[paste prompt from QUICK-PROMPTS.txt] --ar 16:9 --v 6 --style raw --seed 42069
```

### DALL-E Specific
```
Generate in wide format (1920x1080). [paste prompt]. Photorealistic rendering
disabled, clean digital illustration style preferred.
```

### Stable Diffusion Specific
- **Positive:** Use prompt as-is
- **Negative:** `bright colors, cheerful, cartoonish, low quality, blurry, realistic photo, cluttered, busy`
- **Steps:** 30-50
- **CFG Scale:** 7-9

---

## After Generation

1. **Save** all images to this directory with correct filenames
2. **Verify** against quality checklist above
3. **Update status** in Required Images table
4. **Integrate** into project README.md
5. **Test** images at different sizes (thumbnail, full-width)
6. **Archive** source files (if applicable)

---

## Support

**Questions about:**
- **Brand guidelines:** See `.claude/skills/brrhlv-brand/SKILL.md`
- **Prompt details:** See [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md)
- **Quick prompts:** See [QUICK-PROMPTS.txt](./QUICK-PROMPTS.txt)
- **Session context:** See [GENERATION-SESSION-SUMMARY.md](./GENERATION-SESSION-SUMMARY.md)

**Project:** cc-spawner
**Repository:** ~/projects/opensource/cc-spawner
**Assets:** ~/projects/opensource/cc-spawner/assets/

---

## Next Steps

1. Choose your generation tool (Midjourney recommended)
2. Start with hero.png using prompt from QUICK-PROMPTS.txt
3. Generate remaining 7 images in recommended order
4. Verify each against quality checklist
5. Update README.md with images
6. Update status table above

**Status:** 📝 Specifications complete, ready for generation

---

*Generated by Gemini Designer Agent*
*Brand: brrhlv v4 Clarity Edition*
*Date: 2026-01-21*
