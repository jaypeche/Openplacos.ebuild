# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils git-2

DESCRIPTION="This utility is used to create a low cost home automation system controlled by computer"
HOMEPAGE="http://openplacos.tuxfamily.org/"

EGIT_REPO_URI="git://github.com/openplacos/openplacos.git"
EGIT_BRANCH="master"
EGIT_COMMIT="a68afd6621dc8db2672f5ab3561c895d1387d76f"

OPOS_PATH="/usr/lib/ruby/openplacos"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="x86 amd64"
IUSE="-arduino -debug -gtk2"

DEPEND="dev-vcs/git
	sys-apps/dbus
	dev-lang/ruby
	dev-db/mysql
	>=dev-ruby/rubygems-1.3.7-r1
	arduino? ( dev-embedded/arduino )
	gtk2? ( dev-ruby/ruby-gnome2
	>=x11-libs/gtk+-2.20.1 )"

src_unpack () {
	git-2_src_unpack ${A}
		cd "${S}"
		if use debug; then
			epatch "${FILESDIR}/${P}-debug.diff" || die "epatch failed !"
		fi
}

src_install () {

	# Copying files
	einfo
	einfo "Copying files"
	insinto ${OPOS_PATH} || die "insinto failed !"
	cp -dpR * ${D}/${OPOS_PATH} || die "copy failed !"

	# Ruby on Rails files (TODO: fix upstream)
	dodir ${OPOS_PATH}/plugins/rorplacos/tmp || die "dodir failed !"
	dodir ${OPOS_PATH}/plugins/rorplacos/log || die
	#fowners -R openplacos /usr/lib/ruby/openplacos/plugins/rorplacos/tmp || die "fowners failed !"
	#fowners -R openplacos /usr/lib/ruby/openplacos/plugins/rorplacos/log || die

	einfo "Linking common executables files"
	# OPOS Server
	dohard ${OPOS_PATH}/server/main.rb /usr/bin/openplacos-server || die
	fperms +x /usr/bin/openplacos-server || die

	# CLI Client
	dohard ${OPOS_PATH}/clients/CLI_client/opos-client.rb /usr/bin/openplacos || die
	fperms +x /usr/bin/openplacos || die

	# XML-RPC Client
	dohard ${OPOS_PATH}/clients/xml-rpc/xml-rpc-client.rb /usr/bin/openplacos-xmlrpc || die
	fperms +x /usr/bin/openplacos-xmlrpc || die

	# SOAP Client
	dohard ${OPOS_PATH}/clients/soap/soap-client.rb /usr/bin/openplacos-soap || die
	fperms +x /usr/bin/openplacos-soap || die

	# GTK Client
	if use gtk2 ; then
		dohard ${OPOS_PATH}/clients/deprecated/gtk/gtk.rb /usr/bin/openplacos-gtk || die
		fperms +x /usr/bin/openplacos-gtk || die
	fi

	einfo "Checking default drivers permissions"
	fperms a+x ${OPOS_PATH}/drivers/VirtualPlacos/VirtualPlacos.rb || die "fperms failed !"
	fperms a+x ${OPOS_PATH}/drivers/VirtualPlacos/compensation_hygro.rb || die

	einfo "Copying default configuration"
	insinto /etc/default || die "insinto failed !"
       	doins server/config_with_VirtualPlacos_and_RoR.yaml || die "doins failed"
       	mv -f ${D}/etc/default/config_with_VirtualPlacos_and_RoR.yaml ${D}/etc/default/openplacos || die "mv config failed !"
       	dosym /etc/default/openplacos /etc/conf.d/openplacos || die "dosym failed !"

	einfo "Copying Dbus integration files"
	insinto /usr/share/dbus-1/system-services || die "insinto failed !"
	doins setup_files/*.service || die "doins failed !"
	insinto /etc/dbus-1/system.d || die
	doins setup_files/openplacos.conf || die
	insinto /etc/udev/rules.d/ || die
	doins setup_files/10-openplacos.rules || die

	einfo "Copying daemon file"
	insinto /etc/init.d || die "insinto failed !"
	doins setup_files/openplacos || die "doins failed !"
	fperms +x /etc/init.d/openplacos || die "fperms failed !"
}

pkg_postinst() {

	# Gems Bundler install for opos
        einfo
        einfo "OpenplacOS bundle install"
        einfo "This could take a while.. please wait..."
        gem install bundler --bindir /usr/bin --no-ri --no-rdoc ||  die "gem install failed !"
        cd ${OPOS_PATH} && bundle install || die "bundle install failed !"

        einfo
        einfo "Rails bundle install"
        einfo "This could take a while.. please wait..."
        cd ${OPOS_PATH}/plugins/rorplacos/ && bundle install || die "bundle install failed !"

	# Adding openplacos user and dialout group
	einfo
	einfo "Creating group and user for openplacos"

	if grep "^dialout" /etc/group > /dev/null
		then ewarn "Oops, dialout group already exists !"
			else
		enewgroup dialout || die "enewgroup failed !"
	fi

	if grep "^openplacos" /etc/passwd > /dev/null
		then ewarn "Oops, openplacos user already exists !"
			else
		enewuser openplacos -1 -1 -1 dialout,usb || die "enewuser failed !"
	fi

	einfo
	einfo "Reloading dbus config"
	/etc/init.d/dbus reload > /dev/null || die "reloading dbus failed !"

	einfo
	einfo "Before running OpemplacOS for first time"
	einfo "You should proceed your database configuration"
	einfo "Please provide MySQL root password"
	einfo
	einfo "# /usr/bin/mysqladmin -u root -h localhost password 'new-password'"
	einfo
	einfo "# /etc/init.d/mysql start"
	einfo "# mysql -u root -p < /usr/lib/ruby/openplacos/setup_files/install.sql"
	einfo "# rc-update add mysql default"

	einfo
	einfo "Start OpenplacOS daemon"
	einfo "# /etc/init.d/openplacos start"
	einfo "# rc-update add openplacos default"

	if use gtk2 ; then
		einfo
		einfo "Now, you can launch GTK client for example"
		einfo "$ /usr/bin/openplacos-gtk"
	else
		einfo
		einfo "Now, you can launch web interface for example,"
		einfo "URL: http://localhost:3000/login"
	fi

	einfo
	einfo "Look at http://openplacos.tuxfamily.org for more information"
	einfo
}
