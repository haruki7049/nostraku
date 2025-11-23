# Contributing to nostraku

Thank you for your interest in contributing to nostraku! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and collaborative environment. Be kind, considerate, and constructive in your interactions.

## Getting Started

### Prerequisites

- Raku (Rakudo) compiler
- zef package manager
- libsecp256k1 library
- Git

### Setting Up Development Environment

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/nostraku
   cd nostraku
   ```

3. Set up the development environment:

   **Using Nix (recommended):**
   ```bash
   nix develop
   ```

   **Manual setup:**
   - Install Raku/Rakudo
   - Install zef: `git clone https://github.com/ugexe/zef && cd zef && raku -I. bin/zef install .`
   - Install libsecp256k1 (see README.md for platform-specific instructions)

4. Install dependencies:
   ```bash
   zef install --deps-only .
   ```

## Development Workflow

### Making Changes

1. Create a new branch for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
   or
   ```bash
   git checkout -b fix/issue-description
   ```

2. Make your changes, following the coding standards below

3. Test your changes:
   ```bash
   zef test .
   ```

4. Format your code (if using Nix):
   ```bash
   nix fmt
   ```

5. Commit your changes with a clear, descriptive commit message:
   ```bash
   git commit -m "Add feature: brief description"
   ```

6. Push to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

7. Create a Pull Request on GitHub

### Commit Message Guidelines

- Use clear, descriptive messages
- Start with a verb in present tense (Add, Fix, Update, Remove, etc.)
- Keep the first line under 72 characters
- Add a detailed description if necessary

Examples:
```
Add support for NIP-02 contact lists

Fix event ID calculation for events with empty tags

Update documentation for Net::Nostr::Signer
```

## Coding Standards

### Raku Style Guidelines

- Use 4 spaces for indentation (not tabs)
- Follow Raku naming conventions:
  - `kebab-case` for methods and attributes
  - `PascalCase` for classes and types
  - `SCREAMING_SNAKE_CASE` for constants
- Keep lines under 100 characters when possible
- Add whitespace for readability

### Documentation

- All public classes, methods, and functions must have Pod6 documentation
- Use `#|` comments for inline declarator documentation
- Include examples in Pod6 documentation where appropriate
- Update README.md if adding new features

#### Pod6 Documentation Template

```raku
=begin pod

=head1 NAME

Module::Name - Brief description

=head1 SYNOPSIS

=begin code :lang<raku>
use Module::Name;

# Example usage
=end code

=head1 DESCRIPTION

Detailed description of the module.

=head1 METHODS

=head2 method-name

=begin code :lang<raku>
method method-name(Param $param) returns Type
=end code

Description of what the method does.

=end pod
```

### Type Safety

- Use type constraints where appropriate (HexKey, HexSignature, etc.)
- Prefer strong typing over dynamic typing
- Validate inputs when creating new types

### Error Handling

- Use `die` for unrecoverable errors
- Provide clear, helpful error messages
- Document error conditions in Pod6

## Testing

### Writing Tests

- Tests are located in the `t/` directory
- Use `.rakutest` extension for test files
- Follow the existing test structure
- Test both success and failure cases
- Include edge cases in your tests

### Test File Structure

```raku
use Test;
use Net::Nostr::YourModule;

plan N;  # Number of tests

# Test 1
{
    my $result = your-function();
    ok $result, "Description of what is being tested";
}

# Test 2
{
    dies-ok { invalid-call() }, "Should die on invalid input";
}

done-testing;
```

### Running Tests

Run all tests:
```bash
zef test .
```

Run a specific test file:
```bash
raku t/your-test.rakutest
```

## Pull Request Process

1. Ensure your code passes all tests
2. Update documentation to reflect your changes
3. Update CHANGELOG.md (if applicable) with a note about your changes
4. Ensure your PR description clearly explains:
   - What problem it solves
   - How it solves it
   - Any breaking changes
   - Related issues (use "Fixes #123" or "Closes #123")

5. Be responsive to review feedback
6. Squash commits if requested before merge

## Project Structure

```
nostraku/
├── lib/
│   └── Net/
│       └── Nostr/
│           ├── Event.rakumod      # Event representation
│           ├── Message.rakumod    # Protocol messages
│           ├── Signer.rakumod     # Signature generation
│           └── Types.rakumod      # Type definitions
├── t/                             # Tests
│   ├── event.rakutest
│   ├── message.rakutest
│   └── signer.rakutest
├── examples/                      # Usage examples
│   ├── create-note.raku
│   └── message-generation-demo.raku
├── META6.json                     # Package metadata
├── README.md
├── CONTRIBUTING.md
└── LICENSE
```

## Feature Requests and Bug Reports

### Reporting Bugs

When reporting bugs, please include:
- Raku version (`raku --version`)
- libsecp256k1 version
- Operating system
- Steps to reproduce
- Expected behavior
- Actual behavior
- Any error messages or stack traces

### Requesting Features

For feature requests:
- Clearly describe the feature
- Explain the use case
- Provide examples if possible
- Reference relevant NIPs (Nostr Implementation Possibilities) if applicable

## Nostr Protocol Implementation

When implementing Nostr features:
- Reference the appropriate NIP (Nostr Implementation Possibilities)
- Ensure compatibility with existing Nostr implementations
- Test interoperability when possible
- Update documentation to indicate which NIPs are supported

## Questions?

If you have questions about contributing:
- Open an issue on GitHub
- Check existing issues and pull requests
- Review the Nostr protocol documentation

## License

By contributing to nostraku, you agree that your contributions will be licensed under the Artistic-2.0 License.

## Thank You!

Your contributions make this project better for everyone. Thank you for taking the time to contribute!
