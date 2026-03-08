load("@rules_img//img:image.bzl", "image_manifest")
load("@rules_img//img:layer.bzl", "image_layer")
load("@rules_img//img:load.bzl", "image_load")
load("//deps:defs.bzl", "deps_layer", "sbom")

image_layer(
    name = "test_bin",
    srcs = {
        "usr/bin/test_bin": "//test_bin:test_bin",
    },
    include_runfiles = False,
)

deps_layer(
    name = "deps_layer",
    impl = "//test_bin",
    prefix = "lib/potato/",
)

image_manifest(
    name = "image",
    base = "@ubuntu",
    env = {
        "LD_LIBRARY_PATH": "/lib64:/usr/lib64:/lib/potato",
    },
    layers = [
        ":deps_layer",
        ":test_bin",
    ],
)

image_load(
    name = "image.load",
    image = ":image",
    tag = "my-app:latest",
)

sbom(
    name = "sbom",
    deps = [
        ":image",
    ],
)
