LicenseFinder-docker
====================

[LicenseFinder](https://github.com/pivotal/LicenseFinder) Docker Image for Ruby

How to Use
----------

```console
./license_finder
```

### Scanning with a pre-built image

If your project's gems are already installed in a Docker image, use `--from-image` to scan against that image:

```console
./license_finder --from-image my-ruby-app:latest
```

This extracts the installed gems from the specified image and uses them for license analysis, avoiding the need to run `bundle install`.

Other Languages
---------------

This image only supports Ruby. For other languages, consider the following alternatives:

- [licensefinder/license_finder](https://hub.docker.com/r/licensefinder/license_finder) - Official LicenseFinder image with multi-language support
- [pip-licenses](https://github.com/raimon49/pip-licenses) - Python
- [composer licenses](https://getcomposer.org/doc/03-cli.md#licenses) - PHP

Author
------

[Shinichi Akiyama](https://github.com/shakiyam)

License
-------

[MIT License](https://opensource.org/licenses/MIT)
