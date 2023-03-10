{ stdenv, lib, buildEnv, makeWrapper, runCommand, fetchurl, zlib, rsync, curl }:

# rustc and cargo nightly binaries

let
  convertPlatform = system:
    if      system == "i686-linux"    then "i686-unknown-linux-gnu"
    else if system == "x86_64-linux"  then "x86_64-unknown-linux-gnu"
    else if system == "i686-darwin"   then "i686-apple-darwin"
    else if system == "x86_64-darwin" then "x86_64-apple-darwin"
    else abort "no snapshot to bootstrap for this platform (missing target triple)";

  thisSys = convertPlatform stdenv.system;

  defaultDateFile = fetchurl {
    url = "https://static.rust-lang.org/dist/channel-rust-nightly-date.txt";
    sha256 = "1zkdm5sfsh09aav60gki2k5aancmm69l98jsgghvnxksyr8waasb";
  };
  defaultDate = lib.removeSuffix "\n" (builtins.readFile defaultDateFile);

  mkUrl = { pname, archive, date, system }:
    "${archive}/${date}/${pname}-nightly-${system}.tar.gz";

  fetch = args: let
      url = mkUrl { inherit (args) pname archive date system; };
      sha256 = args.hash;
    in fetchurl { inherit url sha256; };

  generic = { pname, archive, exes }:
      { date ? defaultDate, system ? thisSys, ... } @ args:
      stdenv.mkDerivation rec {
    name = "${pname}-${version}";
    version = "nightly-${date}";
    preferLocalBuild = true;
    # TODO meta;
    outputs = [ "out" "doc" ];
    src = fetch (args // { inherit pname archive system date; });
    nativeBuildInputs = [ rsync ];
    dontStrip = true;
    installPhase = ''
      rsync --chmod=u+w -r ./*/ $out/
    '';
    preFixup = if stdenv.isLinux then let
      # it's overkill, but fixup will prune
      rpath = "$out/lib:" + lib.makeLibraryPath [ zlib stdenv.cc.cc.lib curl ];
    in ''
      for executable in ${lib.concatStringsSep " " exes}; do
        patchelf \
          --interpreter "$(< $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath "${rpath}" \
          "$out/bin/$executable"
      done
      for library in $out/lib/*.so; do
        patchelf --set-rpath "${rpath}" "$library"
      done
    '' else "";
  };

in rec {
  rustc = generic {
    pname = "rustc";
    archive = "https://static.rust-lang.org/dist";
    exes = [ "rustc" "rustdoc" ];
  };

  rustcWithSysroots = { rustc, sysroots ? [] }: buildEnv {
    name = "combined-sysroots";
    paths = [ rustc ] ++ sysroots;
    pathsToLink = [ "/lib" "/share" ];
    #buildInputs = [ makeWrapper ];
    # Can't use wrapper script because of https://github.com/rust-lang/rust/issues/31943
    postBuild = ''
      mkdir -p $out/bin/
      cp ${rustc}/bin/* $out/bin/
    '';
  };

  rust-std = { date ? defaultDate, system ? thisSys, ... } @ args:
      stdenv.mkDerivation rec {
    # Strip install.sh, etc
    pname = "rust-std";
    version = "nightly-${date}";
    name = "${pname}-${version}-${system}";
    src = fetch (args // {
      inherit pname date system;
      archive = "https://static.rust-lang.org/dist";
    });
    installPhase = ''
      mkdir -p $out
      mv ./*/* $out/
      rm $out/manifest.in
    '';
  };

  cargo = generic {
    pname = "cargo";
    archive = "https://static.rust-lang.org/dist";
    exes = [ "cargo" ];
  };

  rust = generic {
    pname = "rust";
    archive = "https://static.rust-lang.org/dist";
    exes = [ "rustc" "rustdoc" "cargo" "rust-analyzer" "rustfmt" ];
  };
}
