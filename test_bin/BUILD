load("@rules_cc//cc:defs.bzl", "cc_binary")

cc_binary(
    name = "test_bin",
    srcs = ["src/main.cpp"],
    visibility = ["//visibility:public"],
    deps = [
        "@external_deps//cc/boost:asio",
        "@external_deps//cc/boost:beast",
        "@external_deps//cc/crypto",
    ],
)
