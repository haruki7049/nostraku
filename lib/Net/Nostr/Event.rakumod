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

#| Convert the whole object to JSON for transmission
method to-json() returns Str {
    my %payload =
        id         => $!id,
        pubkey     => $!pubkey,
        created_at => $!created_at,
        kind       => $!kind,
        tags       => $!tags,
        content    => $!content,
        sig        => $!sig;

    return to-json(%payload, :!pretty);
}
