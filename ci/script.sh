set -ex

main() {
    local td=

    ./build-docker-image.sh $TARGET

    if [ $TRAVIS_BRANCH = master ] || [ ! -z $TRAVIS_TAG ]; then
        return
    fi

    cargo install --path .

    # NOTE(case) japaric/cross#4
    case $TARGET in
        mips-unknown-linux-gnu | \
            mips64-unknown-linux-gnuabi64 | \
            powerpc64-unknown-linux-gnu)
        ;;
        *)
            td=$(mktemp -d)

            git clone --depth 1 https://github.com/rust-lang/cargo $td

            pushd $td
            cross build --target $TARGET
            popd

            rm -rf $td
            ;;
    esac

    # NOTE(s390x) japaric/cross#3
    # NOTE(x86_64-musl) can't test compiler-builtins because that crate needs
    # cdylibs and this musl target doesn't support cdylibs
    case $TARGET in
        s390x-unknown-linux-gnu | \
            x86_64-unknown-linux-musl)
        ;;
        *)
            td=$(mktemp -d)

            git clone \
                --depth 1 \
                --recursive \
                https://github.com/rust-lang-nursery/compiler-builtins \
                $td

            pushd $td
            cargo generate-lockfile
            cross test \
                  --no-default-features \
                  --target $TARGET
            popd

            rm -rf $td

            td=$(mktemp -d)

            cargo init --bin --name hello $td

            pushd $td
            cargo generate-lockfile
            cross run --target $TARGET
            popd

            rm -rf $td
        ;;
    esac
}

main
