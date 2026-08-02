# Security Policy 🔒

## Reporting a Vulnerability

We take the security of **mamadera** seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Preferred Reporting

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, use the [Security Advisories](https://github.com/pierou/mamadera/security/advisories) tab to submit a private report.

### What We Expect

- Clear description of the vulnerability
- Steps to reproduce it
- Impact assessment
- Preferred fix (optional)

### What We Promise

- **24-hour acknowledgment** of your report
- **Non-disclosure** of your identity until you're ready
- **Responsible disclosure** - we won't publicly discuss until fixed
- **Credit** (with permission) in release notes
- **Free fix** - no charges for vulnerability resolution

## Security Best Practices

### Our Commitment

- ✅ **No telemetry/analytics** by default
- ✅ **Local-first architecture** - all data stays on device
- ✅ **Open source** - code is auditable by anyone
- ✅ **Minimal permissions** - only what's essential
- ✅ **GDPR/CCPA compliant** - privacy by design

### Data Protection

- **Encryption**: All sensitive data encrypted with `flutter_secure_storage`
- **Local Storage**: No cloud sync unless user explicitly requests
- **No Tracking**: Zero third-party SDKs, no analytics, no crash reporting
- **Export Control**: User-controlled data export only (JSON encrypted or CSV)

### Dependencies

- **Regular Updates**: Dependabot configured for automated security updates
- **Audit Trail**: All dependencies documented and reviewed
- **No Hidden Trackers**: Manual review of all new packages for privacy implications

### Incident Response

If a security issue is discovered:

1. **Assess Impact** - Determine scope and severity
2. **Patch Quickly** - Fix within 48 hours for critical issues
3. **Communicate** - Notify users and contributors
4. **Review** - Post-mortem to prevent recurrence

## Security Guidelines for Contributors

### Code Review Checklist

- [ ] No hardcoded secrets or API keys
- [ ] Proper input validation on all endpoints
- [ ] Secure storage of sensitive data
- [ ] No unnecessary network requests
- [ ] Privacy implications documented
- [ ] Third-party dependencies audited

### Vulnerable Patterns to Avoid

```dart
// ❌ NEVER DO THIS
// Hardcoded keys
const api_key = "secret123";

// Unencrypted data
Database.instance.save("password", "plain_text");

// External tracking
await analytics.logEvent("user_action");

// Unsafe input
await database.insert(data); // No validation
```

```dart
// ✅ DO THIS INSTEAD
// Environment variables + secure storage
final apiKey = await secureStorage.read(key: 'api_key');

// Encrypted data
final encrypted = await crypto.encrypt(data, key);
Database.instance.save("password", encrypted);

// Local-only, no tracking
// No external analytics or telemetry
```

## Security Updates

Security updates are released promptly. Check:
- [Releases](https://github.com/pierou/mamadera/releases)
- [Security Advisories](https://github.com/pierou/mamadera/security/advisories)

## Third-Party Audits

We welcome security audits. Contact us to discuss terms and scheduling.

## License

Security issues are reported under the same MIT License terms as the project, with confidentiality obligations for unpatched vulnerabilities.

---

**mamadera is built with security and privacy at its core. 🛡️🍼**
```