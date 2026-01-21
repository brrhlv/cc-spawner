# Quick Start Guide

Get cc-spawner running in 5 minutes.

## Prerequisites

- Windows 10 or 11
- Administrator access
- Git Bash installed
- An Anthropic API key

## Step 1: Clone the Repository

```bash
git clone https://github.com/brrhlv/cc-spawner.git
cd cc-spawner
```

## Step 2: Configure API Key

```bash
# Copy the example file
cp _config/api-keys.env.example _config/api-keys.env

# Edit with your key
notepad _config/api-keys.env
```

Add your Anthropic API key:
```
ANTHROPIC_API_KEY=sk-ant-api03-your-actual-key-here
```

## Step 3: Create Your First User

```bash
./spawner spawn Lab1
```

You'll see a UAC prompt - click Yes to allow administrator access.

The spawn process will:
1. Create Windows user "Lab1"
2. Initialize their profile
3. Install Node.js and nvm
4. Install Claude Code CLI
5. Copy the vanilla template
6. Set up API keys

## Step 4: Test the New Environment

Open a new terminal and switch to the new user:

```bash
runas /user:Lab1 cmd
```

Enter the password when prompted (default: `Spawn12345`)

Then run Claude Code:
```bash
claude
```

You should see a fresh Claude Code instance with no custom configuration.

## Step 5: Clean Up (Optional)

When you're done testing:

```bash
./spawner despawn Lab1 --force
```

This removes the user and backs up their data to `backups/`.

## Next Steps

- [Create custom templates](TEMPLATES.md)
- [Troubleshoot common issues](TROUBLESHOOTING.md)
- Read the full [README](../README.md)

## Common Commands

```bash
# Create user with specific template
./spawner spawn Lab2 --template vanilla

# Reset just the .claude config (keeps user)
./spawner respawn Lab1 --cli

# Copy config from another user
./spawner cospawn Lab2 --from Lab1

# Remove user without confirmation
./spawner despawn Lab1 --force
```
