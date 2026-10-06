ACCEL_PPP_VERSION = 1.14.0
ACCEL_PPP_SITE = $(call github,accel-ppp,accel-ppp,v$(ACCEL_PPP_VERSION))
ACCEL_PPP_LICENSE = GPL-2.0+
ACCEL_PPP_LICENSE_FILES = LICENSE
ACCEL_PPP_DEPENDENCIES = openssl pcre2 $(if $(BR2_TOOLCHAIN_USES_MUSL),libucontext)

ACCEL_PPP_CONF_OPTS = \
	-DCMAKE_BUILD_TYPE=MinSizeRel \
	-DIGNORE_GIT=ON \
	-DRADIUS=FALSE -DSHAPER=FALSE -DLUA=FALSE -DNETSNMP=FALSE \
	-DBUILD_IPOE_DRIVER=FALSE -DBUILD_VLAN_MON_DRIVER=FALSE

# Upstream detects musl by running the HOST's `ldd --version`, which is wrong
# when cross-compiling in the Debian-based Buildroot docker image. Force it.
define ACCEL_PPP_FORCE_MUSL
	$(SED) 's/if (LDD_VERSION MATCHES "\[Mm\]usl")/if (TRUE)/' $(@D)/CMakeLists.txt
endef
ACCEL_PPP_PRE_CONFIGURE_HOOKS += $(if $(BR2_TOOLCHAIN_USES_MUSL),ACCEL_PPP_FORCE_MUSL)

# Ship only the modules you actually use (see the [modules] list in the conf)
define ACCEL_PPP_TRIM_TARGET
	cd $(TARGET_DIR)/usr/lib/accel-ppp && \
	  rm -f l2tp.so pptp.so sstp.so ipoe.so vlan_mon.so sigchld.so logwtmp.so \
	        auth_mschap_v1.so auth_mschap_v2.so ipv6pool.so ipv6_nd.so ipv6_dhcp.so
	rm -f $(TARGET_DIR)/etc/accel-ppp.conf.dist
endef
ACCEL_PPP_POST_INSTALL_TARGET_HOOKS += ACCEL_PPP_TRIM_TARGET

$(eval $(cmake-package))