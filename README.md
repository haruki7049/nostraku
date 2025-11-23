# nostraku

A Nostr protocol implementation for Raku (Perl 6)

## Description

**nostraku** is a Raku library that provides data types and utilities for working with the Nostr protocol. It implements the core functionality defined in NIP-01 (Nostr Implementation Possibilities), including event creation, signing, and message formatting.

Nostr (Notes and Other Stuff Transmitted by Relays) is a simple, open protocol for creating censorship-resistant social networks. This library helps you build Nostr-compatible applications in Raku.

## Installation

### Prerequisites

You need to have the following installed:

- **Raku** (Rakudo) - The Raku compiler
- **zef** - Raku module installer
- **libsecp256k1** - For cryptographic operations

#### Installing libsecp256k1

**On Debian/Ubuntu:**

```bash
sudo apt-get install libsecp256k1-dev
```

**On macOS with Homebrew:**

```bash
brew install libsecp256k1
```

**On NixOS (using flake):**

```bash
nix develop
```

### Installing nostraku

Using zef:

```bash
zef install nostraku
```

Or from source:

```bash
git clone https://github.com/haruki7049/nostraku
cd nostraku
zef install .
```

## Quick Start

### Creating and Signing an Event

```raku
use Net::Nostr::Event;
use Net::Nostr::Signer;

# Create an event
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,  # Text note
    tags       => [],
    content    => "Hello, Nostr!",
);

# Calculate event ID
$event.id = $event.calculate-id();

# Sign the event
my $signer = Net::Nostr::Signer.new;
my $private-key = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144";
$event.sig = $signer.sign($event.id, $private-key);

# Convert to JSON
say $event.to-json();
```

### Creating Protocol Messages

```raku
use Net::Nostr::Message;
use Net::Nostr::Event;

# EVENT message
my $event-msg = Net::Nostr::Message.new-event($event);
say $event-msg.to-json();

# REQ message
my $req-msg = Net::Nostr::Message.new-req(
    "subscription-id",
    [
        { kinds => [1], limit => 10 },
        { authors => ["pubkey-hex"] },
    ]
);
say $req-msg.to-json();

# CLOSE message
my $close-msg = Net::Nostr::Message.new-close("subscription-id");
say $close-msg.to-json();
```

## Development

### Setting up the development environment

Using Nix:

```bash
nix develop
```

Or manually install:

- Raku/Rakudo
- zef
- libsecp256k1

### Running tests

```bash
zef test .
```

### Code formatting

```bash
nix fmt
```

## License

This project is licensed under the Artistic-2.0 License - see the [LICENSE](LICENSE) file for details.

## Links

- [GitHub Repository](https://github.com/haruki7049/nostraku)
- [Nostr Protocol](https://github.com/nostr-protocol/nostr)
- [NIP-01 Specification](https://github.com/nostr-protocol/nips/blob/master/01.md)
- [Raku Language](https://raku.org/)
