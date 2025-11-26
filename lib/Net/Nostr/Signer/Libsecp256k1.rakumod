=begin pod

=head1 NAME

Net::Nostr::Signer::Libsecp256k1 - libsecp256k1 backend for Nostr event signing

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Signer;

# Use libsecp256k1 backend
my $signer = Net::Nostr::Signer.new(backend => 'Libsecp256k1');
my $sig = $signer.sign($event-id-hex, $privkey-hex);
=end code

=head1 DESCRIPTION

Net::Nostr::Signer::Libsecp256k1 provides Schnorr signature generation for Nostr events
using the libsecp256k1 library, which is the Bitcoin Core's native implementation
of secp256k1 elliptic curve cryptography.

The Nostr protocol requires BIP-340 Schnorr signatures over the secp256k1 curve as
specified in NIP-01. libsecp256k1 provides native BIP-340 Schnorr signature support,
making this backend more efficient and straightforward than OpenSSL-based implementations.

B<SECURITY NOTE>: Private keys should be handled with extreme care. Never
hardcode them in your source code or commit them to version control.

=head1 REQUIREMENTS

This module requires the libsecp256k1 library to be installed on your system.

On Debian/Ubuntu:
=begin code :lang<bash>
sudo apt-get install libsecp256k1-dev
=end code

On macOS with Homebrew:
=begin code :lang<bash>
brew install libsecp256k1
=end code

On NixOS (using flake.nix):
=begin code :lang<bash>
nix develop
=end code

=head1 METHODS

=head2 new

Creates a new libsecp256k1 signer instance and initializes the secp256k1 context.

=head2 sign

Signs a 32-byte message hash (event ID) with a private key using BIP-340 Schnorr signature.

=head1 AUTHOR

haruki7049

=head1 SEE ALSO

=item L<Net::Nostr::Role::Signer> - Abstract signer role
=item L<Net::Nostr::Signer> - Facade class for backend selection
=item L<Net::Nostr::Signer::OpenSSL> - OpenSSL backend implementation
=item L<https://github.com/bitcoin-core/secp256k1> - libsecp256k1 library

=head1 LICENSE

MIT

=end pod

unit class Net::Nostr::Signer::Libsecp256k1;

use Net::Nostr::Role::Signer;
use NativeCall;

also does Net::Nostr::Role::Signer;

# --- Constants ---

#| Library name (matches libsecp256k1.so or .dylib)
constant LIB = 'secp256k1';

#| Context flag for no precomputation (minimal context)
constant SECP256K1_CONTEXT_NONE = 1;

# --- NativeCall Bindings for libsecp256k1 ---

#| Create a secp256k1 context for cryptographic operations
sub secp256k1_context_create(int32 $flags)
    returns Pointer
    is native(LIB) { * }

#| Destroy a secp256k1 context
sub secp256k1_context_destroy(Pointer $ctx)
    is native(LIB) { * }

#| Create a keypair from a 32-byte secret key
sub secp256k1_keypair_create(
    Pointer $ctx,
    CArray[uint8] $keypair_out,
    CArray[uint8] $seckey
) returns int32 is native(LIB) { * }

#| Generate a BIP-340 Schnorr signature for a 32-byte message
sub secp256k1_schnorrsig_sign32(
    Pointer $ctx,
    CArray[uint8] $sig64_out,
    CArray[uint8] $msg32,
    CArray[uint8] $keypair,
    CArray[uint8] $aux_rand32
) returns int32 is native(LIB) { * }

# --- Class Logic ---

#| Secp256k1 context pointer
has Pointer $!ctx;

submethod BUILD {
    $!ctx = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
    die "Failed to create secp256k1 context" unless $!ctx;
}

submethod DESTROY {
    secp256k1_context_destroy($!ctx) if $!ctx;
}

#| Convert hex string to CArray[uint8]
method hex-to-carray(Str $hex --> CArray[uint8]) {
    my $blob = Blob.new: $hex.comb(2).map(*.parse-base(16));
    my $arr = CArray[uint8].new;

    my $i = 0;
    for $blob.list -> $byte {
        $arr[$i] = $byte;
        $i += 1;
    }

    return $arr;
}

#| Sign a 32-byte message hash with a private key using BIP-340 Schnorr
method sign(Str $id-hex, Str $privkey-hex --> Str) {
    # 1. Prepare buffers
    my $seckey-arr = self.hex-to-carray($privkey-hex);
    my $msg-arr    = self.hex-to-carray($id-hex);

    # Keypair buffer (96 bytes for secp256k1 keypair)
    my $keypair-arr = CArray[uint8].new;
    $keypair-arr[$_] = 0 for ^96;

    # Signature buffer (64 bytes)
    my $sig-arr = CArray[uint8].new;
    $sig-arr[$_] = 0 for ^64;

    # 2. Create Keypair from secret key
    my $res-kp = secp256k1_keypair_create($!ctx, $keypair-arr, $seckey-arr);
    die "Failed to create keypair" unless $res-kp == 1;

    # 3. Sign using BIP-340 Schnorr (with NULL aux_rand for deterministic signing)
    my $res-sign = secp256k1_schnorrsig_sign32(
        $!ctx,
        $sig-arr,
        $msg-arr,
        $keypair-arr,
        CArray[uint8]  # NULL for auxiliary randomness
    );
    die "Failed to sign" unless $res-sign == 1;

    # 4. Convert signature to hex string
    return Blob.new( ($sig-arr[$_] for ^64) ).list.fmt('%02x', '');
}
