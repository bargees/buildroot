################################################################################
#
# docker-engine
#
################################################################################

DOCKER_ENGINE_VERSION = 1.10.3
DOCKER_ENGINE_GITCOMMIT = 20f81dd
DOCKER_ENGINE_SITE = $(call github,moby,moby,v$(DOCKER_ENGINE_VERSION))

DOCKER_ENGINE_SRC_SUBDIR = github.com/docker/docker
DOCKER_ENGINE_WORKSPACE = vendor

DOCKER_ENGINE_LICENSE = Apache-2.0
DOCKER_ENGINE_LICENSE_FILES = LICENSE

DOCKER_ENGINE_DEPENDENCIES = host-go host-pkgconf

DOCKER_ENGINE_LDFLAGS = -w -s \
	-X main.GitCommit=$(DOCKER_ENGINE_GITCOMMIT) \
	-X main.Version=$(DOCKER_ENGINE_VERSION)

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_STATIC_CLIENT),y)
DOCKER_ENGINE_LDFLAGS += -extldflags '-static'
endif

DOCKER_ENGINE_TAGS = cgo exclude_graphdriver_zfs exclude_graphdriver_aufs autogen \
	sqlite_omit_load_extension
DOCKER_ENGINE_BUILD_TARGETS = docker

ifeq ($(BR2_PACKAGE_LIBSECCOMP),y)
DOCKER_ENGINE_TAGS += seccomp
DOCKER_ENGINE_DEPENDENCIES += libseccomp
endif

ifeq ($(BR2_INIT_SYSTEMD),y)
DOCKER_ENGINE_TAGS += journald
DOCKER_ENGINE_DEPENDENCIES += systemd
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DAEMON),y)
DOCKER_ENGINE_TAGS += daemon
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_EXPERIMENTAL),y)
DOCKER_ENGINE_TAGS += experimental
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_BTRFS),y)
DOCKER_ENGINE_DEPENDENCIES += btrfs-progs
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_btrfs
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_DEVICEMAPPER),y)
DOCKER_ENGINE_DEPENDENCIES += lvm2
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_devicemapper
endif

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DRIVER_VFS),y)
DOCKER_ENGINE_DEPENDENCIES += gvfs
else
DOCKER_ENGINE_TAGS += exclude_graphdriver_vfs
endif

DOCKER_ENGINE_INSTALL_BINS = $(notdir $(DOCKER_ENGINE_BUILD_TARGETS))

define DOCKER_ENGINE_RUN_AUTOGEN
	cd $(@D) && \
		GITCOMMIT="$(DOCKER_ENGINE_GITCOMMIT)" \
		BUILDTIME="$$(date)" \
		VERSION="$(DOCKER_ENGINE_VERSION)" \
		PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)" $(TARGET_MAKE_ENV) \
		bash ./hack/make/.go-autogen
endef

DOCKER_ENGINE_POST_CONFIGURE_HOOKS += DOCKER_ENGINE_RUN_AUTOGEN

ifeq ($(BR2_PACKAGE_DOCKER_ENGINE_DAEMON),y)

define DOCKER_ENGINE_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.service \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.service
	$(INSTALL) -D -m 0644 $(@D)/contrib/init/systemd/docker.socket \
		$(TARGET_DIR)/usr/lib/systemd/system/docker.socket
	mkdir -p $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/
	ln -fs ../../../../usr/lib/systemd/system/docker.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/docker.service
endef

define DOCKER_ENGINE_USERS
	- - docker -1 * - - - Docker Application Container Framework
endef

endif

$(eval $(golang-package))
