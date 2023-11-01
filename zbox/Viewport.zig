left: ?f64 = null,
right: ?f64 = null,
top: ?f64 = null,
bottom: ?f64 = null,

pub fn width(self: Viewport) f64 {
    if (self.left) |left| {
        if (self.right) |right| {
            return right - left;
        }
    }
    return 0;
}

pub fn height(self: Viewport) f64 {
    if (self.top) |top| {
        if (self.bottom) |bottom| {
            return bottom - top;
        }
    }
    return 0;
}

pub fn includePoint(self: *Viewport, x: f64, y: f64) void {
    self.left = if (self.left) |left| @min(left, x) else x;
    self.right = if (self.right) |right| @max(right, x) else x;
    self.top = if (self.top) |top| @min(top, y) else y;
    self.bottom = if (self.bottom) |bottom| @max(bottom, y) else y;
}

const Viewport = @This();
