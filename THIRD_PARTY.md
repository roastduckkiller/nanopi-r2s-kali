# Third-party components and provenance

The MIT license applies to this repository's original scripts and documentation.
It does not relicense software downloaded or copied by the build.

| Component | Source / provenance | Distribution in this release |
| --- | --- | --- |
| Kali packages | [Kali archive](https://http.kali.org/kali), signature checked with the Kali archive key | Downloaded by users at build time; not bundled |
| R2S bootloader, DTB, initramfs, kernel, modules, firmware | User's working FriendlyELEC system, vendor kernel 6.6.134+ in the tested setup | Copied locally by the build; not bundled |
| Node.js | [Official Node 24.21.0 release](https://nodejs.org/dist/v24.21.0/) | Optional user download |
| Pi | npm `@earendil-works/pi-coding-agent` 0.87.1 | Optional user download |

Kali package license/copyright notices live under `/usr/share/doc/*/copyright`
in the generated filesystem. The archive contains corresponding source packages;
use the matching package versions when retrieving sources. Firmware licenses may
differ from the kernel's license.

Vendor references:
- [NanoPi R2S documentation](https://wiki.friendlyelec.com/wiki/index.php/NanoPi_R2S)
- [FriendlyELEC kernel source, nanopi-r2-v6.6.y](https://github.com/friendlyarm/kernel-rockchip/tree/nanopi-r2-v6.6.y)
- [RK3328 SD image tooling](https://github.com/friendlyarm/sd-fuse_rk3328)

The exact source commit/configuration for the original factory kernel was not
recorded. A branch link alone does not establish an exact source match or fulfill
all binary redistribution obligations. Therefore v0.1.0 publishes **source tools
only**, with no vendor dumps or prebuilt OS image. If distributing your generated
image, first establish the corresponding sources and notices required by all
included components, and remove device-specific information from vendor payloads.

Kali Linux® is a trademark of its respective owner. This project is independent,
not endorsed by OffSec/Kali or FriendlyELEC. See the
[Kali trademark policy](https://www.kali.org/docs/policy/trademark/).
