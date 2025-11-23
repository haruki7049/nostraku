use v6.d;

use Net::Nostr::Types;

#| Demonstrates the usage of Key type from Net::Nostr::Types
#| The Key type accepts both HexKey (64 hex chars) and Bech32Key formats

sub MAIN() {
    say "=== Net::Nostr::Types Key Demonstration ===";
    say "";

    # Example 1: HexKey format (64 lowercase hex characters)
    say "--- Example 1: HexKey Format ---";
    my HexKey $hex-key = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";
    say "Valid HexKey: $hex-key";
    say "Length: {$hex-key.chars} characters";
    say "";

    # Example 2: Bech32Key format (npub, nsec, etc.)
    say "--- Example 2: Bech32Key Format ---";
    my Bech32Key $bech32-key = "npub1l2vyh47mk2x0yd54r82frvx8v6u0jvwdkq3h9y4xew8t0p7znp5qx2r9yf";
    say "Valid Bech32Key: $bech32-key";
    say "Length: {$bech32-key.chars} characters";
    say "";

    # Example 3: Key type - Accepts both formats
    say "--- Example 3: Key Type (Flexible) ---";
    say "The Key type accepts both HexKey and Bech32Key formats:";
    say "";

    # Using Key with HexKey
    my Key $key1 = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";
    say "Key (from hex):     $key1";

    # Using Key with Bech32Key
    my Key $key2 = "npub1l2vyh47mk2x0yd54r82frvx8v6u0jvwdkq3h9y4xew8t0p7znp5qx2r9yf";
    say "Key (from bech32):  $key2";
    say "";

    # Example 4: Validation demonstration
    say "--- Example 4: Key Validation ---";
    say "The Key type validates input automatically:";
    say "";

    # Valid hex key
    my $valid-hex = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320";
    if $valid-hex ~~ Key {
        say "✓ '$valid-hex' is a valid Key (HexKey)";
    }

    # Valid bech32 key
    my $valid-bech32 = "npub1l2vyh47mk2x0yd54r82frvx8v6u0jvwdkq3h9y4xew8t0p7znp5qx2r9yf";
    if $valid-bech32 ~~ Key {
        say "✓ '$valid-bech32' is a valid Key (Bech32Key)";
    }
    say "";

    # Invalid keys - too short
    my $too-short = "f835d6d00f7797af";
    say "Testing invalid key (too short): '$too-short'";
    if $too-short !~~ Key {
        say "✗ Correctly rejected: key is too short";
    }
    say "";

    # Invalid keys - contains uppercase
    my $has-uppercase = "F835D6D00F7797AF40240748916F2C9E6DF861608669072032DF0389E26D8320";
    say "Testing invalid key (uppercase): '$has-uppercase'";
    if $has-uppercase !~~ Key {
        say "✗ Correctly rejected: HexKey must be lowercase";
    }
    say "";

    # Invalid keys - wrong length
    my $wrong-length = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d832012";
    say "Testing invalid key (66 chars): '$wrong-length'";
    if $wrong-length !~~ Key {
        say "✗ Correctly rejected: HexKey must be exactly 64 characters";
    }
    say "";

    # Example 5: Using Key in function signatures
    say "--- Example 5: Using Key in Function Signatures ---";
    say "";

    # Define a function that accepts a Key
    sub display-key-info(Key $key) {
        say "Key provided: $key";

        # Determine the key type
        if $key ~~ HexKey {
            say "  Type: HexKey (64 hex characters)";
            say "  Format: Raw hexadecimal";
        } elsif $key ~~ Bech32Key {
            say "  Type: Bech32Key";
            say "  Format: Bech32-encoded";
            
            # Extract prefix from Bech32 key
            if $key ~~ /^ (<[a..z]>+) '1' / {
                my $prefix = ~$0;
                say "  Prefix: $prefix";
                
                given $prefix {
                    when "npub" { say "  Purpose: Public key" }
                    when "nsec" { say "  Purpose: Secret/Private key" }
                    when "note" { say "  Purpose: Note/Event ID" }
                    default     { say "  Purpose: Other" }
                }
            }
        }
        say "";
    }

    # Call with different key types
    display-key-info("f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320");
    display-key-info("npub1l2vyh47mk2x0yd54r82frvx8v6u0jvwdkq3h9y4xew8t0p7znp5qx2r9yf");
    display-key-info("nsec1em36c3e53g78rs73yt74yfy6s5tzvpqguv34y9ygy6fdx5gzvz2q7ajp5d");

    # Example 6: Practical use case
    say "--- Example 6: Practical Use Case ---";
    say "Key type is useful when accepting user input that could be in either format:";
    say "";

    sub process-user-key(Key $user-key) {
        say "Processing key: $user-key";
        
        # In a real application, you might:
        # - Store the key in a database
        # - Use it to verify signatures
        # - Convert between formats
        # - Display it to the user in their preferred format
        
        if $user-key ~~ HexKey {
            say "  → Accepted as HexKey";
        } elsif $user-key ~~ Bech32Key {
            say "  → Accepted as Bech32Key";
        }
    }

    # Simulate user input in different formats
    process-user-key("f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320");
    say "";

    say "=== Demonstration Complete ===";
    say "";
    say "Key Takeaways:";
    say "  • Key type provides flexible validation for both hex and bech32 formats";
    say "  • HexKey must be exactly 64 lowercase hex characters";
    say "  • Bech32Key follows the pattern: prefix + '1' + alphanumeric chars";
    say "  • Use Key type in function signatures for maximum flexibility";
    say "  • Type validation happens automatically at assignment";
}
