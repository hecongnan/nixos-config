{ pkgs, flclash }:
pkgs.runCommand "flclash-native-library-loading"
{
  nativeBuildInputs = [ pkgs.stdenv.cc ];
}
  ''
    cat > check-loader.c <<'EOF'
    #define _GNU_SOURCE
    #include <dlfcn.h>
    #include <errno.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    __attribute__((constructor)) static void check_loader(void) {
        /* Skip the wrapper's shell; inspect the actual application environment. */
        if (strcmp(program_invocation_short_name, "FlClash") != 0) return;
        void *library = dlopen("librust_api.so", RTLD_NOW);
        if (!library) {
            fprintf(stderr, "FlClash Rust library: %s\n", dlerror());
            _Exit(1);
        }
        dlclose(library);
        _Exit(0);
    }
    EOF
    cc -shared -fPIC check-loader.c -ldl -o check-loader.so
    # Run the real wrapper, without needing a display or entering the UI.
    LD_PRELOAD="$PWD/check-loader.so" ${flclash}/bin/FlClash
    touch "$out"
  ''
