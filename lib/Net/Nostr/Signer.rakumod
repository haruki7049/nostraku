=begin pod

=head1 NAME

Net::Nostr::Signer - Facade for Nostr event signing with pluggable backends

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Signer;
use Net::Nostr::Event;

# Create a signer instance (uses OpenSSL backend by default)
my $signer = Net::Nostr::Signer.new;

# Or explicitly specify the backend
my $signer = Net::Nostr::Signer.new(backend => 'OpenSSL');

# Create and prepare an event
my $event = Net::Nostr::Event.new(
    pubkey     => "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320",
    created_at => now.Int,
    kind       => 1,
    tags       => [],
    content    => "Hello, Nostr!",
);

# Calculate event ID
$event.id = $event.calculate-id();

# Sign the event with private key
my $private-key = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144";
$event.sig = $signer.sign($event.id, $private-key);

say "Signature: $event.sig()";
=end code

=head1 DESCRIPTION

Net::Nostr::Signer is a facade class that provides a unified interface for
Nostr event signing with support for pluggable cryptographic backends.

This module uses the Strategy pattern implemented with Raku roles to allow
different signing backends to be swapped without changing user code.

The Nostr protocol requires BIP-340 Schnorr signatures over the secp256k1 curve
as specified in NIP-01. Different backends may implement this using various
cryptographic libraries.

B<SECURITY NOTE>: Private keys should be handled with extreme care. Never
hardcode them in your source code or commit them to version control.

=head1 AVAILABLE BACKENDS

=head2 OpenSSL (default)

Uses OpenSSL's libcrypto for elliptic curve operations. Requires libssl-dev
to be installed on the system.

=head2 Libsecp256k1

Uses Bitcoin Core's libsecp256k1 library which provides native BIP-340 Schnorr
signature support. Requires libsecp256k1-dev to be installed on the system.

=head1 ATTRIBUTES

=head2 $.backend

The backend signer instance that implements the Net::Nostr::Role::Signer role.

=head1 METHODS

=head2 new

=begin code :lang<raku>
method new(Str :$backend = 'OpenSSL')
=end code

Creates a new signer instance with the specified backend.

Parameters:
=item :$backend - Backend name (default: 'OpenSSL')

Available backends:
=item 'OpenSSL' - Uses OpenSSL libcrypto
=item 'Libsecp256k1' - Uses Bitcoin Core's libsecp256k1 library

=head2 sign

=begin code :lang<raku>
method sign(Str $id-hex, Str $privkey-hex --> Str)
=end code

Signs a 32-byte message hash (event ID) with a private key.

Parameters:
=item $id-hex - The event ID as a 64-character hex string
=item $privkey-hex - The private key as a 64-character hex string

Returns a 128-character hex string representing the Schnorr signature.

Dies with an error message if signing fails.

=head1 EXTENDING WITH NEW BACKENDS

To add a new backend, create a class that implements the Net::Nostr::Role::Signer role:

=begin code :lang<raku>
use Net::Nostr::Role::Signer;

unit class Net::Nostr::Signer::MyBackend;
also does Net::Nostr::Role::Signer;

method sign(Str $id-hex, Str $privkey-hex --> Str) {
    # Your implementation here
}
=end code

Then update this facade class to include the new backend in the constructor.

=head1 AUTHOR

haruki7049

=head1 SEE ALSO

=item L<Net::Nostr::Role::Signer> - Abstract signer role interface
=item L<Net::Nostr::Signer::OpenSSL> - OpenSSL backend implementation
=item L<Net::Nostr::Signer::Libsecp256k1> - libsecp256k1 backend implementation
=item L<Net::Nostr::Event> - Event representation and ID calculation
=item L<https://github.com/nostr-protocol/nips/blob/master/01.md> - NIP-01 specification
=item L<https://bips.xyz/340> - BIP-340 Schnorr Signatures

=head1 LICENSE

MIT

=end pod

unit class Net::Nostr::Signer;

use Net::Nostr::Role::Signer;
use Net::Nostr::Signer::OpenSSL;
use Net::Nostr::Signer::Libsecp256k1;

#| The backend signer instance
has Net::Nostr::Role::Signer $.backend is required;

#| Factory method to create a signer with the specified backend
method new(Str :$backend = 'OpenSSL') {
    my Net::Nostr::Role::Signer $signer-impl;

    given $backend.lc {
        when 'openssl' {
            $signer-impl = Net::Nostr::Signer::OpenSSL.new;
        }
        when 'libsecp256k1' | 'secp256k1' {
            $signer-impl = Net::Nostr::Signer::Libsecp256k1.new;
        }
        default {
            die "Unknown signer backend: $backend. Available backends: OpenSSL, Libsecp256k1";
        }
    }

    return self.bless(:backend($signer-impl));
}

#| Delegate signing to the backend
method sign(Str $id-hex, Str $privkey-hex --> Str) {
    return $!backend.sign($id-hex, $privkey-hex);
}
