HUGO_BUILD_FILE = """
package(default_visibility = ["//visibility:public"])
exports_files(["hugo"])
"""

HUGO_BUILD_FILE_WINDOWS = """
package(default_visibility = ["//visibility:public"])
alias(
    name = "hugo",
    actual = "hugo.exe",
)
exports_files(["hugo.exe"])
"""

def _get_platform_details(os_name, version, extended):
    # Split version to major, minor, patch
    parts = version.split(".")
    major = int(parts[0])
    minor = int(parts[1])
    
    hugo = "hugo_extended" if extended else "hugo"
    
    is_mac = os_name.startswith("mac os") or os_name.startswith("darwin")
    is_windows = os_name.find("windows") != -1
    
    if is_mac:
        if major > 0 or minor >= 153:
            filename = "{hugo}_{version}_darwin-universal.pkg".format(
                hugo = hugo,
                version = version,
            )
            is_pkg = True
        elif major > 0 or minor >= 103:
            filename = "{hugo}_{version}_darwin-universal.tar.gz".format(
                hugo = hugo,
                version = version,
            )
            is_pkg = False
        else:
            filename = "{hugo}_{version}_macOS-64bit.tar.gz".format(
                hugo = hugo,
                version = version,
            )
            is_pkg = False
    elif is_windows:
        is_pkg = False
        if major > 0 or minor >= 103:
            filename = "{hugo}_{version}_windows-amd64.zip".format(
                hugo = hugo,
                version = version,
            )
        else:
            filename = "{hugo}_{version}_Windows-64bit.zip".format(
                hugo = hugo,
                version = version,
            )
    else:
        # Linux / FreeBSD / other Unixes
        is_pkg = False
        if major > 0 or minor >= 103:
            filename = "{hugo}_{version}_linux-amd64.tar.gz".format(
                hugo = hugo,
                version = version,
            )
        else:
            filename = "{hugo}_{version}_Linux-64bit.tar.gz".format(
                hugo = hugo,
                version = version,
            )
            
    url = "https://github.com/gohugoio/hugo/releases/download/v{version}/{filename}".format(
        version = version,
        filename = filename,
    )
    
    return url, is_pkg, is_windows

def _hugo_repository_impl(repository_ctx):
    os_name = repository_ctx.os.name.lower()
    version = repository_ctx.attr.version
    extended = repository_ctx.attr.extended
    
    url, is_pkg, is_windows = _get_platform_details(os_name, version, extended)
    
    if is_pkg:
        # Download the pkg file directly
        repository_ctx.download(
            url = url,
            output = "hugo.pkg",
            sha256 = repository_ctx.attr.sha256,
        )
        # Expand pkg utilizing pkgutil
        res = repository_ctx.execute(["pkgutil", "--expand-full", "hugo.pkg", "expanded"])
        if res.return_code != 0:
            fail("Failed to expand PKG file: " + res.stderr)
            
        # Move binary from expanded/Payload/hugo to hugo
        res = repository_ctx.execute(["cp", "expanded/Payload/hugo", "hugo"])
        if res.return_code != 0:
            fail("Failed to copy binary from expanded PKG: " + res.stderr)
            
        # Give execute permission
        repository_ctx.execute(["chmod", "+x", "hugo"])
        
        # Clean up
        repository_ctx.delete("hugo.pkg")
        repository_ctx.delete("expanded")
    else:
        # Standard download_and_extract
        repository_ctx.download_and_extract(
            url = url,
            sha256 = repository_ctx.attr.sha256,
        )
        
    if is_windows:
        repository_ctx.file("BUILD.bazel", HUGO_BUILD_FILE_WINDOWS)
    else:
        repository_ctx.file("BUILD.bazel", HUGO_BUILD_FILE)

hugo_repository = repository_rule(
    _hugo_repository_impl,
    attrs = {
        "version": attr.string(
            default = "0.55.5",
            doc = "The hugo version to use",
        ),
        "sha256": attr.string(
            doc = "The sha256 value for the binary",
        ),
        "os_arch": attr.string(
            doc = "The os arch value. If empty, autodetect it",
        ),
        "extended": attr.bool(
            doc = "Use extended hugo version",
        ),
    },
)
