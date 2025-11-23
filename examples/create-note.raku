use v6.d;

use Net::Nostr::Event;
use Net::Nostr::Signer;

#| Generate a signed Nostr text note (Kind 1)
sub MAIN(
    Str $content = "Hello Nostr from Raku!", #| Content of the note (default: "Hello...")
    :$privkey where * ~~ /^ <[0..9a..f]> ** 64 $/ = "ce7a8c7348a127d1e31275d1527c985256260408f84635422844d32d69026144", #| Private key (Hex)
    :$pubkey  where * ~~ /^ <[0..9a..f]> ** 64 $/ = "f835d6d00f7797af40240748916f2c9e6df861608669072032df0389e26d8320"  #| Public key (Hex)
) {
    note "Creating event with content: '$content'";

    # 1. Create the Event Object
    my $event = Net::Nostr::Event.new(
        pubkey     => $pubkey,
        created_at => now.Int,
        kind       => 1, # Kind 1 = Text Note
        tags       => [],
        content    => $content,
    );

    # 2. Calculate Event ID (Hash)
    $event.id = $event.calculate-id();
    note "Event ID: $event.id()";

    # 3. Sign the Event
    note "Signing event...";
    my $signer = Net::Nostr::Signer.new;
    $event.sig = $signer.sign($event.id, $privkey);
    say ""; # Creates a line-break

    # 4. Output JSON
    # This JSON string is ready to be sent to a Relay via WebSocket
    say $event.to-json();
}
