#!/bin/sh -eu

if [ -z "$VERSION" ] || [ -z "$ITERATION" ]; then
    echo "VERSION and ITERATION must be set!" >&2
    exit 1
fi

pkg_name=opentaxii
out_dir=./dist
common_args="
    --after-install=after-install.sh
    --after-upgrade=after-upgrade.sh
    --before-remove=before-remove.sh
    --architecture=all
    --input-type=dir
    --license=Proprietary
    --maintainer=support@eclecticiq.com
    --name=${pkg_name}
    --url=https://eclecticiq.com
    --vendor=EclecticIQ
    --verbose
"
files_args="
    --config-files /lib/systemd/system/opentaxii.service
    ./opentaxii.service=/lib/systemd/system/opentaxii.service
    /opt/${pkg_name}
"

# the virtualenv may have the wrong symlink. correct it before building
# packages - luckily the path to python3.6 is the same on ubuntu and centos
ln -sf /usr/bin/python3 /opt/${pkg_name}/bin/python3

mkdir -p "$out_dir"

fpm $common_args \
    --output-type=deb \
    --version="${VERSION}-${ITERATION}" \
    --package="${out_dir}/${pkg_name}_${VERSION}-${ITERATION}.deb" \
    -d 'python3.7 | python3.6 | python3 (>= 3.5)' \
    $files_args

fpm $common_args \
    --output-type=rpm \
    --version="${VERSION}" \
    --iteration="${ITERATION}" \
    --package="${out_dir}/${pkg_name}_${VERSION}-${ITERATION}.rpm" \
    -d 'python(abi) >= 3.5' \
    $files_args
