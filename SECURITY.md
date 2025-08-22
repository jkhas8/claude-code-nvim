# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| 0.9.x   | :white_check_mark: |
| < 0.9   | :x:                |

## Security Considerations

This project handles file system operations and inter-process communication. Please be aware of the following security aspects:

### File System Access
- The file watcher monitors specified directories and can read file contents
- Changes are applied to files on disk when accepted
- File permissions are preserved during operations
- The system respects existing file access controls

### Inter-Process Communication
- Uses Unix domain sockets for communication between components
- Socket files are created with restrictive permissions (0600 - owner only)
- No network communication is involved
- All communication is local to the machine

### Process Security
- The file watcher runs as the current user (no privilege escalation)
- Neovim plugin operates within the Neovim process context
- No external executables are spawned without user knowledge

### Configuration Files
- Configuration files may contain sensitive paths
- Store configuration files with appropriate permissions
- Avoid including sensitive information in configuration

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### 🚨 **DO NOT** create a public issue for security vulnerabilities

Instead, please report security issues through one of these channels:

1. **Email**: Send details to [security@yourproject.com](mailto:security@yourproject.com)
2. **GitHub Security Advisories**: Use the "Security" tab in the repository
3. **Private message**: Contact maintainers directly

### What to include in your report:

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Impact assessment** (who is affected, how severe)
4. **Suggested fix** (if you have one)
5. **Your contact information** for follow-up

### Response Timeline

- **24 hours**: Acknowledgment of your report
- **72 hours**: Initial assessment and severity classification
- **1 week**: Detailed response with our investigation findings
- **2-4 weeks**: Fix development and testing (depending on complexity)
- **Release**: Security fix released and advisory published

### Disclosure Policy

We follow **coordinated disclosure**:

1. We investigate and develop a fix
2. We notify affected users through appropriate channels
3. We release the fix
4. We publicly disclose the vulnerability details
5. We credit the reporter (with permission)

## Security Best Practices

### For Users

1. **Keep updated**: Always use the latest version
2. **Secure configuration**: 
   - Use restrictive file permissions for config files
   - Only watch necessary directories
   - Review ignore patterns regularly

3. **Monitor access**: 
   - Check socket file permissions: `ls -la /tmp/claude-code-nvim.sock`
   - Verify only intended processes can access the socket

4. **Network isolation**: 
   - This tool operates locally only
   - No network access should be required

### For Contributors

1. **Input validation**: Always validate file paths and user input
2. **Path traversal**: Prevent directory traversal attacks
3. **Resource limits**: Implement appropriate resource limits
4. **Error handling**: Don't leak sensitive information in error messages
5. **Dependency updates**: Keep dependencies updated

### For Deployment

1. **User permissions**: Run with minimal necessary permissions
2. **File system**: Use appropriate file system permissions
3. **Process isolation**: Consider using containers or sandboxing
4. **Monitoring**: Monitor file system access patterns

## Known Security Considerations

### File System Monitoring
- The watcher has read access to monitored directories
- Changes are automatically detected and may be automatically applied
- Consider the implications of monitoring sensitive directories

### Socket Communication
- Unix sockets are used for IPC (more secure than network sockets)
- Socket files should be protected with proper permissions
- Multiple Neovim instances can connect to the same watcher

### Process Communication
- The system relies on process IDs for some functionality
- Process information is used to identify Claude Code instances
- This information is obtained through standard system APIs

## Audit Trail

We maintain logs of:
- File changes detected and processed
- IPC connection events
- Configuration changes
- Error conditions

These logs may contain file paths and should be protected accordingly.

## Compliance

This project aims to follow security best practices including:
- [OWASP Secure Coding Practices](https://owasp.org/www-project-secure-coding-practices-quick-reference-guide/)
- [CIS Security Controls](https://www.cisecurity.org/controls)
- Standard file system security practices

## Security Updates

Security updates will be:
1. **Prioritized** over feature development
2. **Released promptly** after thorough testing
3. **Clearly documented** in release notes
4. **Announced** through project communication channels

## Questions?

If you have security questions or concerns:
- Review this document and the code
- Check existing issues and discussions
- Contact the maintainers through appropriate channels

Thank you for helping keep this project secure! 🔒