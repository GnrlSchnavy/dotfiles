# Claude Code Configuration

This directory contains Claude Code settings that are version-controlled and managed through dotfiles.

## Files

### `settings.local.json`
Main Claude Code configuration file containing:
- **Permissions**: Bash commands that Claude is allowed to execute
- **Tool Access**: Fine-grained control over system operations
- **Security**: Controlled access to prevent unauthorized commands

## Usage

### Current Configuration
The active configuration grants Claude access to essential development commands:
- File operations (`ls`, `cat`, `find`, `tree`, `grep`)
- Version control (`git add`, `git commit`, `git push`)
- System management (`stow`, `cp`, `mv`, `mkdir`)
- Shell operations (`source`)

### Modifying Permissions
To add or remove Claude permissions:

1. Edit the settings file:
   ```bash
   $EDITOR ~/.dotfiles/system/.claude/settings.local.json
   ```

2. Re-stow to apply changes:
   ```bash
   cd ~/.dotfiles && stow system
   ```

3. Restart Claude Code to pick up new settings

### Environment-Specific Settings
For different environments (work vs personal), consider:
- Creating separate permission profiles
- Using different allowed command sets
- Maintaining minimal permissions for security

## Security Considerations

- **Principle of Least Privilege**: Only grant necessary permissions
- **Command Specificity**: Use specific patterns rather than wildcards when possible
- **Regular Review**: Periodically audit allowed commands
- **Version Control**: All changes are tracked for accountability

## Benefits

- **Consistency**: Same Claude behavior across machines
- **Portability**: Easy setup on new systems
- **Collaboration**: Share configurations with team members
- **Security**: Controlled and auditable permissions
- **Backup**: Settings preserved in version control