=begin pod

=head1 NAME

Net::Nostr::Signer - Schnorr signature generation for Nostr events

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Signer;
use Net::Nostr::Event;

# Create a signer instance
my $signer = Net::Nostr::Signer.new;

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

Net::Nostr::Signer provides Schnorr signature generation for Nostr events using
the secp256k1 elliptic curve library via NativeCall bindings.

The Nostr protocol requires Schnorr signatures over the secp256k1 curve as
specified in NIP-01. This module provides a simple interface to generate these
signatures from event IDs and private keys.

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

On NixOS (using the provided flake.nix):
=begin code :lang<bash>
nix develop
=end code

=head1 ATTRIBUTES

=head2 $!ctx

Internal attribute storing the secp256k1 context pointer.
Automatically initialized in the BUILD submethod.

=head1 METHODS

=head2 new

=begin code :lang<raku>
method new()
=end code

Creates a new signer instance and initializes the secp256k1 context.
The context is created with SECP256K1_CONTEXT_NONE flag.

=head2 hex-to-carray

=begin code :lang<raku>
method hex-to-carray(Str $hex --> CArray[uint8])
=end code

Converts a hexadecimal string to a CArray[uint8] for use with native functions.

Parameters:
=item $hex - Hexadecimal string (should have even length)

Returns a CArray[uint8] containing the binary representation.

This is an internal utility method used to convert hex-encoded keys and
event IDs into the byte arrays required by the secp256k1 library.

=head2 sign

=begin code :lang<raku>
method sign(Str $id-hex, Str $privkey-hex --> Str)
=end code

Signs a 32-byte message hash (event ID) with a private key using Schnorr signature.

Parameters:
=item $id-hex - The event ID as a 64-character hex string
=item $privkey-hex - The private key as a 64-character hex string

Returns a 128-character hex string representing the Schnorr signature.

The method performs the following steps:
=item 1. Converts hex inputs to byte arrays
=item 2. Creates a keypair from the private key
=item 3. Generates a Schnorr signature over the message
=item 4. Returns the signature as a hex string

Dies with an error message if keypair creation or signing fails.

=head1 NATIVE FUNCTIONS

This module uses NativeCall to interface with libsecp256k1. The following
native functions are bound:

=head2 secp256k1_context_create

Creates a secp256k1 context for cryptographic operations.

=head2 secp256k1_keypair_create

Creates a keypair from a 32-byte secret key.

=head2 secp256k1_schnorrsig_sign32

Generates a Schnorr signature for a 32-byte message.

=head1 ERROR HANDLING

The C<sign> method will die with an error message if:
=item The keypair creation fails (invalid private key)
=item The signature generation fails

Ensure your private keys are valid 32-byte hex strings.

=head1 SECURITY CONSIDERATIONS

=item Never expose private keys in logs or error messages
=item Store private keys securely (encrypted storage, hardware wallets, etc.)
=item Use secure random number generators when creating private keys
=item Consider using environment variables or secure vaults for key management

=head1 AUTHOR

haruki7049

=head1 SEE ALSO

=item L<Net::Nostr::Event> - Event representation and ID calculation
=item L<Net::Nostr::Types> - Type definitions including HexKey and HexSignature
=item L<https://github.com/bitcoin-core/secp256k1> - secp256k1 library
=item L<https://github.com/nostr-protocol/nips/blob/master/01.md> - NIP-01 specification

=head1 LICENSE

MIT

=end pod

unit class Net::Nostr::Signer;

use NativeCall;

#| Library name (matches libsecp256k1.so or .dylib)
constant LIB = 'secp256k1';

constant SECP256K1_CONTEXT_NONE = 1;

# --- NativeCall Bindings ---

sub secp256k1_context_create(int32)
    returns Pointer
    is native(LIB) { * }

sub secp256k1_keypair_create(
    Pointer $ctx,
    CArray[uint8] $keypair_out,
    CArray[uint8] $seckey
) returns int32 is native(LIB) { * }

sub secp256k1_schnorrsig_sign32(
    Pointer $ctx,
    CArray[uint8] $sig64_out,
    CArray[uint8] $msg32,
    CArray[uint8] $keypair,
    CArray[uint8] $aux_rand32
) returns int32 is native(LIB) { * }


# --- Class Logic ---

has Pointer $!ctx;

submethod BUILD {
    $!ctx = secp256k1_context_create(SECP256K1_CONTEXT_NONE);
}

#| Convert Hex string to CArray[uint8]
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

#| Sign a 32-byte message hash with a private key
method sign(Str $id-hex, Str $privkey-hex --> Str) {
    # 1. Prepare buffers
    my $seckey-arr = self.hex-to-carray($privkey-hex);
    my $msg-arr    = self.hex-to-carray($id-hex);

    my $keypair-arr = CArray[uint8].new;
    $keypair-arr[$_] = 0 for ^96;

    my $sig-arr = CArray[uint8].new;
    $sig-arr[$_] = 0 for ^64;

    # 2. Create Keypair
    my $res-kp = secp256k1_keypair_create($!ctx, $keypair-arr, $seckey-arr);
    die "Failed to create keypair" unless $res-kp == 1;

    # 3. Sign (Schnorr)
    my $res-sign = secp256k1_schnorrsig_sign32(
        $!ctx,
        $sig-arr,
        $msg-arr,
        $keypair-arr,
        CArray[uint8] # NULL
    );
    die "Failed to sign" unless $res-sign == 1;

    # 4. Return Hex
    return Blob.new( ($sig-arr[$_] for ^64) ).list.fmt('%02x', '');
}
