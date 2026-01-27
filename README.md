LicenseFinder-docker
====================

[LicenseFinder](https://github.com/pivotal/LicenseFinder) Docker Image for Ruby 
How to Use
----------

```console
docker container run --rm -t -u "$(id -u):$(id -g)" -v "$PWD":/scan:ro ghcr.io/shakiyam/license_finder
```

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
