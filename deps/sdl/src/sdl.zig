const std = @import("std");
const c = @import("c.zig");

// Type Aliases
pub const Window = c.SDL_Window;
pub const Renderer = c.SDL_Renderer;
pub const Surface = c.SDL_Surface;
pub const Texture = c.SDL_Texture;
pub const Rect = c.SDL_Rect;
pub const Event = c.SDL_Event;
pub const RendererFlip = c.SDL_RendererFlip;
pub const Color = c.SDL_Color;

// Function Forwards
pub const init = c.SDL_Init;
pub const quit = c.SDL_Quit;
pub const delay = c.SDL_Delay;
pub const getTicks = c.SDL_GetTicks;
pub const pollEvent = c.SDL_PollEvent;
pub const waitEvent = c.SDL_WaitEvent;
pub const waitEventTimeout = c.SDL_WaitEventTimeout;
pub const getKeyboardState = c.SDL_GetKeyboardState;
pub const destroyWindow = c.SDL_DestroyWindow;
pub const destroyRenderer = c.SDL_DestroyRenderer;
pub const renderCopyEx = c.SDL_RenderCopyEx;
pub const renderDrawRects = c.SDL_RenderDrawRects;
pub const renderSetLogicalSize = c.SDL_RenderSetLogicalSize;
pub const loadBmp = c.SDL_LoadBMP;
pub const freeSurface = c.SDL_FreeSurface;
pub const createTextureFromSurface = c.SDL_CreateTextureFromSurface;
pub const queryTexture = c.SDL_QueryTexture;

// Constant Forwards
pub const INIT_EVERYTHING = c.SDL_INIT_EVERYTHING;
pub const INIT_VIDEO = c.SDL_INIT_VIDEO;
pub const WINDOWPOS_CENTERED = c.SDL_WINDOWPOS_CENTERED;
pub const WINDOW_SHOWN = c.SDL_WINDOW_SHOWN;
pub const KEYDOWN = c.SDL_KEYDOWN;
pub const KEYUP = c.SDL_KEYUP;
pub const QUIT = c.SDL_QUIT;
pub const MOUSEBUTTONDOWN = c.SDL_MOUSEBUTTONDOWN;
pub const WINDOW_BORDERLESS = c.SDL_WINDOW_BORDERLESS;
pub const WINDOW_FULLSCREEN = c.SDL_WINDOW_FULLSCREEN;

// SDL Scan codes
pub const SCANCODE_DOWN = c.SDL_SCANCODE_DOWN;
pub const SCANCODE_UP = c.SDL_SCANCODE_UP;
pub const SCANCODE_LEFT = c.SDL_SCANCODE_LEFT;
pub const SCANCODE_RIGHT = c.SDL_SCANCODE_RIGHT;
pub const SCANCODE_1 = c.SDL_SCANCODE_1;
pub const SCANCODE_2 = c.SDL_SCANCODE_2;
pub const SCANCODE_3 = c.SDL_SCANCODE_3;
pub const SCANCODE_4 = c.SDL_SCANCODE_4;
pub const SCANCODE_5 = c.SDL_SCANCODE_5;
pub const SCANCODE_6 = c.SDL_SCANCODE_6;
pub const SCANCODE_7 = c.SDL_SCANCODE_7;
pub const SCANCODE_8 = c.SDL_SCANCODE_8;
pub const SCANCODE_9 = c.SDL_SCANCODE_9;
pub const SCANCODE_BACKSPACE = c.SDL_SCANCODE_BACKSPACE;
pub const SCANCODE_C = c.SDL_SCANCODE_C;
pub const SCANCODE_R = c.SDL_SCANCODE_R;
pub const SCANCODE_Z = c.SDL_SCANCODE_Z;
pub const SCANCODE_X = c.SDL_SCANCODE_X;

// Errors
const InitError = error{InitializationError};

const CreateError = error{
    WindowCreationError,
    RendererCreationError,
};

// Non-forwarding functions
pub fn getError() []const u8 {
    return "Hello there";
}

pub fn clearError() void {}

pub fn createWindow(
    window_name: []const u8,
    x_pos: i32,
    y_pos: i32,
    width: i32,
    height: i32,
    flags: var,
) !*Window {
    var opt_window: ?*Window = c.SDL_CreateWindow(
        window_name.ptr,
        x_pos,
        y_pos,
        width,
        height,
        makeFlags(flags),
    );
    if (opt_window) |window| {
        return window;
    }
    handleError("Error creating Window");
    return CreateError.WindowCreationError;
}

pub fn createRenderer(window: *Window, index: i32, flags: var) !*Renderer {
    var opt_render: ?*Renderer = c.SDL_CreateRenderer(
        window,
        index,
        makeFlags(flags),
    );
    if (opt_render) |render| {
        return render;
    }
    handleError("Error creating Renderer");
    return CreateError.RendererCreationError;
}

pub fn destroyTexture(texture: *Texture) void {
    c.SDL_DestroyTexture(texture);
}

pub fn handleError(function_str: []const u8) void {
    std.debug.warn(
        "{}: {}\n",
        .{ function_str, getError() },
    );
    clearError();
}

pub fn renderClear(renderer: *Renderer) !void {
    const result = c.SDL_RenderClear(renderer);
    if (result != 0) {
        handleError("Error clearing renderer");
        return error.RENDER_CLEAR_ERROR;
    }
}

pub fn setRenderDrawColor(renderer: *Renderer, color: Color) !void {
    const result = c.SDL_SetRenderDrawColor(
        renderer,
        color.r,
        color.g,
        color.b,
        color.a,
    );
    if (result != 0) {
        handleError("Error setting render draw color");
        return error.SET_RENDER_DRAW_COLOR_ERROR;
    }
}

pub fn renderCopy(renderer: *Renderer, texture: *Texture, source_rect: *const Rect, dest_rect: *const Rect) !void {
    const result = c.SDL_RenderCopy(renderer, texture, source_rect, dest_rect);
    if (result != 0) {
        handleError("Error copying texture");
        return error.RENDER_COPY_ERROR;
    }
}

pub fn renderPresent(renderer: *Renderer) void {
    c.SDL_RenderPresent(renderer);
}

pub fn renderDrawRect(renderer: *Renderer, rect: *const Rect) !void {
    const result = c.SDL_RenderDrawRect(renderer, rect);
    if (result != 0) {
        handleError("Error rendering rectangle");
        return error.RENDER_DRAW_RECT_ERROR;
    }
}

pub fn renderFillRect(renderer: *Renderer, rect: *const Rect) !void {
    const result = c.SDL_RenderFillRect(renderer, rect);
    if (result != 0) {
        handleError("Error rendering filled rectangle");
        return error.RENDER_FILL_RECT_ERROR;
    }
}

// Useful struct for setting color
//pub const Color = struct {
//    r: u8,
//    g: u8,
//    b: u8,
//    a: u8,
//};

pub const BLACK = Color{
    .r = 0,
    .g = 0,
    .b = 0,
    .a = 255,
};

pub const WHITE = Color{
    .r = 255,
    .g = 255,
    .b = 255,
    .a = 255,
};
pub const RED = Color{
    .r = 255,
    .g = 0,
    .b = 0,
    .a = 255,
};
pub const GREEN = Color{
    .r = 0,
    .g = 255,
    .b = 0,
    .a = 255,
};
pub const BLUE = Color{
    .r = 0,
    .g = 0,
    .b = 255,
    .a = 255,
};

// Helper functions

fn makeFlags(args: var) u32 {
    var flags: u32 = 0;
    inline for (args) |flag| {
        flags = flags | @as(u32, flag);
    }
    return flags;
}
