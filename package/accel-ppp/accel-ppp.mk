ACCEL_PPP_VERSION = 1.14.0
ACCEL_PPP_SITE = $(call github,accel-ppp,accel-ppp,$(ACCEL_PPP_VERSION))
ACCEL_PPP_LICENSE = GPL-2.0+
ACCEL_PPP_LICENSE_FILES = COPYING
ACCEL_PPP_DEPENDENCIES = openssl pcre2 $(if $(BR2_TOOLCHAIN_USES_MUSL),libucontext)

# LIB_SUFFIX is otherwise guessed from the *host* `uname -m` (x86_64 -> "64"),
# which would install to /usr/lib64 and bake that into MODULE_PATH.
ACCEL_PPP_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=MinSizeRel \
	-DIGNORE_GIT=ON \
	-DLIB_SUFFIX= \
	-DRADIUS=FALSE -DSHAPER=FALSE -DLUA=FALSE -DNETSNMP=FALSE \
	-DBUILD_IPOE_DRIVER=FALSE -DBUILD_VLAN_MON_DRIVER=FALSE

# Upstream detects musl by running the HOST's `ldd --version`, which is wrong
# when cross-compiling in the Debian-based Buildroot docker image. Force it.
define ACCEL_PPP_FORCE_MUSL
	$(SED) 's/if (LDD_VERSION MATCHES "\[Mm\]usl")/if (TRUE)/' $(@D)/CMakeLists.txt
endef
ACCEL_PPP_PRE_CONFIGURE_HOOKS += $(if $(BR2_TOOLCHAIN_USES_MUSL),ACCEL_PPP_FORCE_MUSL)

# Drop modules that cannot work with this kernel (no IPv6, no L2TP/PPTP,
# no out-of-tree IPoE driver) and the sample config: the image ships no
# configuration, the player supplies their own.
# NB: modules are installed as lib<name>.so; libconnlimit and libvlan-mon must
# stay, libpppoe links against them on musl.
define ACCEL_PPP_TRIM_TARGET
	cd $(TARGET_DIR)/usr/lib/accel-ppp && \
		rm -f libl2tp.so libpptp.so libsstp.so libipoe.so \
		      libipv6_dhcp.so libipv6_nd.so libipv6pool.so
	rm -f $(TARGET_DIR)/etc/accel-ppp.conf.dist \
	      $(TARGET_DIR)/usr/etc/accel-ppp.conf.dist
	rmdir $(TARGET_DIR)/usr/etc 2>/dev/null || true
endef
ACCEL_PPP_POST_INSTALL_TARGET_HOOKS += ACCEL_PPP_TRIM_TARGET

$(eval $(cmake-package))
