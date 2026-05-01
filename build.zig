const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const stdlib_c = b.addTranslateC(.{
        .root_source_file = b.path("headers/stdlib.h"),
        .target = target,
        .optimize = optimize,
    });

    const getch_c = b.addTranslateC(.{
        .root_source_file = b.path(if (target.result.os.tag == .windows) "headers/windows.h" else "headers/linux.h"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "greed",
        .root_module = b.createModule(.{
            .root_source_file = b.path("greed.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "stdlib_c",
                    .module = stdlib_c.createModule(),
                },
                .{
                    .name = "getch_c",
                    .module = getch_c.createModule(),
                },
            },
        }),
    });

    b.installArtifact(exe);
}
