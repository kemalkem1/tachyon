load("//bazel:tachyon_cc.bzl", "tachyon_cc_library")

def _generate_ec_point_impl(ctx):
    arguments = [
        "--out=%s" % (ctx.outputs.out.path),
        "--type=%s" % (ctx.attr.type),
        "--fq_limb_nums=%s" % (ctx.attr.fq_limb_nums),
        "--fr_limb_nums=%s" % (ctx.attr.fr_limb_nums),
    ]

    ctx.actions.run(
        tools = [ctx.executable._tool],
        executable = ctx.executable._tool,
        outputs = [ctx.outputs.out],
        arguments = arguments,
    )

    return [DefaultInfo(files = depset([ctx.outputs.out]))]

generate_ec_point = rule(
    implementation = _generate_ec_point_impl,
    attrs = {
        "out": attr.output(mandatory = True),
        "type": attr.string(mandatory = True),
        "fq_limb_nums": attr.int(mandatory = True),
        "fr_limb_nums": attr.int(mandatory = True),
        "_tool": attr.label(
            # TODO(chokobole): Change it to "exec" we can build it on macos.
            cfg = "target",
            executable = True,
            allow_single_file = True,
            default = Label("@kroma_network_tachyon//tachyon/cc/math/elliptic_curves/generator"),
        ),
    },
)

def generate_ec_points(
        name,
        fq_limb_nums,
        fr_limb_nums,
        deps = [],
        **kwargs):
    for n in [
        ("gen_point_traits", "point_traits.h"),
        ("gen_util_hdr", "{}_util.h".format(name)),
        ("gen_util_src", "{}_util.cc".format(name)),
    ]:
        generate_ec_point(
            type = name,
            fq_limb_nums = fq_limb_nums,
            fr_limb_nums = fr_limb_nums,
            name = n[0],
            out = n[1],
        )

    tachyon_cc_library(
        name = "{}_util".format(name),
        srcs = [":gen_util_src"],
        hdrs = [":gen_util_hdr"],
        deps = deps + [
            ":point_traits",
            "//tachyon/cc/math/finite_fields:prime_field_conversions",
            "//tachyon/cc/math/elliptic_curves:point_conversions",
        ],
    )

    tachyon_cc_library(
        name = "point_traits",
        hdrs = [":gen_point_traits"],
        deps = deps + [
            "//tachyon/cc/math/finite_fields:prime_field_traits",
            "//tachyon/cc/math/elliptic_curves:point_traits",
        ],
    )
