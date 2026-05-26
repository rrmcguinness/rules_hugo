---
title: Introduction
type: docs
---

# Bazel Rules for Hugo Static Site Generator

<table><tr>
<td><img src="https://bazel.build/images/bazel-icon.svg" height="120"/></td>
<td><img src="https://raw.githubusercontent.com/gohugoio/hugoDocs/master/static/img/hugo-logo.png" height="120"/></td>
</tr><tr>
<td>Rules</td>
<td>Hugo</td>
</tr></table>

## Add Module Dependencies

Declare a dependency on `rules_hugo_rmcguinness` and the hugo binary as well as the theme in your `MODULE.bazel`:

```python
bazel_dep(name = "rules_hugo_rmcguinness", version = "0.2.0")

hugo_deps = use_extension("@rules_hugo_rmcguinness//hugo:extensions.bzl", "hugo_deps")

# Configure Hugo repository
hugo_deps.hugo_repository(
    name = "hugo",
    extended = True,
    version = "0.162.0",
)

# Load hugo-book theme
hugo_deps.http_archive(
    name = "hugo_theme_book",
    build_file_content = """
filegroup(
    name = "files",
    srcs = glob(["**"]),
    visibility = ["//visibility:public"]
)
    """,
    sha256 = "adf41c4282974dc7b42aa28762e34b704a0aad4ec8d648eb425484dbdfbbefc8",
    strip_prefix = "hugo-book-11.0.0",
    url = "https://github.com/alex-shpak/hugo-book/archive/refs/tags/v11.0.0.zip",
)

use_repo(hugo_deps, "hugo", "hugo_theme_book")
```

## Add Theme Files

Copy the site template files into your repository.  Typically themes include an
`exampleSite`, so one way to do this is:

```sh
$ bazel fetch @hugo_theme_book//:files
$ cp -r $(bazel info output_base)/external/hugo_theme_book/exampleSite/ ./site
```

## Build Rules

Create a build file for the site:

```sh
$ touch site/BUILD.bazel
```

Having the following rules:

```python
load("@rules_hugo_rmcguinness//hugo:rules.bzl", "hugo_site", "hugo_theme")

hugo_theme(
    name = "book",
    srcs = [
        "@hugo_theme_book//:files",
    ],
)

hugo_site(
    name = "site",
    config = "config.yaml",
    content = glob(["content/**"]),
    static = glob(["static/**"]),
    layouts = glob(["layouts/**"]),
    theme = ":book",
)
```

## Generate

To build the site:

```sh
$ bazel build //site
```

Locally serve site:

```sh
$ (cd $(shell bazel info bazel-bin)/site/site && python -m SimpleHTTPServer 7070)
```

Create a tarball:

```sh
$ tar -cvf bazel-out/site.tar -C $(shell bazel info bazel-bin)/site/site .
```

## End

Have fun!
