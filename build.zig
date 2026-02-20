const std = @import("std");

const examples = [_]struct {
    name: []const u8,
    path: []const u8,
}{
    .{ .name = "hello", .path = "examples/hello/src/main.zig" },
    .{ .name = "increment", .path = "examples/increment/src/main.zig" },
    .{ .name = "logging", .path = "examples/logging/src/main.zig" },
    .{ .name = "errors", .path = "examples/errors/src/main.zig" },
    .{ .name = "events", .path = "examples/events/src/main.zig" },
};

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const sdk = b.dependency("soroban-sdk", .{ .optimize = optimize });
    const sdk_module = sdk.module("soroban-sdk");

    const postprocess = b.addExecutable(.{
        .name = "postprocess_wasm",
        .root_module = b.createModule(.{
            .root_source_file = sdk.path("tools/postprocess_wasm.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });

    inline for (examples) |ex| {
        const contract = b.addExecutable(.{
            .name = ex.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(ex.path),
                .target = b.resolveTargetQuery(.{
                    .cpu_arch = .wasm32,
                    .os_tag = .freestanding,
                    .cpu_features_sub = std.Target.wasm.featureSet(&.{
                        .multivalue,
                        .extended_const,
                        .nontrapping_fptoint,
                        .call_indirect_overlong,
                    }),
                }),
                .optimize = optimize,
            }),
        });
        contract.root_module.addImport("soroban-sdk", sdk_module);
        contract.root_module.strip = true;
        contract.entry = .disabled;
        contract.rdynamic = true;

        const run = b.addRunArtifact(postprocess);
        run.addArtifactArg(contract);
        const wasm = run.addOutputFileArg(ex.name ++ ".wasm");

        const install = b.addInstallBinFile(wasm, ex.name ++ ".wasm");
        install.step.dependOn(&run.step);

        const step = b.step(ex.name, "Build " ++ ex.name ++ " contract");
        step.dependOn(&install.step);
    }
}
