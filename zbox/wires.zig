pub const ArrowStyle = enum {
    none,
    forward,
    reverse,
    bidirectional,
    junction_begin,
    junction_end,
    junction_both,
};

pub const Options = struct {
    bits: usize = 1,
    dir: ArrowStyle = .none,
    class: ?[]const u8 = null,
};
