=begin pod

=head1 NAME

Net::Nostr::Types - Type definitions for Nostr protocol

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Types;

# HexKey - 64 character hex string (32 bytes)
my HexKey $pubkey = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";

# Bech32Key - Bech32-encoded key string (e.g., npub, nsec)
my Bech32Key $bech32-pubkey = "npub1l2vyh47mk2x0yd54r82frvx8v6u0jvwdkq3h9y4xew8t0p7znp5qx2r9yf";

# Key - Accepts either HexKey or Bech32Key
my Key $hex-key = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";
my Key $bech32-key = "npub1l2vyh47mk2x0yd54r82frvx8v6u0jvwdkq3h9y4xew8t0p7znp5qx2r9yf";

# HexSignature - 128 character hex string (64 bytes)
my HexSignature $sig = "a" x 128;

# Timestamp - Unix timestamp (non-negative integer)
my Timestamp $created-at = now.Int;

# Kind - Event kind identifier (non-negative integer)
my Kind $kind = 1;  # Text note

# Tag - Single tag as array of strings
my Tag $tag = ["e", "event_id_here"];

# Tags - Array of tags
my Tags $tags = [
    ["e", "event_id"],
    ["p", "pubkey"],
];
=end code

=head1 DESCRIPTION

This module defines type constraints for the Nostr protocol according to NIP-01.
All types are exported and can be used to validate data structures.

=head1 TYPES

=head2 HexKey

A subset of Str that represents a 32-byte hex-encoded string (64 characters).
Used for public keys, private keys, and event IDs in the Nostr protocol.

Validates that the string consists of exactly 64 lowercase hexadecimal digits (0-9, a-f).

=head2 HexSignature

A subset of Str that represents a 64-byte hex-encoded string (128 characters).
Used for Schnorr signatures in Nostr events.

Validates that the string consists of exactly 128 lowercase hexadecimal digits (0-9, a-f).

=head2 Bech32Key

A subset of Str that represents a Bech32-encoded key string.
Bech32 is an encoding format used in various cryptocurrencies and protocols.
In Nostr, it's commonly used for encoding public keys and other identifiers
in a human-readable format (e.g., npub, nsec prefixes).

Validates that the string follows the Bech32 format: lowercase letters,
followed by the separator '1', followed by alphanumeric characters.

=head2 Key

A subset of Str that accepts either HexKey or Bech32Key format.
This provides flexible key validation, allowing applications to work with
both hex-encoded keys (64 character hex strings) and Bech32-encoded keys
(human-readable format with prefixes like npub, nsec).

This is useful when accepting user input or working with different key
representations in the Nostr protocol.

=head2 Timestamp

A subset of Int representing a Unix timestamp (non-negative integer).
Used for the C<created_at> field in Nostr events.

=head2 Kind

A subset of Int representing an event kind (non-negative integer).
Common kinds include:
=item 0 - Metadata
=item 1 - Text note
=item 2 - Recommend relay
=item 3 - Contacts
=item 4 - Encrypted direct messages
=item 7 - Reaction

=head2 Tag

A subset of Array where all elements are strings.
Represents a single tag in a Nostr event, e.g., ["e", "event_id"] or ["p", "pubkey"].

=head2 Tags

A subset of Array where all elements are Tags.
Represents the complete list of tags in a Nostr event.

=head1 AUTHOR

haruki7049

=head1 LICENSE

Artistic-2.0

=end pod

unit module Net::Nostr::Types;

#| Subset for 32-byte hex-encoded string (64 characters)
#| Validates that the string consists of exactly 64 lowercase hex digits
my subset HexKey of Str is export where * ~~ /^ <[0..9a..f]> ** 64 $/;

#| Subset for Bech32-encoded key string
#| Validates that the string follows the Bech32 format with lowercase letters,
#| followed by '1', and alphanumeric characters
my subset Bech32Key of Str is export where * ~~ /^ <[a..z]>+ '1' <[a..z0..9]>+ $/;

#| Subset that accepts either HexKey or Bech32Key format
#| Provides flexible key validation for both hex-encoded and Bech32-encoded keys
my subset Key of Str is export where HexKey | Bech32Key;

#| 64-byte hex-encoded string (128 characters) - for Signatures
my subset HexSignature of Str is export where * ~~ /^ <[0..9a..f]> ** 128 $/;

#| Unix Timestamp (non-negative integer)
my subset Timestamp of Int is export where * >= 0;

#| Event Kind (non-negative integer)
my subset Kind of Int is export where * >= 0;

#| A single tag is a list of strings (e.g. ["e", "event_id"])
#| Validates that it is an Array and all elements are Strings
my subset Tag of Array is export where { .all ~~ Str };

#| List of tags (e.g. [ ["e", "..."], ["p", "..."] ])
#| Validates that it is an Array and all elements are Tags
my subset Tags of Array is export where { .all ~~ Tag };
