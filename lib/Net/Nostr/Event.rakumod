=begin pod

=head1 NAME

Net::Nostr::Event - Nostr event representation and manipulation

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Event;
use Net::Nostr::Signer;

# Create a new event
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,  # Text note
    tags       => [["p", "some_pubkey"], ["e", "some_event_id"]],
    content    => "Hello, Nostr!",
);

# Calculate the event ID
$event.id = $event.calculate-id();

# Sign the event
my $signer = Net::Nostr::Signer.new;
$event.sig = $signer.sign($event.id, $private-key);

# Verify the event ID
say "Valid ID" if $event.verify-id();

# Convert to JSON for transmission
say $event.to-json();

# Convert to Hash
my %event-data = $event.to-hash();
=end code

=head1 DESCRIPTION

Net::Nostr::Event represents a Nostr event according to NIP-01 specification.
It provides methods for event creation, ID calculation, verification, and serialization.

Events are the fundamental data structure in Nostr, containing:
=item id - 32-byte hex-encoded SHA256 hash of the serialized event
=item pubkey - 32-byte hex-encoded public key of the event creator
=item created_at - Unix timestamp when the event was created
=item kind - Integer representing the event type
=item tags - Array of arrays containing event metadata
=item content - Arbitrary string content
=item sig - 64-byte hex-encoded Schnorr signature

=head1 ATTRIBUTES

=head2 id

Type: HexKey (64 character hex string)

The event ID, calculated as the SHA256 hash of the serialized event data.
This field is read-write and typically set after calling C<calculate-id()>.

=head2 pubkey

Type: HexKey (64 character hex string), required

The public key of the event creator in hex format.

=head2 created_at

Type: Timestamp (Unix timestamp), required

Unix timestamp when the event was created. Defaults to C<now.Int>.

=head2 kind

Type: Kind (non-negative integer), required

Event kind identifier. Common values:
=item 0 - Metadata
=item 1 - Text note
=item 2 - Recommend relay
=item 3 - Contacts
=item 4 - Encrypted direct messages
=item 7 - Reaction

=head2 tags

Type: Tags (array of arrays), required

Array of tags for the event. Each tag is an array of strings.
Common tag types include "e" (event reference) and "p" (pubkey reference).
Defaults to empty array.

=head2 content

Type: Str, required

The content of the event. Defaults to empty string.

=head2 sig

Type: HexSignature (128 character hex string)

The Schnorr signature of the event. This field is read-write and typically
set after signing the event with C<Net::Nostr::Signer>.

=head1 METHODS

=head2 serialize-for-id

=begin code :lang<raku>
method serialize-for-id() returns Str
=end code

Serializes the event data according to NIP-01 for ID generation and signing.
Returns a JSON string in the format: [0, <pubkey>, <created_at>, <kind>, <tags>, <content>]

The serialization uses compact JSON format (no extra whitespace) to ensure
canonical representation for consistent hash calculation.

=head2 calculate-id

=begin code :lang<raku>
method calculate-id() returns Str
=end code

Calculates the SHA256 hash of the serialized event data.
Returns a 64-character hex string that serves as the event ID.

This should be called before signing the event and the result should be
assigned to the C<id> attribute.

=head2 verify-id

=begin code :lang<raku>
method verify-id() returns Bool
=end code

Verifies that the current C<id> attribute matches the calculated hash
of the event content. Returns True if valid, False otherwise.

Useful for verifying the integrity of received events.

=head2 to-hash

=begin code :lang<raku>
method to-hash() returns Hash
=end code

Converts the event to a Hash containing all event fields.
This is useful for embedding events in protocol messages or further processing.

Returns a Hash with keys: id, pubkey, created_at, kind, tags, content, sig.

=head2 to-json

=begin code :lang<raku>
method to-json() returns Str
=end code

Converts the event to a JSON string representation using compact format.
The resulting JSON can be transmitted directly to Nostr relays.

=head1 AUTHOR

haruki7049

=head1 SEE ALSO

=item L<Net::Nostr::Types> - Type definitions
=item L<Net::Nostr::Signer> - Event signing
=item L<Net::Nostr::Message> - Protocol messages

=head1 LICENSE

MIT

=end pod

unit class Net::Nostr::Event;

use JSON::Fast;
use Digest::SHA;
use Net::Nostr::Types;

has HexKey $.id is rw;
has HexKey $.pubkey is required;
has Timestamp $.created_at is required = now.Int;
has Kind $.kind is required;
has Tags $.tags is required = [];
has Str $.content is required = "";
has HexSignature $.sig is rw;

#| Serialize the event data according to NIP-01 for ID generation and signing
#| Format: [0, <pubkey>, <created_at>, <kind>, <tags>, <content>]
method serialize-for-id() returns Str {
    # Ensure tags are treated correctly. Simplified structure here.
    my @data =
        0,
        $!pubkey,
        $!created_at,
        $!kind,
        $!tags,
        $!content;

    # Use :!pretty to ensure no extra whitespace (Canonical JSON)
    return to-json(@data, :!pretty);
}

#| Calculate the SHA256 hash of the serialized event (The Event ID)
method calculate-id() returns Str {
    my $serialized = self.serialize-for-id();
    # sha256 returns a Blob, convert to hex string manually to be safe
    return sha256($serialized.encode).list.fmt('%02x', '');
}

#| Verify if the current ID matches the content
method verify-id() returns Bool {
    return self.calculate-id() eq $!id;
}

#| Return the event as a Hash (for embedding in protocol messages)
method to-hash() returns Hash {
    return %(
        id         => $!id,
        pubkey     => $!pubkey,
        created_at => $!created_at,
        kind       => $!kind,
        tags       => $!tags,
        content    => $!content,
        sig        => $!sig,
    );
}

#| Convert the whole object to JSON for transmission
method to-json() returns Str {
    return to-json(self.to-hash, :!pretty);
}
