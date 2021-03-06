# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils git

DESCRIPTION="OpenplacOS is enrichied in Glouton's Enzymes"
HOMEPAGE="http://openplacos.sourceforge.net/"

EGIT_REPO_URI="git://openplacos.git.sourceforge.net/gitroot/openplacos/openplacos"
EGIT_PATCHES="${FILESDIR}/${P}-gentoo.diff"

# This is an example :
#EGIT_BRANCH="master"
#EGIT_COMMIT="6a0004a8bb25c6108c25a16c9d78c14137f32d9f"

OPOS_PATH="/usr/lib/ruby/openplacos"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="gnome multithread mysql nagios -phidget +sqlite3 -testing"

DEPEND="dev-vcs/git
	sys-apps/dbus
	dev-lang/ruby
	>=dev-ruby/rubygems-1.3.7-r1
	phidget? ( dev-embedded/phidget )
	mysql?  ( dev-db/mysql )
	gnome?  ( dev-ruby/ruby-gnome2
		>=x11-libs/gtk+-2.20.1 )
	nagios? ( net-analyzer/nagios )"

pkg_setup() {
	einfo "Ruby gem library installation"
	einfo "This could take a while.. please wait..."
	gem install rubygems-update --no-ri --no-rdoc || die "gem install failed !"

	einfo "Installing default gems for opos"
	gem install activerecord mysql serialport --no-ri --no-rdoc || die "gem install failed !"

	# Ruby-dbus multithread support
	#
	# Bugfix(20110124) :	branch : multithreading origin/multithreading
	#			at commit 89843b67e85a941317049d523a545042a4fddb07

	if use multithread ; then
		einfo "Installing ruby-dbus multithread branch"
		cd ${T}
		einfo "Cloning files"
		git clone git://github.com/mvidner/ruby-dbus.git || die "git clone failed !"
		cd ${T}/ruby-dbus
		einfo "Ckecking multithreading"
		git checkout -b multithreading origin/multithreading
		git reset --hard 89843b67e85a941317049d523a545042a4fddb07
		einfo "Genrating gem"
		rake gem || die "rake failed !"
		einfo "Installing gem"
		gem install ${T}/ruby-dbus/pkg/*.gem --no-ri --no-rdoc || die "gem install failed !"
	else
		ewarn "Installing ruby-dbus with gem method"
		gem install ruby-dbus --no-ri --no-rdoc || die "gem install failed !"
	fi

	# Ruby sqlite3 support
	if use sqlite3 ; then
		einfo "Installing sqlite3 gem"
		gem install sqlite3 --no-ri --no-rdoc || die "gem install failed !"
	fi

	# This is obsolete with rubygems > 1.3.6
	# update_rubygems || die "gem update failed !"
	# gem update --no-ri --no-rdoc || die "gem update failed !"
}

src_unpack () {

	# Choose branch master||unstable
	if use testing ; then
		EGIT_BRANCH="unstable" \
		&& EGIT_STORE_DIR="/usr/portage/git-src/openplacos/unstable" \
		&& EGIT_COMMIT="unstable"
	fi
		git_src_unpack || die "src_unpack failed !"
}

src_install () {

	einfo "Copying files"
	insinto ${OPOS_PATH} || die "insinto failed !"
	doins -r * || die "doins failed !"

	einfo "Linking executables files"
        dohard ${OPOS_PATH}/server/Top.rb /usr/bin/openplacos-server || die "dohard failed !"
        fperms +x /usr/bin/openplacos-server || die "fperms failed !"
	dohard ${OPOS_PATH}/client/CLI_client/opos-client.rb /usr/bin/openplacos || die
        fperms +x /usr/bin/openplacos || die

	if use !testing ; then

	dohard ${OPOS_PATH}/client/IHMlocal/IHM.rb /usr/bin/openplacos-gtk || die
        fperms +x /usr/bin/openplacos-gtk || die
	dohard ${OPOS_PATH}/client/xml-rpc/client/xml-rpc-client.rb  /usr/bin/openplacos-xmlrpc || die
        fperms +x /usr/bin/openplacos-xmlrpc || die
	dohard ${OPOS_PATH}/client/soap/client/soap-client.rb  /usr/bin/openplacos-soap || die
        fperms +x /usr/bin/openplacos-soap || die
	dohard ${OPOS_PATH}/client/xml-rpc/server/xml-rpc-server.rb  /usr/bin/openplacos-server-xmlrpc || die
        fperms +x /usr/bin/openplacos-server-xmlrpc || die
	dohard ${OPOS_PATH}/client/soap/server/soap-server.rb  /usr/bin/openplacos-server-soap || die
        fperms +x /usr/bin/openplacos-server-soap || die

	else
	ewarn "WARNING! Plugins was not installated in testing mode"
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
	fperms 755 /etc/init.d/openplacos || die "fperms failed !"

	einfo "Installing Gentoo Linux documentation"
	dodoc INSTALL_GENTOO || die "dodoc failed !"
}

pkg_postinst() {

	# Adding openplacos user in following groups
	enewuser openplacos -1 -1 -1 usb,dialout
	einfo
	einfo "URL administration: http://localhost:8081/openplacos/"
	einfo "You should start OpenplacOS service ..!"
	einfo "Execute /etc/init/openplacos start"
	einfo "And rc-update add openplacos default"
	einfo
	einfo "Look at http://openplacos.sourceforge.net/ for more information"
	einfo
}
