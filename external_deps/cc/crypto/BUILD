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

cc_export(
    name = "crypto",
    dep = "@openssl//:crypto",
)

license(
    name = "license",
    license_kinds = [
        "@rules_license//licenses/spdx:Apache-2.0",
    ],
)

package_info(
    name = "package",
    package_name = "openssl",
    package_url = "https://www.openssl.org/",
    package_version = "3.5.5",
    purl = "pkg:github/openssl/openssl@67b5686b4419b4cb8caa502711c41815f5279751",
)
