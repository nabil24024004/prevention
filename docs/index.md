# Documentation Index

Welcome to the **Prevention** app documentation. This folder contains comprehensive guides for developers, contributors, and stakeholders.

---

## 📚 Documentation Structure

### Getting Started
- [README](../README.md) - Project overview and quick start
- [context.md](context.md) - Problem statement, solution approach, and vision

### Features & Functionality
- [features.md](features.md) - Detailed feature documentation with technical details
  - VPN blocking system
  - Streak tracking mechanics
  - Islamic motivation content
  - Relapse accountability flow
  - Offline sync capabilities

### Technical Documentation
- [architecture.md](architecture.md) - System design and tech stack
  - Architecture diagrams
  - Layer responsibilities
  - Data flow
  - Scalability considerations

- [api.md](api.md) - API reference and database schemas
  - Supabase RPC functions
  - REST endpoints
  - Table schemas
  - Code examples

### Security
- [security_walkthrough.md](security_walkthrough.md) - Complete security implementation
  - Tier 1-4 remediation
  - All security features explained
  - Verification steps

- [session_security_verification.md](session_security_verification.md) - Supabase auth configuration
  - JWT settings
  - Refresh token rotation
  - Reuse detection

- [conflict_resolution_policy.md](conflict_resolution_policy.md) - Offline sync conflict handling
  - Conflict scenarios
  - Resolution strategies
  - Server-wins policy

### Deployment & Testing
- [deployment_guide.md](deployment_guide.md) - Production deployment instructions
  - Pre-deployment checklist
  - Build commands
  - Distribution options
  - Monitoring queries

- [testing_instructions.md](testing_instructions.md) - Beta testing protocol
  - Installation steps
  - Testing scenarios
  - Bug reporting

---

## 🗂️ File Organization

```
docs/
├── index.md                          # This file
├── context.md                        # Project background
├── features.md                       # Feature documentation
├── architecture.md                   # System design
├── api.md                            # API reference
├── security_walkthrough.md           # Security implementation
├── session_security_verification.md  # Auth settings
├── conflict_resolution_policy.md     # Offline sync policy
├── deployment_guide.md               # Deployment instructions
└── testing_instructions.md           # Testing guide
```

---

## 🔍 Quick Navigation

### For Developers
1. Start with [README](../README.md) for setup
2. Read [architecture.md](architecture.md) to understand system design
3. Reference [api.md](api.md) for API usage
4. Check [features.md](features.md) for implementation details

### For Security Auditors
1. Review [security_walkthrough.md](security_walkthrough.md)
2. Check [session_security_verification.md](session_security_verification.md)
3. Verify [conflict_resolution_policy.md](conflict_resolution_policy.md)

### For Beta Testers
1. Follow [testing_instructions.md](testing_instructions.md)
2. Reference [features.md](features.md) for expected behavior

### For Stakeholders
1. Read [context.md](context.md) for problem/solution overview
2. Review [features.md](features.md) for capability summary
3. Check [deployment_guide.md](deployment_guide.md) for launch readiness

---

## 📝 Documentation Standards

All documentation follows:
- **Markdown format** for readability
- **Code examples** where applicable
- **Visual diagrams** (ASCII art or Mermaid)
- **Version tracking** (date in footer)
- **Cross-references** between docs

---

## 🤝 Contributing to Docs

To improve documentation:

1. Fork repository
2. Edit relevant `.md` file
3. Follow existing style guide
4. Submit pull request

**Style Guide**:
- Use headers for sections
- Include code examples
- Add diagrams where helpful
- Keep language clear and concise

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/prevention/issues)
- **Documentation questions**: Tag with `documentation` label

---

**Last Updated**: January 2026
