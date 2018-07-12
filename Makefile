kernel-version=4.17.6
arch=x86_64

all: config compile

prepare: prepare_kernel

prepare_kernel:
	mkdir -p build
	cd ./build && git clone -b v$(kernel-version) --single-branch git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
	cd ./build/linux-stable && $(MAKE) mrproper
	cd ./build && mkdir -p pristine
	cd ./build && cp -r ./linux-stable ./pristine

copy_change:
	cd ./build/linux-stable && cp -r ../../fs .
	cd ./build/linux-stable && cp -r ../../include .
	cd ./build/linux-stable && cp -r ../../ipc .
	cd ./build/linux-stable && cp -r ../../mm .
	cd ./build/linux-stable && cp -r ../../net .
	cd ./build/linux-stable && cp -r ../../security .

copy_config:
	cp -f /boot/config-$(shell uname -r) .config
	cd ./build/linux-stable && cp ../../.config .config

config: copy_change copy_config
	cd ./build/linux-stable && ./scripts/kconfig/streamline_config.pl > config_strip
	cd ./build/linux-stable &&  mv .config config_sav
	cd ./build/linux-stable &&  mv config_strip .config
	cd ./build/linux-stable && $(MAKE) menuconfig

config_travis: copy_change copy_config
	cd ./build/linux-stable && ./scripts/kconfig/streamline_config.pl > config_strip
	cd ./build/linux-stable &&  mv .config config_sav
	cd ./build/linux-stable &&  mv config_strip .config
	cd ./build/linux-stable && $(MAKE) olddefconfig
	cd ./build/linux-stable && $(MAKE) oldconfig

config_travis_off:
	cd ./build/linux-stable && sed -i -e "s/CONFIG_SECURITY_FLOW_FRIENDLY=y/CONFIG_SECURITY_FLOW_FRIENDLY=n/g" .config
	cd ./build/linux-stable &&$(MAKE) oldconfig

compile: compile_kernel

compile_kernel: copy_change
	cd ./build/linux-stable && $(MAKE) -j16

compile_security: copy_change
	cd ./build/linux-stable && $(MAKE) security W=1 -j16

install: install_kernel

install_kernel:
	cd ./build/linux-stable && sudo $(MAKE) modules_install
	cd ./build/linux-stable && sudo $(MAKE) install
	cd ./build/linux-stable && sudo cp -f .config /boot/config-$(kernel-version)

clean: clean_kernel

clean_kernel:
	cd ./build/linux-stable && $(MAKE) clean
	cd ./build/linux-stable && $(MAKE) mrproper

delete_kernel:
	cd ./build && rm -rf ./linux-stable
	cd ./build && rm -rf ./pristine

patch: copy_change
	cd build/linux-stable && rm -f .config
	cd build/linux-stable && rm -f config_sav
	cd build/linux-stable && rm -f certs/signing_key.pem
	cd build/linux-stable && rm -f certs/x509.genkey
	cd build/linux-stable && rm -f certs/signing_key.x509
	cd build/linux-stable && rm -f tools/objtool/arch/x86/insn/inat-tables.c
	cd build && rm -f patch-$(kernel-version)-information-flow
	cd build/pristine/linux-stable && $(MAKE) clean
	cd build/pristine/linux-stable && $(MAKE) mrproper
	cd ./build/linux-stable && $(MAKE) clean
	cd ./build/linux-stable && $(MAKE) mrproper
	cd ./build && diff -uprN -b -B ./pristine/linux-stable ./linux-stable > ./patch-$(kernel-version)-flow-friendly; [ $$? -eq 1 ]
	mkdir -p output
	cp -f ./build/patch-$(kernel-version)-flow-friendly ./output/patch-$(kernel-version)-flow-friendly

test_patch:
	cd ./build/pristine/linux-stable && patch -p2 < ../../patch-$(kernel-version)-flow-friendly

prepare_release_travis:
	cp -f output/patch-$(kernel-version)-flow-friendly patch
