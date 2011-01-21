# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header:

EAPI="2"

inherit eutils git

DESCRIPTION="OpenplacOS is enrichied in Glouton's Enzymes"
HOMEPAGE="http://openplacos.sourceforge.net/"

EGIT_REPO_URI="git://openplacos.git.sourceforge.net/gitroot/openplacos/openplacos"
EGIT_BRANCH="master"
EGIT_PATCHES="${FILESDIR}/${P}-gentoo.diff"
#EGIT_COMMIT="6a0004a8bb25c6108c25a16c9d78c14137f32d9f"
OPOS_PATH="/usr/lib/ruby/openplacos"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="gnome nagios"

DEPEND="dev-vcs/git
	sys-apps/dbus
	dev-lang/ruby
	>=dev-ruby/rubygems-1.3.7-r1
	dev-db/mysql
	gnome?  ( dev-ruby/ruby-gnome2
		>=x11-libs/gtk+-2.20.1 )
	nagios? ( net-analyzer/nagios )"

pkg_setup() {
	einfo "Ruby gem library installation"
	einfo "This could take a while.. please wait..."
	gem install rubygems-update --no-ri --no-rdoc || die "gem install failed !"
	#update_rubygems || die "gem update failed !"
	#gem update --no-ri --no-rdoc || die "gem update failed !"
	gem install openplacos ruby-dbus --no-ri --no-rdoc || die "gem install failed !"
}

src_unpack () {
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

	enewuser openplacos || die
	einfo
	einfo "URL administration: http://localhost/openplacos/"
	einfo "You should start OpenplacOS service ..!"
	einfo "Execute /etc/init/openplacos start"
	einfo "And rc-update add openplacos default"
	einfo
	einfo "Look at http://openplacos.sourceforge.net/ for more information"
	einfo
}
