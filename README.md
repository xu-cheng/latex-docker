# latex-docker

[![GitHub Actions Status](https://github.com/xu-cheng/latex-docker/workflows/build/badge.svg)](https://github.com/xu-cheng/latex-docker/actions)
[![GitHub Actions Status](https://github.com/xu-cheng/latex-docker/workflows/build-historic/badge.svg)](https://github.com/xu-cheng/latex-docker/actions)

Docker Image of [TeXLive](https://tug.org/texlive/).

## List of Images

### Latest TeXLive Images

| Name                   |    OS    | Platform | Scheme | Usage                                                      |
| :--------------------- | :------: | :------: | :----: | :--------------------------------------------------------- |
| [texlive-debian]       | [Debian] |  amd64   |  Full  | `docker pull ghcr.io/xu-cheng/texlive-debian:latest`       |
| [texlive-alpine]       | [Alpine] |  amd64   |  Full  | `docker pull ghcr.io/xu-cheng/texlive-alpine:latest`       |
| [texlive-alpine-small] | [Alpine] |  amd64   | Small  | `docker pull ghcr.io/xu-cheng/texlive-alpine-small:latest` |

These images are updated quarterly.

### Historical TeXLive Images

| Name                      |    OS    |  Platform   | Scheme | Usage                                                            |
| :------------------------ | :------: | :---------: | :----: | :--------------------------------------------------------------- |
| [texlive-historic-debian] | [Debian] | amd64/arm64 |  Full  | `docker pull ghcr.io/xu-cheng/texlive-historic-debian:<version>` |
| [texlive-historic-alpine] | [Alpine] |    amd64    |  Full  | `docker pull ghcr.io/xu-cheng/texlive-historic-alpine:<version>` |

Available versions include 2020, 2021, 2022, 2023, and 2024.

## See Also

- [latex-action](https://github.com/xu-cheng/latex-action): GitHub action to compile LaTeX documents.
- [texlive-action](https://github.com/xu-cheng/texlive-action): GitHub action to run arbitrary commands in a TeXLive environment.

## License

MIT

[alpine]: https://www.alpinelinux.org/
[debian]: https://www.debian.org/
[texlive-alpine]: https://github.com/users/xu-cheng/packages/container/package/texlive-alpine
[texlive-alpine-small]: https://github.com/users/xu-cheng/packages/container/package/texlive-alpine-small
[texlive-debian]: https://github.com/users/xu-cheng/packages/container/package/texlive-debian
[texlive-historic-alpine]: https://github.com/users/xu-cheng/packages/container/package/texlive-historic-alpine
[texlive-historic-debian]: https://github.com/users/xu-cheng/packages/container/package/texlive-historic-debian
