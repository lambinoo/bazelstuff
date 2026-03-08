load("@rules_cc//cc:defs.bzl", "CcInfo")

def _cc_export_impl(ctx):
    return [ctx.attr.dep[DefaultInfo], ctx.attr.dep[CcInfo]]

cc_export_rule = rule(
    implementation = _cc_export_impl,
    attrs = {
        "dep": attr.label(mandatory = True, providers = [CcInfo]),
    },
    provides = [CcInfo, DefaultInfo],
)

def cc_export(**kwargs):
    cc_export_rule(**kwargs)
