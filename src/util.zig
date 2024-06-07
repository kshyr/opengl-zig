const std = @import("std");

pub fn cStringToSlice(cstr: [*c]const u8) []const u8 {
    const length = std.mem.len(cstr);
    return cstr[0..length];
}
