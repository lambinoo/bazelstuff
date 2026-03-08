load("@rules_img//img:layer.bzl", "layer_from_tar")
load("@rules_license//rules:providers.bzl", "LicenseInfo", "PackageInfo")

_TransitiveInfo = provider(
    fields = {
        "packages": "The package info associated with a target",
    },
)

_Package = provider(
    fields = {
        "label": "The target package",
        "info": "Package info",
        "license_info": "License information",
    },
)

def _transitive_info(ctx):
    packages = []

    attrs = dir(ctx.rule.attr)
    for attr_name in attrs:
        if attr_name.startswith("_"):
            continue

        attr_value = getattr(ctx.rule.attr, attr_name)
        if type(attr_value) == type({}):
            maybe_targets = [attr_value.values()]
        elif type(attr_value) != type([]):
            maybe_targets = [attr_value]
        else:
            maybe_targets = attr_value

        for foreign_target in maybe_targets:
            if type(foreign_target) == "Target":
                if _TransitiveInfo in foreign_target:
                    transitive_info = foreign_target[_TransitiveInfo]
                    packages.append(transitive_info.packages)

    return packages

def _sbom_aspect_impl(target, ctx):
    license_info = None
    package_info = None
    for md in ctx.rule.attr.package_metadata:
        if LicenseInfo in md:
            if license_info == None:
                license_info = md[LicenseInfo]
            else:
                fail("Multiple `license` attached to {}".format(target))

        if PackageInfo in md:
            if package_info == None:
                package_info = md[PackageInfo]
            else:
                fail("Multiple `package_info` attached to {}".format(target))

    transitive_packages = _transitive_info(ctx)

    packages = []
    if package_info:
        packages = [_Package(label = target.label, info = package_info, license_info = license_info)]

    infos = _TransitiveInfo(
        packages = depset(packages, transitive = transitive_packages),
    )
    return [infos]

sbom_aspect = aspect(
    implementation = _sbom_aspect_impl,
    attr_aspects = ["*"],
    apply_to_generating_rules = True,
)

def _package_to_component(package):
    licenses = []
    if package.license_info != None:
        licenses = [struct(license = struct(id = license.name)) for license in package.license_info.license_kinds]

    return struct(
        type = "library",
        name = package.info.package_name,
        purl = package.info.purl,
        version = package.info.package_version,
        licenses = licenses,
        externalReferences = [
            struct(
                type = "website",
                url = package.info.package_url,
            ),
        ],
    )

def _sbom_rule_impl(ctx):
    sbom = struct(
        bomFormat = "CycloneDX",
        specVersion = "1.2",
        version = "1",
        metadata = struct(),
        components = [],
    )

    for target in ctx.attr.deps:
        for package in target[_TransitiveInfo].packages.to_list():
            sbom.components.append(_package_to_component(package))

    sbom_file = ctx.actions.declare_file("{}.sbom.json".format(ctx.label.name))
    ctx.actions.write(
        content = json.encode(sbom),
        output = sbom_file,
    )

    return [DefaultInfo(files = depset([sbom_file]))]

sbom = rule(
    implementation = _sbom_rule_impl,
    attrs = {
        "deps": attr.label_list(mandatory = True, providers = [_TransitiveInfo], aspects = [sbom_aspect]),
    },
)

def _deps_layer_rule_impl(ctx):
    list_file = ctx.actions.declare_file("list.json")
    deps_runfiles = ctx.attr.impl[DefaultInfo].default_runfiles.files
    ctx.actions.write(
        output = list_file,
        content = json.encode([file.path for file in deps_runfiles.to_list()]),
    )

    output_file = ctx.actions.declare_file("{}.tar".format(ctx.label.name))
    ctx.actions.run(
        inputs = deps_runfiles.to_list() + [list_file],
        executable = ctx.executable._tool,
        arguments = [list_file.path, "--bin-dir", ctx.bin_dir.path, "--prefix", ctx.attr.prefix, "-o", output_file.path],
        outputs = [output_file],
    )

    return [DefaultInfo(files = depset([output_file]))]

deps_layer_rule = rule(
    implementation = _deps_layer_rule_impl,
    attrs = {
        "impl": attr.label(mandatory = True, executable = True, cfg = "target", providers = [DefaultInfo]),
        "prefix": attr.string(default = ""),
        "_tool": attr.label(default = "//deps:deps", executable = True, cfg = "exec"),
    },
)

def _deps_layer_macro_impl(name, visibility, **kwargs):
    tarfile = "{}.tar".format(name)
    deps_layer_rule(
        name = tarfile,
        **kwargs
    )

    layer_from_tar(
        name = name,
        src = tarfile,
        compress = "gzip",
        visibility = visibility,
    )

deps_layer = macro(
    implementation = _deps_layer_macro_impl,
    inherit_attrs = deps_layer_rule,
)
