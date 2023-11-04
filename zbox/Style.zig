base_css: []const u8 = @embedFile("default.css"),
extra_css: []const u8 = "",

drawing_padding_x: f64 = 25,
drawing_padding_y: f64 = 25,

box_padding_x: f64 = 8,
box_padding_y: f64 = 10,
box_label_line_height: f64 = 25,

default_interface_spacing: f64 = 20,

separator_label_padding_x: f64 = 8,
separator_label_padding_y: f64 = 4,

wire_style: WireStyle = .{
    .label_padding_x = 8,
    .label_padding_y = 3,
    .label_padding_cap = 5,
    .default_length = 100,
    .default_corner_radius = 5,
    .arrow_length = 10,
    .arrow_width = 5,
    .junction_radius = 4,
    .bit_mark_length = 6,
    .bit_mark_label_offset_x = 5,
    .bit_mark_label_offset_xy = 1,
    .bit_mark_label_offset_y = 5,
},
bus_style: WireStyle = .{
    .label_padding_x = 8,
    .label_padding_y = 4,
    .label_padding_cap = 5,
    .default_length = 100,
    .default_corner_radius = 5,
    .arrow_length = 12,
    .arrow_width = 8,
    .junction_radius = 6,
    .bit_mark_length = 10,
    .bit_mark_label_offset_x = 6,
    .bit_mark_label_offset_xy = 1.5,
    .bit_mark_label_offset_y = 7,
},

pub const WireStyle = struct {
    label_padding_x: f64,
    label_padding_y: f64,
    label_padding_cap: f64,
    default_length: f64,
    default_corner_radius: f64, // TODO rounded corners on wires
    arrow_length: f64,
    arrow_width: f64,
    junction_radius: f64,
    bit_mark_length: f64,
    bit_mark_label_offset_x: f64,
    bit_mark_label_offset_xy: f64,
    bit_mark_label_offset_y: f64,
};
