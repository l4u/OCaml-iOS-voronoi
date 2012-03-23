PLAT = /Developer/Platforms/iPhoneSimulator.platform
SDK = /Developer/SDKs/iPhoneSimulator4.2.sdk
PLATAPPS = $(PLAT)/Developer/Applications
OCAMLDIR = /usr/local/ocamlxsim
OCAMLBINDIR = $(OCAMLDIR)/bin/
CC = $(PLAT)/Developer/usr/bin/gcc-4.2
CFLAGS = -arch i386 -isysroot $(PLAT)$(SDK) -gdwarf-2 \
	-D__IPHONE_OS_VERSION_MIN_REQUIRED=30200 \
	-isystem $(OCAMLDIR)/lib/ocaml -DCAML_NAME_SPACE
MFLAGS = -fobjc-legacy-dispatch -fobjc-abi-version=2
LDFLAGS = -Xlinker -objc_abi_version -Xlinker 2

MOBS = ViewDelegator.o wrap.o main.o
MLOBS = wrapper.cmx wrappee.cmx cocoa.cmx uiKit.cmx uiFont.cmx \
    uiBezierPath.cmx uiView.cmx uiActionSheet.cmx uiApplication.cmx \
    bzpdata.cmx bzpdraw.cmx colorfield.cmx vorocells.cmx voronoictlr.cmx

all: Voronoi Voronoi.nib Info.plist PkgInfo

Voronoi: $(MOBS) $(MLOBS)
	$(OCAMLBINDIR)ocamlopt -cc '$(CC)' -ccopt '$(CFLAGS)' \
	    -cclib '$(LDFLAGS)' \
	    -o Voronoi \
	    $(MOBS) $(MLOBS) \
	    -cclib '-framework UIKit' \
	    -cclib '-framework Foundation'

execute: all
	$(PLATAPPS)/iPhone\ Simulator.app/Contents/MacOS/iPhone\ Simulator \
		-SimulateApplication Voronoi &

Voronoi.nib: Voronoi.xib
	ibtool --compile Voronoi.nib Voronoi.xib


PkgInfo:
	echo -n 'APPL????' > PkgInfo

clean:
	rm -rf Voronoi Voronoi.nib PkgInfo build *.o *.cm[iox]

%.o: %.m
	$(CC) $(CFLAGS) $(MFLAGS) -c $<

%.cmi: %.mli
	$(OCAMLBINDIR)ocamlc -c $<

%.cmo: %.ml
	$(OCAMLBINDIR)ocamlc -c $<

%.cmx: %.ml
	$(OCAMLBINDIR)ocamlopt -cc '$(CC)' -ccopt '$(CFLAGS)' -c $<

depend::
	$(OCAMLBINDIR)ocamldep *.ml *.mli > MLDepend
	$(CC) $(CFLAGS) -MM *.m > MDepend

-include MLDepend
-include MDepend
