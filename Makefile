kernel-version=5.11.2
arch=x86_64

all: config compile

prepare: prepare_kernel

prepare_kernel:
	mkdir -p ~/build
	cd ~/build && git clone -b v$(kernel-version) --single-branch --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
	cd ~/build/linux-stable && $(MAKE) mrproper
	cd ~/build && mkdir -p pristine
	cd ~/build && cp -r ./linux-stable ./pristine

prepare_update: prepare_kernel
	mv fs/splice.c fs/_splice.c
	cp ~/build/pristine/linux-stable/fs/splice.c fs/splice.c
	mv include/linux/lsm_hook_defs.h include/linux/_lsm_hook_defs.h
	cp ~/build/pristine/linux-stable/include/linux/lsm_hook_defs.h include/linux/lsm_hook_defs.h
	mv include/linux/security.h include/linux/_security.h
	cp ~/build/pristine/linux-stable/include/linux/security.h include/linux/security.h
	mv ipc/mqueue.c ipc/_mqueue.c
	cp ~/build/pristine/linux-stable/ipc/mqueue.c ipc/mqueue.c
	mv ipc/shm.c ipc/_shm.c
	cp ~/build/pristine/linux-stable/ipc/shm.c ipc/shm.c
	mv mm/mmap.c mm/_mmap.c
	cp ~/build/pristine/linux-stable/mm/mmap.c mm/mmap.c
	mv net/socket.c net/_socket.c
	cp ~/build/pristine/linux-stable/net/socket.c net/socket.c
	mv security/Kconfig security/_Kconfig
	cp ~/build/pristine/linux-stable/security/Kconfig security/Kconfig
	mv security/security.c security/_security.c
	cp ~/build/pristine/linux-stable/security/security.c security/security.c

copy_change:
	cp -rf ./fs ~/build/linux-stable
	cp -rf ./include ~/build/linux-stable
	cp -rf ./ipc ~/build/linux-stable
	cp -rf ./mm ~/build/linux-stable
	cp -rf ./net ~/build/linux-stable
	cp -rf ./security ~/build/linux-stable

copy_config:
	cp -f /boot/config-$(shell uname -r) .config
	cp -f ./.config ~/build/linux-stable/.config

config: copy_change copy_config
	cd ~/build/linux-stable && ./scripts/kconfig/streamline_config.pl > config_strip
	cd ~/build/linux-stable &&  mv .config config_sav
	cd ~/build/linux-stable &&  mv config_strip .config
	cd ~/build/linux-stable && $(MAKE) menuconfig

config_circle: copy_change copy_config
	cd ~/build/linux-stable && ./scripts/kconfig/streamline_config.pl > config_strip
	cd ~/build/linux-stable &&  mv .config config_sav
	cd ~/build/linux-stable &&  mv config_strip .config
	cd ~/build/linux-stable && $(MAKE) olddefconfig
	cd ~/build/linux-stable && $(MAKE) oldconfig

config_circle_off: config_circle
	cd ~/build/linux-stable && sed -i -e "s/CONFIG_SECURITY_FLOW_FRIENDLY=y/CONFIG_SECURITY_FLOW_FRIENDLY=n/g" .config
	cd ~/build/linux-stable &&$(MAKE) oldconfig

compile: compile_kernel

compile_kernel: copy_change
	cd ~/build/linux-stable && $(MAKE) -j16

compile_security: copy_change
	cd ~/build/linux-stable && $(MAKE) security W=1 -j16

install: install_kernel

install_kernel:
	cd ~/build/linux-stable && sudo $(MAKE) modules_install
	cd ~/build/linux-stable && sudo $(MAKE) install
	cd ~/build/linux-stable && sudo cp -f .config /boot/config-$(kernel-version)heck

clean: clean_kernel

clean_kernel:
	cd ~/build/linux-stable && $(MAKE) clean
	cd ~/build/linux-stable && $(MAKE) mrproper

delete_kernel:
	cd ~/build && sudo rm -rf ./linux-stable
	cd ~/build && sudo rm -rf ./pristine

patch: copy_change
	cd ~/build/linux-stable && rm -f .config
	cd ~/build/linux-stable && rm -f config_sav
	cd ~/build/linux-stable && rm -f certs/signing_key.pem
	cd ~/build/linux-stable && rm -f certs/x509.genkey
	cd ~/build/linux-stable && rm -f certs/signing_key.x509
	cd ~/build/linux-stable && rm -f tools/objtool/arch/x86/insn/inat-tables.c
	cd ~/build/linux-stable && $(MAKE) clean
	cd ~/build/linux-stable && $(MAKE) mrproper
	cd ~/build/linux-stable && git add .
	cd ~/build/linux-stable && git commit -a -m 'information flow'
	cd ~/build/linux-stable && git format-patch HEAD~ -s
	rm -f ~/build/0001-information-flow.patch
	mkdir -p patches
	cp -f ~/build/linux-stable/*.patch patches/

test_patch:
	cp -f ./patches/0001-information-flow.patch ~/build/0001-information-flow.patch
	cd ~/build/pristine/linux-stable && git apply ../../0001-information-flow.patch
