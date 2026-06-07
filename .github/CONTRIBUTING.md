# Contributing to mamadera 🍼

Thank you for your interest in contributing to **mamadera**, the privacy-first newborn activity tracker!

## 🌟 Code of Conduct

Please read our [Code of Conduct](CODE_OF_CONDUCT.md) before participating in this project.

## 📋 How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**How to Report a Bug:**
- Use a clear and descriptive title
- Describe the steps to reproduce
- Include expected vs actual behavior
- Add screenshots if applicable
- Specify your Flutter/Dart version

### Suggesting Features

Feature suggestions are welcome! Please ensure:
- It aligns with our **privacy-first philosophy**
- It adds genuine value for parents
- We've explored the feature first

**How to Suggest a Feature:**
- Clearly describe the use case
- Explain the benefits
- Note any potential privacy implications

### Pull Requests

1. Fork the repository
2. Create a branch from `main`:
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Make your changes
4. Add tests (minimum 80% coverage for `domain/` and `data/`)
5. Update documentation if needed
6. Commit with conventional messages:
   ```bash
   git commit -m "feat: add amazing feature"
   git commit -m "fix: resolve login issue"
   git commit -m "chore: update dependencies"
   ```
7. Push and open a Pull Request

### Pre-Commit Checklist

- [ ] Code formatted: `dart format lib/`
- [ ] Lint passes: `flutter analyze`
- [ ] Tests pass: `flutter test`
- [ ] No sensitive data committed
- [ ] Privacy implications documented

## 🧪 Testing

We value quality code. Please ensure:

- **Unit tests** for business logic (`domain/`)
- **Widget tests** for critical UI screens (`presentation/`)
- Mock strict dependencies and database
- Edge cases and error handling covered

## 💻 Development Guidelines

### Code Style
- Use `final`/`const` when possible
- Extract widgets > 25 lines
- Prefer sealed classes for states/events
- Use `///` Dartdoc for public elements
- `camelCase` (vars/fct), `PascalCase` (classes/widgets)

### Architecture
- Feature-first Clean Architecture
- Offline-first design
- Local storage only (no cloud sync by default)

### Privacy First
- Never add analytics, telemetry, or cloud tracking
- All data remains local unless user exports manually
- Minimal permissions: none by default
- GDPR/CCPA/COPPA compliance out-of-the-box

## 📚 Documentation

- Update README if your change affects public API
- Add inline comments for complex logic
- Document privacy implications for new features

## 🤝 Community

- Be respectful and constructive
- Welcome newcomers
- Help review PRs
- Share knowledge

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## ❓ Questions?

Open an issue or discuss in the [Discussions](https://github.com/your-username/mamadera/discussions) tab.

---

**Happy Coding! 🍼💙**
```