=begin pod

=head1 NAME

Net::Nostr::Role::Signer - Abstract role for Nostr event signing

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Role::Signer;

# Create a class that implements the Signer role
class My::Custom::Signer does Net::Nostr::Role::Signer {
    method sign(Str $id-hex, Str $privkey-hex --> Str) {
        # Custom implementation here
        ...
    }
}
=end code

=head1 DESCRIPTION

Net::Nostr::Role::Signer defines the abstract interface for Nostr event signing.
All concrete signer implementations must implement this role.

This role enables a pluggable backend architecture, allowing different
cryptographic libraries or implementations to be used for signing Nostr events.

=head1 METHODS

=head2 sign

=begin code :lang<raku>
method sign(Str $id-hex, Str $privkey-hex --> Str)
=end code

Signs a 32-byte message hash (event ID) with a private key.

Parameters:
=item $id-hex - The event ID as a 64-character hex string
=item $privkey-hex - The private key as a 64-character hex string

Returns a 128-character hex string representing the signature.

This method must be implemented by all concrete signer classes.

=head1 AUTHOR

haruki7049

=head1 SEE ALSO

=item L<Net::Nostr::Signer> - Facade class for backend selection
=item L<Net::Nostr::Signer::OpenSSL> - OpenSSL backend implementation
=item L<Net::Nostr::Signer::Libsecp256k1> - libsecp256k1 backend implementation

=head1 LICENSE

MIT

=end pod

unit role Net::Nostr::Role::Signer;

#| Sign a 32-byte message hash with a private key
#| All concrete signers must implement this method
method sign(Str $id-hex, Str $privkey-hex --> Str) { ... }
