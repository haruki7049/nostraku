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
the OpenSSL library for cryptographic operations on the secp256k1 elliptic curve.

The Nostr protocol requires BIP-340 Schnorr signatures over the secp256k1 curve as
specified in NIP-01. This module provides a simple interface to generate these
signatures from event IDs and private keys.

B<SECURITY NOTE>: Private keys should be handled with extreme care. Never
hardcode them in your source code or commit them to version control.

=head1 REQUIREMENTS

This module requires the OpenSSL library (libcrypto) to be installed on your system.

On Debian/Ubuntu:
=begin code :lang<bash>
sudo apt-get install libssl-dev
=end code

On macOS with Homebrew:
=begin code :lang<bash>
brew install openssl
=end code

On NixOS (using the provided flake.nix):
=begin code :lang<bash>
nix develop
=end code

=head1 ATTRIBUTES

=head2 $!ec-group

Internal attribute storing the secp256k1 EC_GROUP pointer.
Automatically initialized in the BUILD submethod.

=head1 METHODS

=head2 new

=begin code :lang<raku>
method new()
=end code

Creates a new signer instance and initializes the secp256k1 EC group.

=head2 hex-to-blob

=begin code :lang<raku>
method hex-to-blob(Str $hex --> Blob)
=end code

Converts a hexadecimal string to a Blob for use with native functions.

Parameters:
=item $hex - Hexadecimal string (should have even length)

Returns a Blob containing the binary representation.

=head2 sign

=begin code :lang<raku>
method sign(Str $id-hex, Str $privkey-hex --> Str)
=end code

Signs a 32-byte message hash (event ID) with a private key using BIP-340 Schnorr signature.

Parameters:
=item $id-hex - The event ID as a 64-character hex string
=item $privkey-hex - The private key as a 64-character hex string

Returns a 128-character hex string representing the Schnorr signature.

The method performs the following steps:
=item 1. Converts hex inputs to byte arrays
=item 2. Computes the x-only public key from the private key
=item 3. Generates auxiliary randomness
=item 4. Computes tagged hash for the nonce
=item 5. Computes the BIP-340 Schnorr signature
=item 6. Returns the signature as a hex string

Dies with an error message if signing fails.

=head1 NATIVE FUNCTIONS

This module uses NativeCall to interface with OpenSSL's libcrypto. The following
native functions are bound for elliptic curve operations on secp256k1.

=head1 ERROR HANDLING

The C<sign> method will die with an error message if:
=item The key operations fail
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
=item L<OpenSSL> - OpenSSL Raku module
=item L<https://github.com/nostr-protocol/nips/blob/master/01.md> - NIP-01 specification
=item L<https://bips.xyz/340> - BIP-340 Schnorr Signatures

=head1 LICENSE

MIT

=end pod

unit class Net::Nostr::Signer;

use NativeCall;
use OpenSSL::NativeLib;
use OpenSSL::Digest;

# --- Constants ---

# secp256k1 curve NID
constant NID_secp256k1 = 714;

# Point conversion form for uncompressed points
constant POINT_CONVERSION_UNCOMPRESSED = 4;

# secp256k1 curve order (n) as hex
constant SECP256K1_ORDER_HEX = 'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141';

# --- NativeCall Bindings for OpenSSL libcrypto ---

sub EC_GROUP_new_by_curve_name(int32 $nid)
    returns Pointer
    is native(&crypto-lib) { * }

sub EC_GROUP_free(Pointer $group)
    is native(&crypto-lib) { * }

sub EC_POINT_new(Pointer $group)
    returns Pointer
    is native(&crypto-lib) { * }

sub EC_POINT_free(Pointer $point)
    is native(&crypto-lib) { * }

sub EC_POINT_mul(Pointer $group, Pointer $r, Pointer $n, Pointer $q, Pointer $m, Pointer $ctx)
    returns int32
    is native(&crypto-lib) { * }

sub EC_POINT_get_affine_coordinates(Pointer $group, Pointer $p, Pointer $x, Pointer $y, Pointer $ctx)
    returns int32
    is native(&crypto-lib) { * }

sub BN_new()
    returns Pointer
    is native(&crypto-lib) { * }

sub BN_free(Pointer $bn)
    is native(&crypto-lib) { * }

sub BN_CTX_new()
    returns Pointer
    is native(&crypto-lib) { * }

sub BN_CTX_free(Pointer $ctx)
    is native(&crypto-lib) { * }

sub BN_bin2bn(Blob $s, int32 $len, Pointer $ret)
    returns Pointer
    is native(&crypto-lib) { * }

sub BN_bn2binpad(Pointer $a, Blob $to, int32 $tolen)
    returns int32
    is native(&crypto-lib) { * }

sub BN_mod_add(Pointer $r, Pointer $a, Pointer $b, Pointer $m, Pointer $ctx)
    returns int32
    is native(&crypto-lib) { * }

sub BN_mod_mul(Pointer $r, Pointer $a, Pointer $b, Pointer $m, Pointer $ctx)
    returns int32
    is native(&crypto-lib) { * }

sub BN_mod_sub(Pointer $r, Pointer $a, Pointer $b, Pointer $m, Pointer $ctx)
    returns int32
    is native(&crypto-lib) { * }

sub BN_is_odd(Pointer $a)
    returns int32
    is native(&crypto-lib) { * }

sub BN_copy(Pointer $a, Pointer $b)
    returns Pointer
    is native(&crypto-lib) { * }

sub BN_hex2bn(CArray[Pointer] $a, Str $str)
    returns int32
    is native(&crypto-lib) { * }

sub RAND_bytes(Blob $buf, int32 $num)
    returns int32
    is native(&crypto-lib) { * }

# --- Class Logic ---

has Pointer $!ec-group;
has Pointer $!bn-ctx;
has Pointer $!curve-order;

submethod BUILD {
    $!ec-group = EC_GROUP_new_by_curve_name(NID_secp256k1);
    die "Failed to create EC group for secp256k1" unless $!ec-group;

    $!bn-ctx = BN_CTX_new();
    die "Failed to create BN context" unless $!bn-ctx;

    # Parse curve order
    my $order-ptr = CArray[Pointer].new;
    $order-ptr[0] = Pointer;
    BN_hex2bn($order-ptr, SECP256K1_ORDER_HEX);
    $!curve-order = $order-ptr[0];
    die "Failed to parse curve order" unless $!curve-order;
}

submethod DESTROY {
    BN_free($!curve-order) if $!curve-order;
    BN_CTX_free($!bn-ctx) if $!bn-ctx;
    EC_GROUP_free($!ec-group) if $!ec-group;
}

#| Convert Hex string to Blob
method hex-to-blob(Str $hex --> Blob) {
    Blob.new: $hex.comb(2).map(*.parse-base(16));
}

#| Convert Blob to hex string
method blob-to-hex(Blob $blob --> Str) {
    $blob.list.fmt('%02x', '');
}

#| Compute BIP-340 tagged hash: SHA256(SHA256(tag) || SHA256(tag) || data)
method tagged-hash(Str $tag, Blob $data --> Blob) {
    my $tag-hash = sha256($tag.encode);
    my $preimage = Blob.new(|$tag-hash.list, |$tag-hash.list, |$data.list);
    sha256($preimage);
}

#| Get x-only public key from private key (returns 32-byte Blob and parity)
method get-xonly-pubkey(Blob $privkey --> List) {
    my $priv-bn = BN_new();
    BN_bin2bn($privkey, 32, $priv-bn);

    my $pubkey-point = EC_POINT_new($!ec-group);
    EC_POINT_mul($!ec-group, $pubkey-point, $priv-bn, Pointer, Pointer, $!bn-ctx);

    my $x = BN_new();
    my $y = BN_new();
    EC_POINT_get_affine_coordinates($!ec-group, $pubkey-point, $x, $y, $!bn-ctx);

    my $x-blob = Blob.allocate(32);
    BN_bn2binpad($x, $x-blob, 32);

    my $y-is-odd = BN_is_odd($y);

    BN_free($y);
    BN_free($x);
    EC_POINT_free($pubkey-point);
    BN_free($priv-bn);

    ($x-blob, $y-is-odd);
}

#| Negate private key modulo curve order
method negate-privkey(Blob $privkey --> Blob) {
    my $priv-bn = BN_new();
    BN_bin2bn($privkey, 32, $priv-bn);

    my $neg-bn = BN_new();
    BN_mod_sub($neg-bn, $!curve-order, $priv-bn, $!curve-order, $!bn-ctx);

    my $result = Blob.allocate(32);
    BN_bn2binpad($neg-bn, $result, 32);

    BN_free($neg-bn);
    BN_free($priv-bn);

    $result;
}

#| Compute R point for Schnorr signature
method compute-r-point(Blob $k --> List) {
    my $k-bn = BN_new();
    BN_bin2bn($k, 32, $k-bn);

    my $r-point = EC_POINT_new($!ec-group);
    EC_POINT_mul($!ec-group, $r-point, $k-bn, Pointer, Pointer, $!bn-ctx);

    my $rx = BN_new();
    my $ry = BN_new();
    EC_POINT_get_affine_coordinates($!ec-group, $r-point, $rx, $ry, $!bn-ctx);

    my $rx-blob = Blob.allocate(32);
    BN_bn2binpad($rx, $rx-blob, 32);

    my $ry-is-odd = BN_is_odd($ry);

    BN_free($ry);
    BN_free($rx);
    EC_POINT_free($r-point);
    BN_free($k-bn);

    ($rx-blob, $ry-is-odd);
}

#| Sign a 32-byte message hash with a private key using BIP-340 Schnorr
method sign(Str $id-hex, Str $privkey-hex --> Str) {
    my $msg = self.hex-to-blob($id-hex);
    my $privkey = self.hex-to-blob($privkey-hex);

    # 1. Get x-only public key
    my ($pubkey-x, $y-is-odd) = self.get-xonly-pubkey($privkey);

    # 2. If y is odd, negate the private key (BIP-340 requirement)
    my $d = $y-is-odd ?? self.negate-privkey($privkey) !! $privkey;

    # 3. Generate auxiliary randomness
    my $aux-rand = Blob.allocate(32);
    RAND_bytes($aux-rand, 32);

    # 4. Compute t = d XOR tagged_hash("BIP0340/aux", aux_rand)
    my $aux-hash = self.tagged-hash("BIP0340/aux", $aux-rand);
    my $t = Blob.new: (^32).map: { $d[$_] +^ $aux-hash[$_] };

    # 5. Compute k' = tagged_hash("BIP0340/nonce", t || pubkey_x || msg)
    my $nonce-input = Blob.new(|$t.list, |$pubkey-x.list, |$msg.list);
    my $k-prime-hash = self.tagged-hash("BIP0340/nonce", $nonce-input);

    # 6. k' mod n (curve order)
    my $k-prime-bn = BN_new();
    BN_bin2bn($k-prime-hash, 32, $k-prime-bn);

    my $k-bn = BN_new();
    my $zero-bn = BN_new();
    BN_mod_add($k-bn, $k-prime-bn, $zero-bn, $!curve-order, $!bn-ctx);

    my $k-blob = Blob.allocate(32);
    BN_bn2binpad($k-bn, $k-blob, 32);

    BN_free($zero-bn);
    BN_free($k-prime-bn);
    BN_free($k-bn);

    # Check k != 0
    die "Failed to sign: k is zero" if $k-blob.list.all == 0;

    # 7. Compute R = k * G
    my ($r-x, $r-y-is-odd) = self.compute-r-point($k-blob);

    # 8. If R.y is odd, negate k
    my $k = $r-y-is-odd ?? self.negate-privkey($k-blob) !! $k-blob;

    # 9. Compute e = tagged_hash("BIP0340/challenge", R.x || pubkey_x || msg) mod n
    my $challenge-input = Blob.new(|$r-x.list, |$pubkey-x.list, |$msg.list);
    my $e-hash = self.tagged-hash("BIP0340/challenge", $challenge-input);

    my $e-bn = BN_new();
    BN_bin2bn($e-hash, 32, $e-bn);

    my $e-mod-bn = BN_new();
    my $zero2-bn = BN_new();
    BN_mod_add($e-mod-bn, $e-bn, $zero2-bn, $!curve-order, $!bn-ctx);

    BN_free($zero2-bn);
    BN_free($e-bn);

    # 10. Compute s = (k + e * d) mod n
    my $d-bn = BN_new();
    BN_bin2bn($d, 32, $d-bn);

    my $k-final-bn = BN_new();
    BN_bin2bn($k, 32, $k-final-bn);

    my $ed-bn = BN_new();
    BN_mod_mul($ed-bn, $e-mod-bn, $d-bn, $!curve-order, $!bn-ctx);

    my $s-bn = BN_new();
    BN_mod_add($s-bn, $k-final-bn, $ed-bn, $!curve-order, $!bn-ctx);

    my $s-blob = Blob.allocate(32);
    BN_bn2binpad($s-bn, $s-blob, 32);

    BN_free($s-bn);
    BN_free($ed-bn);
    BN_free($k-final-bn);
    BN_free($d-bn);
    BN_free($e-mod-bn);

    # 11. Return signature (R.x || s)
    my $sig = Blob.new(|$r-x.list, |$s-blob.list);
    self.blob-to-hex($sig);
}
