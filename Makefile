kernel-version=4.13.7
arch=x86_64

all: config compile

prepare: prepare_kernel

prepare_kernel:
	mkdir -p build
	cd ./build && wget https://www.kernel.org/pub/linux/kernel/v4.x/linux-$(kernel-version).tar.xz && tar -xJf linux-$(kernel-version).tar.xz && cd ./linux-$(kernel-version) && $(MAKE) mrproper

copy_change:
	cd ./build/linux-$(kernel-version) && cp -r ../../fs .
	cd ./build/linux-$(kernel-version) && cp -r ../../include .
	cd ./build/linux-$(kernel-version) && cp -r ../../ipc .
	cd ./build/linux-$(kernel-version) && cp -r ../../mm .
	cd ./build/linux-$(kernel-version) && cp -r ../../net .
	cd ./build/linux-$(kernel-version) && cp -r ../../security .

copy_config:
	cp -f /boot/config-$(shell uname -r) .config
	cd ./build/linux-$(kernel-version) && cp ../../.config .config

config: copy_change copy_config
	cd ./build/linux-$(kernel-version) && ./scripts/kconfig/streamline_config.pl > config_strip
	cd ./build/linux-$(kernel-version) &&  mv .config config_sav
	cd ./build/linux-$(kernel-version) &&  mv config_strip .config
	cd ./build/linux-$(kernel-version) && $(MAKE) menuconfig

config_travis: copy_change copy_config
	cd ./build/linux-$(kernel-version) && ./scripts/kconfig/streamline_config.pl > config_strip
	cd ./build/linux-$(kernel-version) &&  mv .config config_sav
	cd ./build/linux-$(kernel-version) &&  mv config_strip .config
	cd ./build/linux-$(kernel-version) && $(MAKE) olddefconfig
	cd ./build/linux-$(kernel-version) && $(MAKE) oldconfig

compile: compile_kernel

compile_kernel: copy_change
	cd ./build/linux-$(kernel-version) && $(MAKE) -j4

install: install_kernel

install_kernel:
	cd ./build/linux-$(kernel-version) && sudo $(MAKE) modules_install
	cd ./build/linux-$(kernel-version) && sudo $(MAKE) install
	cd ./build/linux-$(kernel-version) && sudo cp -f .config /boot/config-$(kernel-version)

clean: clean_kernel

clean_kernel:
	cd ./build/linux-$(kernel-version) && $(MAKE) clean
	cd ./build/linux-$(kernel-version) && $(MAKE) mrproper

delete_kernel:
	cd ./build && rm -rf ./linux-$(kernel-version)
	cd ./build && rm -f ./linux-$(kernel-version).tar.xz

patch: copy_change
	cd build && mkdir -p pristine
	cd build && tar -xJf linux-$(kernel-version).tar.xz -C ./pristine
	cd build/linux-$(kernel-version) && rm -f .config
	cd build/linux-$(kernel-version) && rm -f config_sav
	cd build/linux-$(kernel-version) && rm -f certs/signing_key.pem
	cd build/linux-$(kernel-version) && rm -f certs/x509.genkey
	cd build/linux-$(kernel-version) && rm -f certs/signing_key.x509
	cd build/linux-$(kernel-version) && rm -f tools/objtool/arch/x86/insn/inat-tables.c
	cd build && rm -f patch-$(kernel-version)-information-flow
	cd build/pristine/linux-$(kernel-version) && $(MAKE) clean
	cd build/pristine/linux-$(kernel-version) && $(MAKE) mrproper
	cd ./build/linux-$(kernel-version) && $(MAKE) clean
	cd ./build/linux-$(kernel-version) && $(MAKE) mrproper
	cd ./build && diff -uprN -b -B ./pristine/linux-$(kernel-version) ./linux-$(kernel-version) > ./patch-$(kernel-version)-flow-friendly; [ $$? -eq 1 ]
	mkdir -p output
	cp -f ./build/patch-$(kernel-version)-flow-friendly ./output/patch-$(kernel-version)-flow-friendly

prepare_release_travis:
	cp -f output/patch-$(kernel-version)-flow-friendly patch
