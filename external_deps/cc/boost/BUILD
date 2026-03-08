load("@rules_license//rules:license.bzl", "license")
load("@rules_license//rules:package_info.bzl", "package_info")
load("//private:defs.bzl", "cc_export")

package(
    default_package_metadata = [
        ":license",
        ":package",
    ],
    default_visibility = ["//visibility:public"],
)

license(
    name = "license",
    package_name = "boost",
    license_kind = "//spdx:BSL-1.0",
)

cc_export(
    name = "asio",
    dep = "@boost.asio//:boost.asio",
)

cc_export(
    name = "beast",
    dep = "@boost.beast//:boost.beast",
)

package_info(
    name = "package",
    package_name = "boost",
    package_url = "https://www.boost.org/",
    package_version = "3.5.5",
    purl = "pkg:github/boostorg/beast@67106ebaab7a644a9bdb5d6e6b0a3f4ad1d0e4f7",
)
