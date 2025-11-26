=begin pod

=head1 NAME

Net::Nostr::Signer::OpenSSL - OpenSSL backend for Nostr event signing

=head1 SYNOPSIS

=begin code :lang<raku>
use Net::Nostr::Signer::OpenSSL;

# Direct usage (not recommended - use Net::Nostr::Signer facade instead)
my $signer = Net::Nostr::Signer::OpenSSL.new;
my $sig = $signer.sign($event-id-hex, $privkey-hex);
=end code

=head1 DESCRIPTION

Net::Nostr::Signer::OpenSSL provides Schnorr signature generation for Nostr events
using the OpenSSL library for cryptographic operations on the secp256k1 elliptic curve.

The Nostr protocol requires BIP-340 Schnorr signatures over the secp256k1 curve as
specified in NIP-01. This module implements these signatures using OpenSSL's libcrypto.

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

=head1 METHODS

=head2 new

Creates a new OpenSSL signer instance and initializes the secp256k1 EC group.

=head2 sign

Signs a 32-byte message hash (event ID) with a private key using BIP-340 Schnorr signature.

=head1 AUTHOR

haruki7049

=head1 SEE ALSO

=item L<Net::Nostr::Role::Signer> - Abstract signer role
=item L<Net::Nostr::Signer> - Facade class for backend selection

=head1 LICENSE

MIT

=end pod

unit class Net::Nostr::Signer::OpenSSL;

use Net::Nostr::Role::Signer;
use NativeCall;
use OpenSSL::NativeLib;
use OpenSSL::Digest;

also does Net::Nostr::Role::Signer;

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

    # Parse curve order - BN_hex2bn expects a pointer to pointer for output
    my $order-ptr = CArray[Pointer].new;
    $order-ptr[0] = Pointer;  # Initialize as null pointer
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

#| Reduce a BIGNUM modulo curve order and return as Blob
#| BN_mod_add(r, a, 0, n) computes r = a mod n (using 0 as addend)
method bn-mod-reduce(Pointer $bn --> Blob) {
    my $reduced-bn = BN_new();
    my $addend-bn = BN_new();  # Initialized to 0 by BN_new
    BN_mod_add($reduced-bn, $bn, $addend-bn, $!curve-order, $!bn-ctx);

    my $result = Blob.allocate(32);
    BN_bn2binpad($reduced-bn, $result, 32);

    BN_free($addend-bn);
    BN_free($reduced-bn);

    $result;
}

#| Check if a Blob is all zeros
method is-zero-blob(Blob $blob --> Bool) {
    for $blob.list -> $byte {
        return False if $byte != 0;
    }
    True;
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

    # 6. k' mod n (curve order) - using helper method
    my $k-prime-bn = BN_new();
    BN_bin2bn($k-prime-hash, 32, $k-prime-bn);
    my $k-blob = self.bn-mod-reduce($k-prime-bn);
    BN_free($k-prime-bn);

    # Check k != 0
    die "Failed to sign: k is zero" if self.is-zero-blob($k-blob);

    # 7. Compute R = k * G
    my ($r-x, $r-y-is-odd) = self.compute-r-point($k-blob);

    # 8. If R.y is odd, negate k
    my $k = $r-y-is-odd ?? self.negate-privkey($k-blob) !! $k-blob;

    # 9. Compute e = tagged_hash("BIP0340/challenge", R.x || pubkey_x || msg) mod n
    my $challenge-input = Blob.new(|$r-x.list, |$pubkey-x.list, |$msg.list);
    my $e-hash = self.tagged-hash("BIP0340/challenge", $challenge-input);

    my $e-bn = BN_new();
    BN_bin2bn($e-hash, 32, $e-bn);
    my $e-blob = self.bn-mod-reduce($e-bn);
    BN_free($e-bn);

    # 10. Compute s = (k + e * d) mod n
    my $d-bn = BN_new();
    BN_bin2bn($d, 32, $d-bn);

    my $k-final-bn = BN_new();
    BN_bin2bn($k, 32, $k-final-bn);

    my $e-mod-bn = BN_new();
    BN_bin2bn($e-blob, 32, $e-mod-bn);

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
