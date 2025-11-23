unit class Net::Nostr::Message;

use JSON::Fast;
use Net::Nostr::Event;

enum MsgType is export <EVENT REQ CLOSE>;

has MsgType $.type is required;
has Net::Nostr::Event $.event;
has Str $.subscription-id;
has Array $.filters;

# --- Factory Methods ---

#| Create an EVENT message
method new-event(Net::Nostr::Event $event) {
    return self.new(type => MsgType::EVENT, :$event);
}

#| Create a REQ message
method new-req(Str $sub-id, @filters) {
    return self.new(type => MsgType::REQ, subscription-id => $sub-id, filters => @filters);
}

#| Create a CLOSE message
method new-close(Str $sub-id) {
    return self.new(type => MsgType::CLOSE, subscription-id => $sub-id);
}

# --- Serialization ---

#| Serialize to JSON string for WebSocket transmission
method to-json() returns Str {
    given $!type {
        # NOTE: Add `MsgType::` to avoid conflicts with reserved words

        when MsgType::EVENT {
            # ["EVENT", <event_object>]
            return to-json(["EVENT", $!event.to-hash], :!pretty);
        }
        when MsgType::REQ {
            # ["REQ", <sub_id>, <filter1>, <filter2>, ...]
            return to-json(["REQ", $!subscription-id, |$!filters], :!pretty);
        }
        when MsgType::CLOSE {
            # ["CLOSE", <sub_id>]
            return to-json(["CLOSE", $!subscription-id], :!pretty);
        }
    }
}

#| Stringification overload (allows "say $msg" directly)
method Str() returns Str {
    return self.to-json();
}
