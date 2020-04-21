const std = @import("std");
const sdl_libraries = @import("sdl");
const sdl = sdl_libraries.sdl;
const sdl_img = sdl_libraries.sdl_img;

const Allocator = std.mem.Allocator;

const grey_boarder = sdl.Color{
    .r = 66,
    .g = 65,
    .b = 65,
    .a = 210,
};

const selected_color = sdl.Color{
    .r = 233,
    .g = 212,
    .b = 18,
    .a = 255,
};

pub fn main() !void {
    try initSdl();
    defer deinitSdl();

    // the only thing that allocates (other than SDL in libc) is an ArrayList
    // which won't get above 81 elements
    var memory = [_]u8{undefined} ** (1024);
    var fb_alloc = std.heap.FixedBufferAllocator.init(memory[0..]);
    const alloc = &fb_alloc.allocator;

    var world = try WorldData.init(alloc);
    defer world.deinit();

    var keyboardActions = makeKeyMap();

    var e: sdl.Event = undefined;
    while (true) {
        if (sdl.waitEvent(&e) != 0) {
            switch (e.@"type") {
                sdl.QUIT => {
                    break;
                },
                sdl.KEYDOWN => {
                    const idx = @intCast(usize, @enumToInt(e.key.keysym.scancode));
                    keyboardActions[idx].call(&world);
                    try world.render();
                },
                else => {},
            }
        }
    }
}

fn initSdl() !void {
    if (sdl.init(sdl.INIT_VIDEO) < 0) {
        return error.SDL_INIT_ERROR;
    }
    if (sdl_img.init(sdl_img.INIT_PNG) & sdl_img.INIT_PNG == 0) {
        return error.IMG_INIT_ERROR;
    }
}

fn deinitSdl() void {
    _ = sdl_img.quit();
    _ = sdl.quit();
}

fn load(renderer: *sdl.Renderer, file_name: []const u8) !*sdl.Texture {
    const surface_opt = sdl_img.load(file_name.ptr);
    if (surface_opt == null) {
        sdl_img.handleError("Error loading asset as surface");
        return error.SurfaceLoadError;
    }
    defer sdl.freeSurface(surface_opt.?);

    const texture_opt = sdl.createTextureFromSurface(renderer, surface_opt.?);
    if (texture_opt == null) {
        sdl_img.handleError("Error converting surface to texture");
        return error.TextureCreationError;
    }
    return texture_opt.?;
}

fn generateGrid() Grid {
    var grid = Grid{ .grid = [_]Cell{undefined} ** 81 };
    var i: usize = 0;
    while (i < 9) : (i += 1) {
        var j: usize = 0;
        while (j < 9) : (j += 1) {
            grid.grid[i * 9 + j] = .{
                .draw_position = sdl.Rect{
                    .x = drawLocation(Point{ .x = @intCast(i32, j), .y = @intCast(i32, i) }).x,
                    .y = drawLocation(Point{ .x = @intCast(i32, j), .y = @intCast(i32, i) }).y,
                    .w = 42,
                    .h = 42,
                },
                .current_value = null,
                .corners = undefined,
                .center = undefined,
            };
        }
    }
    return grid;
}

fn SingleArgWrapper(comptime T: type) type {
    return struct {
        value: T,
        func: fn (*WorldData, T) void,

        pub fn call(self: @This(), world: *WorldData) void {
            self.func(world, self.value);
        }
    };
}

const VoidWrapper = struct {
    func: fn (*WorldData) void,

    pub fn call(self: @This(), world: *WorldData) void {
        self.func(world);
    }
};

const FuncWrapper = union(enum) {
    Number: SingleArgWrapper(u8),
    Position: SingleArgWrapper(Point),
    Void: VoidWrapper,

    pub fn call(self: @This(), world: *WorldData) void {
        // there's gotta be a way to do a generic "whatever the active one is do the thing"
        return switch (self) {
            .Number => |v| v.call(world),
            .Position => |v| v.call(world),
            .Void => |v| v.call(world),
        };
    }
};

fn makeKeyMap() [1000]FuncWrapper {
    const noopFuncWrapper = FuncWrapper{ .Void = .{ .func = noop } };
    var keyboardActions = [_]FuncWrapper{noopFuncWrapper} ** 1000;
    keyboardActions[sdl.SCANCODE_UP] = .{ .Position = .{ .value = Point{ .x = 0, .y = -1 }, .func = WorldData.updateSingleSelection } };
    keyboardActions[sdl.SCANCODE_DOWN] = .{ .Position = .{ .value = Point{ .x = 0, .y = 1 }, .func = WorldData.updateSingleSelection } };
    keyboardActions[sdl.SCANCODE_LEFT] = .{ .Position = .{ .value = Point{ .x = -1, .y = 0 }, .func = WorldData.updateSingleSelection } };
    keyboardActions[sdl.SCANCODE_RIGHT] = .{ .Position = .{ .value = Point{ .x = 1, .y = 0 }, .func = WorldData.updateSingleSelection } };
    keyboardActions[sdl.SCANCODE_C] = .{ .Void = .{ .func = checkSolution } };
    keyboardActions[sdl.SCANCODE_R] = .{ .Void = .{ .func = resetGrid } };
    keyboardActions[sdl.SCANCODE_1] = .{ .Number = .{ .value = 1, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_2] = .{ .Number = .{ .value = 2, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_3] = .{ .Number = .{ .value = 3, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_4] = .{ .Number = .{ .value = 4, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_5] = .{ .Number = .{ .value = 5, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_6] = .{ .Number = .{ .value = 6, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_7] = .{ .Number = .{ .value = 7, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_8] = .{ .Number = .{ .value = 8, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_9] = .{ .Number = .{ .value = 9, .func = WorldData.updateNumber } };
    keyboardActions[sdl.SCANCODE_BACKSPACE] = .{ .Void = .{ .func = WorldData.deleteSelection } };
    keyboardActions[sdl.SCANCODE_Z] = .{ .Void = .{ .func = WorldData.big } };
    keyboardActions[sdl.SCANCODE_X] = .{ .Void = .{ .func = WorldData.centers } };
    return keyboardActions;
}

fn noop(w: *WorldData) void {}

// Vanity, does an offset that makes a grid I happen to like
fn drawLocation(point: Point) Point {
    return Point{
        .x = @intCast(i32, point.x * 43 + 4 * (@divTrunc(point.x, 3) + 1) - 1),
        .y = @intCast(i32, point.y * 43 + 4 * (@divTrunc(point.y, 3) + 1) - 1),
    };
}

/// Initialize Once in practice
const WorldData = struct {
    window: *sdl.Window,
    renderer: *sdl.Renderer,
    grid: Grid,
    selected_cells: std.ArrayList(Point),
    enter_state: State,
    allocator: *Allocator, // unused right now but might as well keep it around
    numbers: *sdl.Texture,
    incorrect: bool = false,
    victory: bool = false,

    const Self = @This();

    const State = enum {
        Big,
        Center,
    };

    pub fn init(alloc: *Allocator) !Self {
        const window = try sdl.createWindow(
            "Sudoku",
            sdl.WINDOWPOS_CENTERED,
            sdl.WINDOWPOS_CENTERED,
            640,
            480,
            .{sdl.WINDOW_SHOWN},
        );
        const renderer = try sdl.createRenderer(window, -1, .{});
        const big_numbers_texture = try load(renderer, "assets/big_numbers.png");
        var grid = generateGrid();
        var selected = try std.ArrayList(Point).initCapacity(alloc, grid.grid.len);
        try selected.append(Point{ .x = 0, .y = 0 });

        return WorldData{
            .window = window,
            .renderer = renderer,
            .grid = grid,
            .selected_cells = selected,
            .enter_state = State.Big,
            .allocator = alloc,
            .numbers = big_numbers_texture,
        };
    }

    pub fn deinit(self: *Self) void {
        self.selected_cells.deinit();
        sdl.destroyTexture(self.numbers);
        _ = sdl.destroyRenderer(self.renderer);
        _ = sdl.destroyWindow(self.window);
    }

    // ugly af but it does what I want
    pub fn render(self: *Self) !void {
        try sdl.setRenderDrawColor(self.renderer, sdl.WHITE);
        try sdl.renderClear(self.renderer);
        try sdl.setRenderDrawColor(self.renderer, sdl.BLACK);
        if (self.incorrect) {
            try sdl.setRenderDrawColor(self.renderer, sdl.RED);
        } else if (self.victory) {
            try sdl.setRenderDrawColor(self.renderer, sdl.GREEN);
        }
        const mode_rect = sdl.Rect{
            .x = 475,
            .y = 50,
            .w = 150,
            .h = 100,
        };
        try sdl.renderFillRect(self.renderer, &mode_rect);
        try sdl.setRenderDrawColor(self.renderer, grey_boarder);

        for (self.grid.grid) |cell| {
            try sdl.renderDrawRect(self.renderer, &cell.draw_position);
            // Draw the big number if it's been placed
            if (cell.current_value) |value| {
                const cv_expand: i32 = value;
                const number_src = sdl.Rect{ .x = (cv_expand - 1) * 42, .y = 0, .w = 42, .h = 42 };
                const number_draw_pos = sdl.Rect{
                    .x = cell.draw_position.x + 2,
                    .y = cell.draw_position.y + 2,
                    .w = 38,
                    .h = 38,
                };
                try sdl.renderCopy(
                    self.renderer,
                    self.numbers,
                    &number_src,
                    &number_draw_pos,
                );
            } else {
                // draw any of the little numbers we've annotated
                var printed_values: i32 = 0;
                var start_y: i32 = 7;
                const start_x: i32 = 3;
                for (cell.center) |b, idx| {
                    if (b) {
                        const number_src = sdl.Rect{ .x = @intCast(i32, idx) * 42, .y = 0, .w = 42, .h = 42 };
                        const small_number_draw = sdl.Rect{
                            .x = cell.draw_position.x + start_x + 7 * printed_values,
                            .y = cell.draw_position.y + start_y,
                            .w = 7,
                            .h = 10,
                        };
                        try sdl.renderCopy(
                            self.renderer,
                            self.numbers,
                            &number_src,
                            &small_number_draw,
                        );

                        printed_values += 1;
                        if (printed_values == 5) {
                            start_y = 22;
                            printed_values = 0;
                        }
                    }
                }
            }
        }
        try sdl.setRenderDrawColor(self.renderer, selected_color);
        for (self.selected_cells.items) |pos| {
            const cell = self.grid.at(pos);
            try sdl.renderDrawRect(self.renderer, &cell.draw_position);
        }

        sdl.renderPresent(self.renderer);
    }

    pub fn updateSingleSelection(world: *Self, transform: Point) void {
        std.debug.assert(world.selected_cells.items.len > 0);
        const old_point = world.selected_cells.items[0];
        const new_selection: Point = .{
            .x = wrap(old_point.x + transform.x, 0, 9),
            .y = wrap(old_point.y + transform.y, 0, 9),
        };
        world.selected_cells.items[0] = new_selection;
        world.selected_cells.resize(1) catch unreachable; // always resizing less than capacity
        // note because it's sudoku we list it as row, column rather than x, y
        std.debug.warn(
            "Updating selection from r{}c{} to r{}c{}\n",
            .{ old_point.y + 1, old_point.x + 1, new_selection.y + 1, new_selection.x + 1 },
        );
    }

    pub fn updateNumber(self: *Self, value: u8) void {
        if (self.enter_state == State.Big) {
            for (self.selected_cells.items) |pos| {
                var cell = self.grid.at(pos);
                cell.current_value = value; // TODO: world stat e.g. corner/center
                std.debug.warn("Updating selection r{}c{} to value {}\n", .{ pos.y + 1, pos.x + 1, value });
            }
        } else {
            for (self.selected_cells.items) |pos| {
                var cell = self.grid.at(pos);
                if (cell.current_value == null) {
                    cell.center[value - 1] = true; // TODO: world stat e.g. corner/center
                    std.debug.warn("Adding center value {} to selection r{}c{}\n", .{ value, pos.y + 1, pos.x + 1 });
                }
            }
        }
    }

    pub fn deleteSelection(self: *Self) void {
        for (self.selected_cells.items) |pos| {
            // If we have a current "Big" number just delete the big number
            // otherwise clear the cell
            var cell = self.grid.at(pos);
            if (cell.current_value != null) {
                cell.current_value = null;
            } else {
                for (cell.center) |*b| {
                    b.* = false;
                }
            }
        }
    }

    pub fn centers(self: *Self) void {
        self.enter_state = State.Center;
    }

    pub fn big(self: *Self) void {
        self.enter_state = State.Big;
    }
};

/// Inclusive of lower_bound but exclusive of upper_bound
fn wrap(value: i32, lower_bound: i32, upper_bound: i32) i32 {
    std.debug.assert((value >= lower_bound and value < upper_bound) or (value == lower_bound - 1) or (value == upper_bound));
    if (value < lower_bound) {
        return upper_bound - 1;
    } else if (value >= upper_bound) {
        return lower_bound;
    } else {
        return value;
    }
}

const Point = struct {
    x: i32,
    y: i32,
};

const Cell = struct {
    current_value: ?u8,
    corners: [9]bool,
    center: [9]bool,
    draw_position: sdl.Rect,
};

const Grid = struct {
    grid: [81]Cell,

    const Self = @This();

    pub fn at(self: *Self, point: Point) *Cell {
        std.debug.assert(point.x >= 0 and point.y >= 0);
        return &self.grid[@intCast(usize, point.y * 9 + point.x)];
    }
};

// real bad impl
fn checkSolution(world: *WorldData) void {
    // check rows
    var grid = &world.grid;
    var row: usize = 0;
    while (row < 9) : (row += 1) {
        var col: usize = 0;
        var row_buffer = [1]u8{0} ** 9;
        while (col < 9) : (col += 1) {
            if (grid.at(Point{ .x = @intCast(i32, col), .y = @intCast(i32, row) }).current_value) |value| {
                std.debug.assert(value > 0);
                row_buffer[value - 1] += 1;
            }
        }

        for (row_buffer) |value| {
            if (value != 1) {
                std.debug.warn("Solution is incorrect\n", .{});
                world.incorrect = true;
                return;
            }
        }
    }

    // row is now columns
    row = 0;
    while (row < 9) : (row += 1) {
        var col: usize = 0; // col is actually rows
        var col_buffer = [1]u8{0} ** 9;
        while (col < 9) : (col += 1) {
            if (grid.at(Point{ .x = @intCast(i32, col), .y = @intCast(i32, row) }).current_value) |value| {
                std.debug.assert(value > 0);
                col_buffer[value - 1] += 1;
            }
        }
        for (col_buffer) |value| {
            if (value != 1) {
                std.debug.warn("Solution is incorrect\n", .{});
                world.incorrect = true;
                return;
            }
        }
    }

    // solution is correct
    std.debug.warn("THE SOLUTION IS CORRECT!\n", .{});
    for (grid.grid) |cell| {
        std.debug.warn("{}, ", .{cell.current_value.?});
    }

    world.victory = true;
    world.incorrect = false;
}

fn resetGrid(world: *WorldData) void {
    const grid = &world.grid;
    std.debug.warn("Resetting Grid\n", .{});
    for (grid.grid) |*cell| {
        cell.current_value = null;
        for (cell.center) |*b| {
            b.* = false;
        }
    }

    world.victory = false;
    world.incorrect = false;
}
