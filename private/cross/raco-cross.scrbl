#lang scribble/manual
@(require (for-label racket/base)
          scribble/bnf)

@(define raco-scrbl '(lib "scribblings/raco/raco.scrbl"))
@(define raco-exe @seclink[#:doc raco-scrbl "exe"]{@exec{raco exe}})
@(define raco-dist @seclink[#:doc raco-scrbl "exe-dist"]{@exec{raco dist}})

@title{Cross-Compilation and Multi-Version Manager: @exec{raco cross}}

The @exec{raco cross} command (implemented in the
@filepath{raco-cross} package) provides a convenient interface to
cross-compilation for Racket. It's especially handy generating
executables that run on platforms other than the one used to create
the executable.

For example,
<
@commandline{raco cross --target x86_64-linux exe example.rkt}

creates an executable named @filepath{example} that runs on x86_64
Linux. That is, it sets up a combination of distributions for the
current platform and for the @tt{x86_64-linux} platform, and it runs
@|raco-exe| as if from the local @tt{x86_64-linux} installation.

@margin-note{For Racket CS, cross-building executables works for
             version 8.1.0.6 and later. For Racket BC, cross-build
             executables works for 7.0 and later. The specific
             platforms available as cross-compilation targets depends
             on the set of distributions that are available from an
             installer site.}

The generated @filepath{example} executable is not necessarily
portable by itself to other machines. As is generally the case with
@|raco-exe|, the executable needs to be turned into a distribution with
@|raco-dist| (which is also supplied by the @filepath{compiler-lib}
package):

@commandline{raco cross --target x86_64-linux dist example-dist example}

The result directory @filepath{example-dist} is then ready to be
copied to a x86_64 Linux machine and run there.

Since @exec{raco cross} depends on facilities for managing Racket
implementations for different versions and platforms, it can also act
as a launcher for a selected native implementation of Racket. For
example,

@commandline{raco cross --version 7.8 racket}

installs and runs a minimal installation of Racket version 7.8 for the
current platform (assuming that the combination of version, platform,
and virtual machine is available).

Use the @DFlag{native} flag to create an installation for a platform
other than the current machine's default, but where the current
machine can run executables directly. For example, on Windows where
@exec{raco} runs a 64-bit Racket build,

@commandline{raco cross --native --platform i383-win32 --vm bc racket}

installs and runs a 32-bit build of Racket BC for Windows and runs it
directly.

@; ----------------------------------------
@section{Platforms, Versions, and Workspaces for @exec{raco cross}}

The @exec{raco cross} command takes care of the following tasks:

@itemlist[

 @item{Downloads minimal Racket installations as needed for a given
       combination of operating system, architecture, Racket virtual
       machine (CS versus BC), and version.

       By default, @exec{raco cross} downloads from the main Racket
       mirror for release distributions, but you can point @exec{raco
       cross} to other sites (such as one of the snapshot sites at
       @url{https://snapshot.racket-lang.org} that includes
       @filepath{.tgz} options) using @DFlag{installers}.}

 @item{Configures the minimal Racket installation to install new
       packages in @exec{installation} scope by default.}

 @item{Configures the minimal Racket installation to compile to
       machine-independent form if @DFlag{compile-any} is specified or
       @exec{any} is used as the target platform.}

 @item{Installs the @filepath{compiler-lib} package so that @exec{raco
       exe} is available, unless @DFlag{skip-pkgs} is specified to keep
       the installation minimal.}

 @item{Generates a cross-compiler plug-in from Racket sources for the
       CS variant of Racket. (No extra cross-compilation plugin is
       needed for BC or for native installations.)}

 @item{Chains to @exec{racket} or @exec{raco} for the target version
       and virtual machine---running a native executable, but
       potentially in cross-compilation mode for a target that is a
       different operating system and/or architecture.}

]

The version and CS/BC variant of Racket where @filepath{raco-cross} is
installed and run doesn't need to be related to the target version and
variant. The @exec{raco cross} command will download and install a
version and variant of Racket for the current machine as needed.

The Racket distributions that are downloaded and managed by @exec{raco
cross} are installed in a @deftech{workspace} directory. By default,
the workspace directory is @racket[(build-path (find-system-path
'addon-dir) "raco-cross" _vers)] where @racket[_vers] is the specified
version. The workspace directory is independent of the Racket
installation that is used to run @exec{raco cross}.

When building for a given target, often packages need to be installed
via @exec{raco cross} only for that target. In some cases, however,
compilation may require platform-specific native libraries, and
the packages must also be installed for the host platform via
@exec{raco cross} (with no @DFlag{target} flag). For example, if
compiling a module requires rendering images at compile time, then
@;
@commandline{raco cross pkg install draw-lib}
@;
most likely will be needed to install the packages for the current
machine, as well as
@;
@commandline{raco cross --target @nonterm{target} pkg install draw-lib}
@;
to install for the @nonterm{target} platform.

Cross-compilation support depends on having suitable distributions for
both the host platform and the target platform. (Use @DFlag{browse} to
check which are available, and see also @secref["build-your-own"].)
Some operating systems
support more than one platform at a time, and it may be necessary to
select a specific host platform to work with a particular target
platform. For example, Mac OS on Apple Silicon can run both
@tt{aarch64-macosx} and @tt{x86_64-macosx} natively, and distribution
bundles for Racket BC tend to be available only for
@tt{x86_64-macosx}, so @exec{--target x86_64-win32 --vm bc} may
require @exec{--host x86_64-macosx}. The @DFlag{host} for a
combination of target platform, virtual machine, and version is
recorded when the target distribution is installed, so @DFlag{host} is
needed only the first time. If the host distribution is already
installed, it must be installed as a native distribution.

@; ----------------------------------------
@section{Running @exec{raco cross}}

The general form to run @exec{raco cross} is
@;
@commandline{raco cross @nonterm{option} @elem{...} @nonterm{command} @nonterm{arg} @elem{...}}
@;
which is analogous to running
@;
@commandline{raco @nonterm{command} @nonterm{arg} @elem{...}}
@;
but with a cross-compilation mode selected by the @nonterm{option}s.
As a special case, @nonterm{command} can be @exec{racket}, which is
analogous to running just @exec{racket} instead of @exec{raco racket}.
Finally, you can omit the @nonterm{command} and @nonterm{arg}s,
in which case @exec{raco cross} just downloads and prepares the
workspace's distribution for the target configuration. A target
configuration is a combination of platform, version, virtual machine,
and whether compiling to machine-independent form.

The following @nonterm{options} are recognized:

@itemlist[

 @item{@DFlag{target} @nonterm{platform} --- Selects the target
       platform. The @nonterm{platform} can have any of the following
       forms:

        @itemlist[

          @item{The concatenation of the string form of the symbols
                returned by @racket[(system-type 'arch)] and @racket[(system-type 'os)]
                on the target platform, with a @racket["-"] in between.
                Some common alternative spellings of the @racket[(system-type 'arch)]
                and @racket[(system-type 'os)] results are also recognized.

                Examples: @exec{i386-win32}, @exec{aarch64-macosx}, @exec{ppc-linux}}

          @item{The string form of the path returned on the target platform by
                @racket[(system-library-subpath #f)].

                These are mostly the same as the previous case, but also include
                @exec{win32\i386} and @exec{win32\x86_64}.}

          @item{The string form of the symbol that is the default
                value of @racket[current-compile-target-machine] for
                the CS implementation of Racket on the target platform.

                Examples: @exec{ti3nt}, @exec{tarm64osx}, @exec{ppc32le}}

          @item{The string @exec{any}, which is equivalent to the host platform
                by also specifying @DFlag{compile-any}.}

        ]

       The default target platform is the host platform.}

 @item{@DFlag{host} @nonterm{platform} --- Selects the platform to run
       natively as needed for cross-compiling to the target platform.
       The possible values for @nonterm{platform} are the same as for
       @DFlag{target}, except that @exec{any} is not allowed as a
       host.

       The default host platform is inferred from the Racket
       implementation that is used to run @exec{raco cross}. The host
       setting for a target platform is recorded when the distribution
       for the target configuration is
       installed into the workspace, so it needs to use specified only
       the first time the target is selected.}

 @item{@DFlag{version} @nonterm{vers} --- Selects the Racket version to
       use for the target machine.

       The default version is based on the Racket version used to run
       @exec{raco cross}, but if that version has a fourth
       @litchar{.}-separated component, then it is dropped, and a
       third component is dropped if it is @litchar{0}.

       The version @exec{current} might be useful with a snapshot
       download site, but only with a fresh workspace directory each
       time the snapshot site's @exec{current} build changes.}

 @item{@DFlag{native} --- Specifies that the target platform runs
       natively on the current machine, so cross-compilation mode is
       not needed.

       Native mode is inferred when the target platform is the same as
       the target platform. Otherwise, the @DFlag{native} setting is
       recorded when the distribution for the target configuration
       is installed into the workspace,
       so it needs to be specified only the first time the target is
       selected.}

 @item{@DFlag{vm} @nonterm{variant} --- Selects the Racket
       virtual-machine implementation to use for the target machine,
       either @exec{cs} or @exec{bc}.

       The default matches the Racket implementation that is used to
       run @exec{raco cross}.

       Beware that only some combinations of platform and Racket
       implementation are available from installer sites.}

 @item{@DFlag{compile-any} or @Flag{M} --- Selects a configuration of
       the target platform that compiles bytecode to
       machine-independent form. When @exec{any} is used as a target,
       @DFlag{compile-any} is redundant but harmless.

       A @DFlag{compile-any} configuration is most useful for using
       @exec{raco make} to create machine-independent bytecode.}

 @item{@DFlag{workspace} @nonterm{dir} --- Uses @nonterm{dir} as the
       workspace directory.

       The default workspace directory depends on the target version
       @nonterm{vers}: @racket[(build-path (find-system-path
       'addon-dir) "raco-cross" @#,nonterm{vers})].}

  @item{@DFlag{installers} @nonterm{url} --- Specifies the site for
        downloading minimal Racket distributions. A @filepath{.tgz}
        file name is added to the end of @nonterm{url} for
        downloading.

        The installers URL is needed only when a target configuration
        is specified for the first time for a given workspace. The
        name of the file to download is constructed based on the
        version, target machine, and virtual-machine implementation,
        and that file name is added to the end of @nonterm{url}, but
        the file name can be overridden through @DFlag{archive}.

        The default @nonterm{url} is @exec{https://mirror.racket-lang.org/installers/@nonterm{vers}/}.}

  @item{@DFlag{archive} @nonterm{filename} --- Overrides the archive
        to use when downloading for the target platform.}

  @item{@DFlag{skip-pkgs} --- Disables installation of the
        @filepath{compiler-lib} package when installing a new
        distribution.

        The @filepath{compiler-lib} package is installed by default so
        that @exec{raco cross @elem{....} exe @elem{...}} and
        @exec{raco cross @elem{....} dist @elem{...}} will work for
        the installed target.}

  @item{@DFlag{skip-setup} --- Skips the @exec{raco setup} step of
        some distribution installations.

        Beware that skipping @exec{raco setup} may produce an
        installation that runs slowly by loading from
        machine-independent compiled files, but @DFlag{skip-setup} may
        be useful for working around bugs in old distributions. Also,
        @DFlag{skip-setup} usually should be paired with
        @DFlag{skip-pkgs}.}

  @item{@Flag{j} @nonterm{n} or @DFlag{jobs} @nonterm{n} --- Uses
        @nonterm{n} parallel jobs for setup actions when installing a
        new distribution, including the initial package install if
        @DFlag{skip-pkgs} is not specified.}

  @item{@DFlag{use-source} --- Build a host installation from source.

        When a host installation is not already available for the
        target version and virtual machine, build it from a Racket
        source distribution, which requires tools such as a C compiler
        and GNU @exec{make}. Building from source is currently
        supported only for Unix-like host platforms. The result of
        building on the current machine is assumed to produce
        executables matching the intended host; supply
        @DPFlag{configure} arguments as necessary to configure the
        build.}

  @item{@DPFlag{configure} --- Adds an argument to the list of
        arguments that are passed to the Racket @exec{configure}
        script when building a host installation from source.

        These flags are used only with @DFlag{use-source}. For
        information about available @exec{configure} arguments, see
        @filepath{README} files in a Racket source distribution.}

  @item{@DFlag{quiet} or @Flag{q} --- Suppresses a description of the
        selected host and target configurations that would otherwise
        print as @exec{raco cross} starts.}

  @item{@DFlag{remove} --- Removes any existing installation in the
        workspace for the target configuration.

        When @DFlag{remove} is specified, no @nonterm{command} can be
        given, and other flags are ignored except as they determine
        the target configuration.}

  @item{@DFlag{browse} --- Shows available platforms from the
        installer site.

        When @DFlag{browse} is specified, no @nonterm{command} can be
        given, and other flags are ignored except as they determine
        the installers site, version, and virtual machine. If
        @DFlag{vm} is not specified, then availability is reported
        for all version machines.}

]

@; ----------------------------------------
@section{Snapshots and @exec{raco cross}}

By default, @exec{raco cross} uses a @DFlag{version} argument to
locate a suitable distribution from the main Racket download mirror.
You can specify an alternative download site with @DFlag{installers},
but at snapshots sites, the Racket version number changes both too
quickly too be a convenient designation of the build and too slowly to
reliably distinguish the build.

Snapshot sites normally have a main page that provides links with
``current'' instead of the version number, and they also have
build-specific pages (with a hash code and/or date in the URL) to
provide the same links. The build-specific pages persist for a a few
days or weeks, depending on the snapshot site, while the main page
turns over more quickly.

The best way to work with snapshots in @exec{raco cross} is to give
each one its own workspace, instead of using the default workspace.
That way, you can use @exec{current} as the version, and you can
adjust @DFlag{installers} and @DFlag{workspace} together as suits your
purpose.

For example, to run the last Racket from the Utah snapshot, you could
write

@verbatim[#:indent 2]{
 raco cross \
  --installers https://www.cs.utah.edu/plt/snapshots/current/installers/ \
  --version current \
  --workspace /tmp/todays-snapshot \
  racket
}

The Utah snapshot updates daily, so tomorrow, throw away
@filepath{/tmp/todays-snapshot} and start again. If, instead, you need
to work with a snapshot build for a few days, locate the snapshot ID
at the bottom of the main snapshot page, and use that in a more
persistent workspace:

@verbatim[#:indent 2]{
 raco cross \
  --installers https://www.cs.utah.edu/plt/snapshots/20210512-8b4b6cf/installers/ \
  --version current \
  --workspace /home/mflatt/snapshots/20210512-8b4b6cf \
  racket
}

@; ----------------------------------------
@section[#:tag "build-your-own"]{Dealing with Missing Installers}

If the download site does not include an installer for your host
platform, and if it's a Unix-like host platform with conventional
build tools installed, then a host Racket installation can be created
with @DFlag{use-source}.

For target platforms, @exec{raco cross} does not directly support
building form source. To build your own:

@itemlist[

 @item{Start with a minimal Racket source distribution for the desired
       target version. For best results, use a ``source plus built
       packages'' distribution.}

 @item{Follow the build instructions in the source distribution to
       create an @emph{in-place} installation. The steps will be
       something like @exec{configure}, @exec{make}, and @exec{make
       install}. Be sure to configure with suitable flags like
       @DFlag{enable-bcdefault} or @DFlag{enable-csdefault}, depending
       on the default configuration for that version and your desired
       target virtual machine.}

 @item{Create a @filepath{.tgz} (gzipped tar) archive that contains
       your in-place installation. All of the archive content should
       be within a single directory; that directory should contain
       @filepath{collects}, for example. The name of the directory
       within the @filepath{.tgz} archive does not matter. The
       @filepath{src} directory (including any intermediate build
       artifacts) can be omitted from the archive.}

 @item{When running @exec{raco cross}, supply @DFlag{installers} with
       a @litchar{file://} URL (encoding a complete path) to the directory
       containing the @filepath{.tgz} file, and supply @DFlag{archive}
       with the name of the @filepath{.tgz} file in that directory.}

]
