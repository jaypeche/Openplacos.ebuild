# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils git

DESCRIPTION="This utility is used to create a low cost automation system controlled by computer"
HOMEPAGE="http://openplacos.sourceforge.net/"

EGIT_REPO_URI="git://openplacos.git.sourceforge.net/gitroot/openplacos/openplacos"
EGIT_PATCHES="${FILESDIR}/${P}-gentoo.diff"
#EGIT_BRANCH="master"
#EGIT_COMMIT="d8dc9d2a2a695ec29a2fe2f15274800612e242c5"

OPOS_PATH="/usr/lib/ruby/openplacos"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="-arduino +gtk2 -phidget -testing"

DEPEND="dev-vcs/git
	sys-apps/dbus
	dev-lang/ruby
	>=dev-ruby/rubygems-1.3.7-r1
	arduino? ( dev-embedded/arduino )
	phidget? ( dev-embedded/phidget )
	gtk2? ( dev-ruby/ruby-gnome2
	>=x11-libs/gtk+-2.20.1 )
	testing? ( dev-db/sqlite )
	!testing? ( dev-db/mysql )"

pkg_setup() {

	einfo "Ruby gem library installation"
	einfo "This could take a while.. please wait..."
	gem install rubygems-update --no-ri --no-rdoc || die "gem install failed !"

	# Default gems
	einfo "Installing default gems for opos"
	gem install activerecord mysql serialport --no-ri --no-rdoc || die "gem install failed !"

	# Ruby-dbus-openplacos gem
	einfo "Installing ruby-dbus-openplacos gem"
	gem install ruby-dbus-openplacos --no-ri --no-rdoc || die "gem install failed !"

	# OpenplacOS gem
	einfo "Installing openplacos gem"
	gem install openplacos --no-ri --no-rdoc || die "gem install failed !"

	# Micro-optparse gem (NEW)
	einfo "Installing micro-optparse gem"
	gem install micro-optparse --no-ri --no-rdoc || die "gem install failed !"

	# Sqlite3 gem
	if use testing ; then
		einfo "Installing sqlite3 gem"
		gem install sqlite3 --no-ri --no-rdoc || die "gem install failed !"
	fi
}

src_unpack () {

	# Choose branch master||unstable

	if use testing ; then
		EGIT_BRANCH="unstable" \
		&& EGIT_STORE_DIR="/usr/portage/git-src/openplacos/unstable" \
		&& EGIT_COMMIT="d8dc9d2a2a695ec29a2fe2f15274800612e242c5"
	fi
		git_src_unpack || die "src_unpack failed !"
}

src_install () {

	einfo "Copying files"
	insinto ${OPOS_PATH} || die "insinto failed !"
	doins -r * || die "doins failed !"

	einfo "Linking common executables files"

	# OPOS Server
	dohard ${OPOS_PATH}/server/Top.rb /usr/bin/openplacos-server || die "dohard failed !"
	fperms +x /usr/bin/openplacos-server || die "fperms failed !"

	# CLI Client
	dohard ${OPOS_PATH}/client/CLI_client/opos-client.rb /usr/bin/openplacos || die
	fperms +x /usr/bin/openplacos || die

	# XML-RPC Client
	dohard ${OPOS_PATH}/client/xml-rpc/xml-rpc-client.rb /usr/bin/openplacos-xmlrpc || die
	fperms +x /usr/bin/openplacos-xmlrpc || die

	# SOAP Client
	dohard ${OPOS_PATH}/client/soap/soap-client.rb /usr/bin/openplacos-soap || die
	fperms +x /usr/bin/openplacos-soap || die

	# GTK Client
	if use gtk2 ; then
		dohard ${OPOS_PATH}/client/gtk/gtk.rb /usr/bin/openplacos-gtk || die
       		fperms +x /usr/bin/openplacos-gtk || die
	fi

	einfo "Checking default drivers permissions"
	fperms a+x ${OPOS_PATH}/drivers/VirtualPlacos/VirtualPlacos.rb || die "fperms failed !"
	fperms a+x ${OPOS_PATH}/drivers/VirtualPlacos/compensation_hygro.rb || die

	einfo "Copying default configuration"
	insinto /etc/default || die "insinto failed !"
	doins server/config_with_VirtualPlacos.yaml || die "doins failed"
	mv -f ${D}/etc/default/config_with_VirtualPlacos.yaml ${D}/etc/default/openplacos || die "mv config failed !"
	dosym /etc/default/openplacos /etc/conf.d/openplacos || die "dosym failed !"

	einfo "Copying Dbus integration files"
	insinto /usr/share/dbus-1/system-services || die "insinto failed !"
	doins setup_files/*.service || die "doins failed !"
	insinto /etc/dbus-1/system.d || die
	doins setup_files/openplacos.conf || die

	einfo "Copying daemon file"
	insinto /etc/init.d || die "insinto failed !"
	doins setup_files/openplacos || die "doins failed !"
	fperms +x /etc/init.d/openplacos || die "fperms failed !"

	einfo "Installing Gentoo Linux documentation"
	dodoc INSTALL_GENTOO || die "dodoc failed !"
}

pkg_postinst() {

	# Adding openplacos user in following groups
	enewuser openplacos -1 -1 -1 usb,dialout

	einfo "Reloading dbus"
	/etc/init.d/dbus reload

	if use !testing; then
		einfo
		einfo "Before running OpemplacOS for first time"
		einfo "You should proceed your database configuration"
		einfo "Please provide MySQL root password"
		einfo
		einfo "# mysql -u root -p < /usr/lib/ruby/openplacos/setup_files/install.sql"
		einfo "# /etc/init.d/mysql start"
		einfo "# rc-update add mysql default"
	fi
	einfo
	einfo "Start OpenplacOS daemon"
	einfo "# /etc/init/openplacos start"
	einfo "# rc-update add openplacos default"
	einfo
	einfo "Now, you can launch GTK Client for example"
	einfo "$ /usr/bin/openplacos-gtk"
	einfo
	einfo "Look at http://openplacos.sourceforge.net/ for more information"
	einfo
}
