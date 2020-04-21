const std = @import("std");
const c = @import("./c.zig");

// Function forwards
pub const init = c.IMG_Init;
pub const quit = c.IMG_Quit;
pub const load = c.IMG_Load;
pub const getError = c.IMG_GetError;

// Forward values
pub const INIT_JPG = c.IMG_INIT_JPG;
pub const INIT_PNG = c.IMG_INIT_PNG;

pub fn handleError(function_str: []const u8) void {
    std.debug.warn(
        "{}: {}\n",
        .{ function_str, getError() },
    );
}