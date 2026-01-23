#!/usr/bin/env node

/**
 * Gemini Image Generation Script for cc-spawner
 * Generates 8 branded images using Google Gemini Imagen
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const API_ENDPOINT = 'https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-001:predict';

if (!GEMINI_API_KEY) {
  console.error('Error: GEMINI_API_KEY environment variable not set');
  process.exit(1);
}

const prompts = {
  'problem.png': `SUBJECT: Chaotic developer workspace showing the problem of testing in production
STYLE: Cyberpunk goth, dark moody atmosphere, technical nightmare visualization
COLORS: Background #0C0C0F, error indicators #EF4444, warning glow in orange, multiple overlapping Claude 'C' logos glitching
COMPOSITION: Single overwhelmed developer desk with multiple monitors, tangled dependency lines crossing the scene, floating error messages, red warning triangles, frustrated developer silhouette in shadow
TECHNICAL: Dark background #0C0C0F, red error glow effects, glitch aesthetic on logos
AVOID: Bright colors, cheerful mood, organized workspace, blue tones`,

  'spawn.png': `SUBJECT: Minecraft monster spawner cage spawning development environment components into a new user profile
STYLE: Cyberpunk tech visualization, clean assembly process, purple particle effects
COLORS: Spawner cage in dark metal with purple glow #7C3AED inside, components with purple accent #9061F9, success indicator #9CB92C, background #0C0C0F
COMPOSITION: Top third shows Minecraft-style metal cage spawner with purple glow, middle shows components dropping down (folder icon, Node.js hexagon, Claude C logo, gear icon, key icon), bottom shows newly formed Lab1 user profile with green success glow
TECHNICAL: Purple particle effects flowing downward, dark background #0C0C0F, green success state #9CB92C
AVOID: Bright backgrounds, realistic rendering, cluttered composition, multiple spawners`,

  'respawn.png': `SUBJECT: Split-screen before and after reset transformation visualization
STYLE: Cyberpunk UI, clean technical diagram, transformation process
COLORS: Left panel orange warning #F59E0B, center mechanism purple #7C3AED, right panel green success #9CB92C, background #0C0C0F
COMPOSITION: Three vertical panels - LEFT corrupted environment with orange glow and wear marks, CENTER reset mechanism showing --cli and --full option badges with circular refresh arrow, RIGHT pristine fresh environment with green success glow
TECHNICAL: Dark background #0C0C0F, subtle panel dividers in #27272A, transformation flow from left to right
AVOID: Cluttered interface, realistic textures, multiple reset options, confusing layout`,

  'despawn.png': `SUBJECT: User profile dissolving peacefully into particles
STYLE: Cyberpunk goth, elegant dissolution, peaceful removal aesthetic
COLORS: Profile labeled Lab2 dissolving into purple particles #7C3AED and #9061F9, platform below in #18181B, void space in #0C0C0F, optional backup chest in steel #A1A1AA
COMPOSITION: Center focus on Lab2 user profile breaking into purple particles floating upward, platform retracting downward, backup chest in bottom right catching data, empty void space below indicating complete cleanup
TECHNICAL: Purple particle effect with glow, dark void background #0C0C0F, subtle platform texture
AVOID: Violent destruction, fire effects, bright colors, cluttered scene`,

  'cospawn.png': `SUBJECT: Configuration cloning between two user profiles
STYLE: Cyberpunk technical visualization, data transfer process, clean tech aesthetic
COLORS: Lab1 source with green #9CB92C status, scanning mechanism with blue scan lines, Lab2 target materializing, data flow particles in purple #9061F9, background #0C0C0F
COMPOSITION: LEFT shows established Lab1 profile with green checkmark, CENTER shows scanning/copying mechanism with blue holographic scan lines, RIGHT shows Lab2 materializing as config items duplicate, purple data flow particles between profiles
TECHNICAL: Dark background #0C0C0F, blue scan effect, purple data particles with glow
AVOID: Complex UI, realistic rendering, multiple profiles, confusing data flow`,

  'architecture.png': `SUBJECT: System architecture cross-section showing Windows OS with isolated user environments
STYLE: Cyberpunk technical diagram, clean architecture visualization, isometric or side-view
COLORS: MAIN user with gold crown #F59E0B and protected glow, Lab1 green #9CB92C, Lab2 blue accent, spawner hub purple #7C3AED, isolation walls #27272A, background #0C0C0F, shared kernel #18181B
COMPOSITION: Cross-section view showing Windows container with three side-by-side user environments (MAIN left with gold crown icon labeled protected, Lab1 center green labeled testing, Lab2 right blue labeled experimental), Minecraft spawner cage in center top as cc-spawner hub with purple connection lines to each user, isolation walls between users, shared kernel layer at bottom
TECHNICAL: Dark background #0C0C0F, subtle depth with elevated surfaces #18181B, purple connection glows
AVOID: Flat 2D layout, cluttered labels, realistic Windows UI, too many users`,

  'templates.png': `SUBJECT: Template selection UI grid showing four template cards
STYLE: Cyberpunk UI design, clean card layout, modern interface
COLORS: Selected card with purple glow #7C3AED, unselected cards #18181B with border #27272A, text in steel #D4D4D8, icons purple #9061F9, background #0C0C0F
COMPOSITION: 2x2 grid of template cards (vanilla/default top-left with checkmark icon, minimal top-right with simplified icon, pai/advanced bottom-left with gear icon, custom bottom-right with wrench icon), selected vanilla card has purple glow border, command shown below: ./spawner spawn Lab1 --template vanilla
TECHNICAL: Dark background #0C0C0F, card elevation #18181B, purple selection glow, clean icons
AVOID: Cluttered cards, realistic shadows, too many templates, complex icons`,

  'hero.png': `SUBJECT: Hero title image for cc-spawner project with centerpiece spawner cage
STYLE: Cyberpunk goth, dramatic hero composition, purple accent lighting, moody atmosphere
COLORS: Title cc-spawner in steel light #D4D4D8 with purple glow #7C3AED, spawner cage metal dark with purple inner glow #9061F9, Lab avatars in green #9CB92C, blue accent, orange #F59E0B, background deep dark #0C0C0F
COMPOSITION: Large cc-spawner title at top with purple glow effect, Minecraft monster spawner cage as centerpiece with Claude C logo spinning inside purple glow, three spawned user avatars below in a row (Lab1 green glowing, Lab2 blue glowing, Lab3 orange glowing), tagline at bottom: Isolated Claude Code test environments for Windows
TECHNICAL: Dark cyberpunk atmosphere #0C0C0F background, subtle purple accent lighting from spawner, glow effects on title and avatars
AVOID: Bright colors, cluttered composition, realistic rendering, too many elements, busy background`
};

async function generateImage(filename, prompt) {
  return new Promise((resolve, reject) => {
    const requestBody = JSON.stringify({
      instances: [{
        prompt: prompt
      }],
      parameters: {
        sampleCount: 1,
        aspectRatio: '16:9',
        negativePrompt: 'bright colors, cheerful, cartoonish, low quality, blurry'
      }
    });

    const options = {
      hostname: 'generativelanguage.googleapis.com',
      path: `/v1beta/models/imagen-3.0-generate-001:predict?key=${GEMINI_API_KEY}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(requestBody)
      }
    };

    console.log(`\nGenerating ${filename}...`);

    const req = https.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(data);

          if (response.error) {
            reject(new Error(`API Error: ${response.error.message}`));
            return;
          }

          if (response.predictions && response.predictions[0]) {
            const imageBase64 = response.predictions[0].bytesBase64Encoded;
            const imageBuffer = Buffer.from(imageBase64, 'base64');
            const outputPath = path.join(__dirname, filename);

            fs.writeFileSync(outputPath, imageBuffer);
            console.log(`✓ Saved ${filename}`);
            resolve(outputPath);
          } else {
            reject(new Error('No image data in response'));
          }
        } catch (error) {
          reject(error);
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(requestBody);
    req.end();
  });
}

async function generateAllImages() {
  console.log('Starting cc-spawner image generation...');
  console.log('Using brrhlv brand guidelines (Cyberpunk Goth aesthetic)');

  const files = Object.keys(prompts);

  for (let i = 0; i < files.length; i++) {
    const filename = files[i];
    const prompt = prompts[filename];

    try {
      await generateImage(filename, prompt);

      // Rate limiting - wait 2 seconds between requests
      if (i < files.length - 1) {
        console.log('Waiting 2s before next request...');
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    } catch (error) {
      console.error(`✗ Failed to generate ${filename}: ${error.message}`);
    }
  }

  console.log('\n✓ Image generation complete!');
  console.log(`Output directory: ${__dirname}`);
}

generateAllImages().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
