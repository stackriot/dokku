module github.com/dokku/dokku/plugins/builder

go 1.15

require (
	github.com/codegangsta/inject v0.0.0-20150114235600-33e0aa1cb7c0
	github.com/codeskyblue/go-sh v0.0.0-20190412065543-76bd3d59ff27
	github.com/dokku/dokku/plugins/common v0.0.0-00010101000000-000000000000
	github.com/otiai10/copy v1.6.0
	github.com/spf13/pflag v1.0.5 // indirect
)

replace github.com/dokku/dokku/plugins/common => ../common
