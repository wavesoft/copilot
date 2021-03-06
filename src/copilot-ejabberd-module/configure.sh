#!/bin/bash
LOC=`pwd`
EJD_DIR=$EJD_DIR
ERL_DIR=`echo "code:lib_dir()." | erl | grep "1>" | cut -d '"' -f2`

if [ ! -e "$EJD_DIR" ]; then
	EJD_DIR=/lib/ejabberd
fi

echo " - ejabberd: $EJD_DIR"
echo " - Erlang: $ERL_DIR"
echo

echo " * Generating Makefile..."
cat > Makefile << EOF
REBAR ?= \$(shell which rebar 2>/dev/null || which ./rebar)
REBAR_FLAGS ?=

all: build-deps compile

compile:
	erlc -I $EJD_DIR/include -o ebin src/*.erl

install:
	cp -R ebin/*.beam $EJD_DIR/ebin

build-deps:
	\$(REBAR) get-deps \$(REBAR_FLAGS)
	cd deps/egeoip && make
	cd deps/mochiweb && make

install-deps: build-deps
	mkdir -p $ERL_DIR/egeoip-master
	cp -R deps/egeoip/{ebin,include,priv} $ERL_DIR/egeoip-master

	mkdir -p $ERL_DIR/mochiweb-master
	cp -R deps/mochiweb/{ebin,include} $ERL_DIR/mochiweb-master

clean:
	\$(REBAR) clean \$(REBAR_FLAGS)
EOF

echo " * Generating rebar.config..."
cat > rebar.config << EOF
{deps, [
				{egeoip, ".*", {git, "http://github.com/mochi/egeoip.git", "HEAD"}},
				{mochiweb, ".*", {git, "http://github.com/mochi/mochiweb.git", "HEAD"}}
			 ]}.
{lib_dirs, ["deps"]}.
{erl_opts, [debug_info,
						fail_on_warning,
						{i, "$EJD_DIR/include"}
					 ]}.
{clean_files, ["ebin/*.beam", "erl_crash.dump"]}.
EOF

echo " * Done. Run 'make build-deps && sudo make install-deps && make compile && sudo make install' to install the module."
