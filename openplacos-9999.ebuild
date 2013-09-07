# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils git-2

DESCRIPTION="This utility is used to create a low cost home automation system controlled by computer"
HOMEPAGE="http://openplacos.tuxfamily.org/"

EGIT_REPO_URI="git://github.com/openplacos/openplacos.git"
EGIT_BRANCH="unstable"
OPOS_PATH="/usr/lib/ruby/openplacos"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="-arduino -debug -gtk2"

DEPEND="dev-vcs/git
	sys-apps/dbus
	>=dev-lang/ruby-1.9.3
	>=dev-db/sqlite-3.7.12
	>=dev-ruby/rubygems-1.3.7-r1
	arduino? ( dev-embedded/arduino )
	gtk2? ( dev-ruby/ruby-gnome2
	>=x11-libs/gtk+-2.20.1 )"

pkg_setup() {
	enewgroup dialout
	enewuser openplacos -1 -1 -1 dialout,uucp --system
}

src_unpack () {
	git-2_src_unpack ${A}
		cd "${S}"
		epatch "${FILESDIR}/${P}-gentoo.diff"
}

src_install () {
        einstall || die "einstall failed"
}

pkg_postinst() {
        # Gems Bundler install for opos
        einfo
        einfo "OpenplacOS bundle install"
        einfo "This could take a while.. please wait..."
        gem install bundler --bindir /usr/bin --no-ri --no-rdoc ||  die "gem install"
        cd ${OPOS_PATH} && bundle install || die "bundle install failed !"
	einfo
	einfo "Bundle install deployment"
	einfo "This could take a while, please wait..."
#	bundle install --deployment || die

	# Fix permissions (upstream?)
	fowners openplacos ${OPOS_PATH}/server/tmp

	einfo
	einfo "You should run OpenplacOS like this,"
        einfo "# /etc/init.d/openplacos start"
        einfo "# rc-update add openplacos default"
	einfo
	einfo "Now, you can launch web interface for example,"
	einfo "URL: http://localhost:4567/"
	einfo
	einfo "Look at http://openplacos.tuxfamily.org for more information"
	einfo
}

