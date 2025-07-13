load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//hugo:internal/github_hugo_theme.bzl", "github_hugo_theme")
load("//hugo:internal/hugo_repository.bzl", "hugo_repository")

def _hugo_deps_impl(module_ctx):
    """Implementation of the hugo_deps module extension."""

    # Process all hugo_repository calls
    for mod in module_ctx.modules:
        for hugo_repo in mod.tags.hugo_repository:
            hugo_repository(
                name = hugo_repo.name,
                version = hugo_repo.version,
                extended = hugo_repo.extended,
                sha256 = hugo_repo.sha256,
                os_arch = hugo_repo.os_arch,
            )

        # Process all github_hugo_theme calls
        for theme in mod.tags.github_hugo_theme:
            github_hugo_theme(
                name = theme.name,
                owner = theme.owner,
                repo = theme.repo,
                commit = theme.commit,
                sha256 = theme.sha256,
                github_host = theme.github_host,
            )

        # Process all http_archive calls
        for archive in mod.tags.http_archive:
            http_archive(
                name = archive.name,
                url = archive.url,
                sha256 = archive.sha256,
                build_file_content = archive.build_file_content,
                strip_prefix = archive.strip_prefix,
            )

# Define the tag classes for the extension
_hugo_repository_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "version": attr.string(default = "0.148.1"),
        "extended": attr.bool(default = False),
        "sha256": attr.string(),
        "os_arch": attr.string(),
    },
)

_github_hugo_theme_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "owner": attr.string(mandatory = True),
        "repo": attr.string(mandatory = True),
        "commit": attr.string(mandatory = True),
        "sha256": attr.string(),
        "github_host": attr.string(default = "github.com"),
    },
)

_http_archive_tag = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
        "sha256": attr.string(),
        "build_file_content": attr.string(),
        "strip_prefix": attr.string(),
    },
)

# Define the module extension
hugo_deps = module_extension(
    implementation = _hugo_deps_impl,
    tag_classes = {
        "hugo_repository": _hugo_repository_tag,
        "github_hugo_theme": _github_hugo_theme_tag,
        "http_archive": _http_archive_tag,
    },
)
