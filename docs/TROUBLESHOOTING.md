# Troubleshooting Guide

Common issues and solutions for cc-spawner.

## Permission Issues

### "Access Denied" or "Must run as Administrator"

**Problem:** Spawner needs admin rights to create Windows users.

**Solution:**
```bash
# Option 1: Let spawner request elevation (default)
./spawner spawn Lab1
# Click "Yes" on UAC prompt

# Option 2: Run from elevated PowerShell
powershell -Command "Start-Process powershell -Verb RunAs"
# Then run spawner from elevated window
```

### "User already exists"

**Problem:** Trying to spawn a user that already exists.

**Solution:**
```bash
# Remove existing user first
./spawner despawn Lab1 --force

# Then spawn fresh
./spawner spawn Lab1
```

## Installation Issues

### Node.js not found after spawn

**Problem:** Claude Code can't find Node after switching to spawned user.

**Solution:**
```bash
# As the spawned user, refresh environment
refreshenv

# Or restart the terminal
exit
runas /user:Lab1 cmd
```

### nvm not recognized

**Problem:** nvm-windows didn't install correctly.

**Solution:**
```bash
# Check nvm location
dir "C:\Users\Lab1\AppData\Roaming\nvm"

# If missing, respawn the user
./spawner respawn Lab1 --full
```

### Claude Code installation fails

**Problem:** npm install fails for Claude Code.

**Solution:**
```bash
# Check npm is working
runas /user:Lab1 cmd
npm --version

# Try manual install
npm install -g @anthropic-ai/claude-code

# If npm fails, check Node installation
node --version
```

## Configuration Issues

### API key not working

**Problem:** Claude says API key is invalid.

**Solutions:**

1. Check `_config/api-keys.env` has the correct key:
   ```bash
   cat _config/api-keys.env
   # Should show: ANTHROPIC_API_KEY=sk-ant-api03-...
   ```

2. Check it was copied to user:
   ```bash
   # As spawned user
   echo %ANTHROPIC_API_KEY%
   ```

3. Reset the config:
   ```bash
   ./spawner respawn Lab1 --cli
   ```

### Template not applied

**Problem:** Spawned user doesn't have expected config.

**Solutions:**

1. Verify template exists:
   ```bash
   ls templates/your-template/.claude/
   ```

2. Check config.json has the template:
   ```bash
   cat config.json | grep your-template
   ```

3. Check the user's .claude folder:
   ```bash
   dir "C:\Users\Lab1\.claude"
   ```

## User Management Issues

### Can't switch to spawned user

**Problem:** `runas` fails or password rejected.

**Solutions:**

1. Check user exists:
   ```powershell
   net user Lab1
   ```

2. Verify password (default: `Spawn12345`):
   ```bash
   runas /user:Lab1 cmd
   # Enter: Spawn12345
   ```

3. Check manifest.json for recorded password:
   ```bash
   cat manifest.json
   ```

### User profile not created

**Problem:** `C:\Users\Lab1` doesn't exist after spawn.

**Solution:**
```bash
# Spawner should auto-initialize, but you can force it:
./spawner respawn Lab1 --full
```

## Backup/Recovery

### Find backups

Backups are stored in `backups/` with timestamps:
```bash
ls backups/
# Lab1_20250121_143022.zip
```

### Restore from backup

```bash
# 1. Spawn a new user
./spawner spawn Lab1

# 2. Extract backup to their .claude
unzip backups/Lab1_20250121_143022.zip -d "C:\Users\Lab1\.claude"
```

## Logs

Check operation logs for detailed error messages:

```bash
# View today's log
cat logs/spawner-$(date +%Y-%m-%d).log

# View all logs
ls logs/
```

## Still Stuck?

1. Check the [GitHub Issues](https://github.com/brrhlv/cc-spawner/issues)
2. Search for similar problems
3. Open a new issue with:
   - Windows version
   - PowerShell version
   - Full error message
   - Steps to reproduce
   - Relevant log output
