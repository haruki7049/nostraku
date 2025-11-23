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
    my $blob = Blob.from-hex($hex);
    my $arr = CArray[uint8].new;
    for $blob.list -> $byte { $arr.push: $byte }
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
