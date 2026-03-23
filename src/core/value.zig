const table_type = @import("./table/type.zig");

pub const ValType = enum {
    I32,
    I64,
    F32,
    F64,
    // A nullable function reference.
    FuncRef,
    // A nullable external reference.
    // external ref is a reference to an opaque object owned by the host environment.
    ExternRef,

    pub fn isNum(self: ValType) bool {
        return switch (self) {
            .I32, .I64, .F32, .F64 => true,
            else => false,
        };
    }

    pub fn isRef(self: ValType) bool {
        return switch (self) {
            .FuncRef, .ExternRef => true,
            else => false,
        };
    }

    // Transforms the Ref Value Type into RefType
    // If the ValType is not a reference type, returns null
    pub fn asRefType(self: ValType) ?table_type.RefType {
        return switch (self) {
            .FuncRef => .table_type.RefType.Func,
            .ExternRef => .table_type.RefType.Extern,
            else => null,
        };
    }

    pub fn fromRefType(refType: table_type.RefType) ValType {
        return switch (refType) {
            .Func => .FuncRef,
            .Extern => .ExternRef,
        };
    }
};

const std = @import("std");

pub const TruncateError = error{
    NaN,
    OutOfRange,
};

// Tries to truncate a floating-point value into an integer of type T (i32 or i64).
// Returns the truncated integer if successful,
// or an error if the value is NaN or out of range.
pub fn tryTruncateInto(comptime T: type, value: anytype) TruncateError!T {
    const Src = @TypeOf(value);

    comptime {
        if (Src != f32 and Src != f64) {
            @compileError("tryTruncateInto only supports f32/f64");
        }
    }

    if (std.math.isNan(value)) {
        return TruncateError.NaN;
    }

    const truncated = @trunc(value);

    if (truncated < std.math.minInt(T) or truncated > std.math.maxInt(T)) {
        return TruncateError.OutOfRange;
    }

    return @intFromFloat(truncated);
}

// Similar to tryTruncateInto,
// but instead of returning an error on out-of-range values,
// it saturates to the min/max integer value.
pub fn truncateSaturateInto(comptime T: type, value: anytype) T {
    const Src = @TypeOf(value);

    comptime {
        if (Src != f32 and Src != f64) {
            @compileError("truncateSaturateInto only supports f32/f64");
        }
    }

    if (std.math.isNan(value)) {
        return 0;
    }

    const truncated = @trunc(value);

    if (truncated < std.math.minInt(T)) {
        return std.math.minInt(T);
    } else if (truncated > std.math.maxInt(T)) {
        return std.math.maxInt(T);
    } else {
        return @intFromFloat(truncated);
    }
}
