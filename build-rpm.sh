#!/usr/bin/env bash
#
# Build a 64 bit RPM for tomcat from the official tarball release
#
# David Wooldridge - 10 Jan 2016

if [[ -z $1 ]] && [[ -z $2 ]]; then
  echo "You need to specify the version and build number (iteration)"
  echo "e.g. ./build-rpm.sh 7.0.54 1"
  exit 1
fi

[[ $TRACE ]] && set -x
set -e
set -o pipefail

version=$1
major_version="${version/.*}"
build_number="${2:-1}"
package_name='tomcat'
prefix_dir='opt'
build_dir='buildroot'
arch='x86_64'
user="tomcat"
group="$user"
tarball="apache-tomcat-${version}.tar.gz"
git_user=$(git config --get-all user.name)
git_email=$(git config --get-all user.email)
maintainer="$git_user <$git_email>"
root_dir=$(git rev-parse --show-toplevel)
tmp_dir='tmp'

which curl >/dev/null || exit 1
which fpm >/dev/null || exit 1

cd "$root_dir"

# Create temp directory
if [[ ! -d "$tmp_dir" ]]; then
  mkdir "$tmp_dir"
fi

# Clean up old builds
if [[ -d "$build_dir" ]]; then
  rm -rf "$build_dir"
fi
mkdir -p "$build_dir"

download_file() {
  local url=$1
  local file=${url##*/}

  if [[ ! -f "${tmp_dir}/${file}" ]]; then
    echo "Downloading: $file"
    curl $url -o "${tmp_dir}/${file}"
    if [[ ! -f "${tmp_dir}/${file}" ]]; then
      echo "Could not download file: $file"
      exit 1
    fi
  fi
}

download_file http://mirror.vorboss.net/apache/tomcat/tomcat-${major_version}/v${version}/bin/apache-tomcat-${version}.tar.gz
download_file http://cdn.mysql.com/archives/mysql-connector-java-5.1/mysql-connector-java-5.1.31.tar.gz

mkdir -p ${build_dir}/etc/{sysconfig,init.d} ${build_dir}/var/{log,run}/tomcat ${build_dir}/$prefix_dir
tar xzf ${tmp_dir}/${tarball} -C "${tmp_dir}/"
mv ${tmp_dir}/apache-tomcat-${version} ${build_dir}/${prefix_dir}/${package_name}

# Set better log directory (/var/log/tomcat)
sed -i "s/directory=\"logs\"/\directory=\"\/var\/log\/tomcat\"/g" ${build_dir}/${prefix_dir}/${package_name}/conf/server.xml

# Remove some stuff we just don't need
rm -rf ${build_dir}/${prefix_dir}/${package_name}/webapps/examples
rm -rf ${build_dir}/${prefix_dir}/${package_name}/webapps/docs
rm ${build_dir}/${prefix_dir}/${package_name}/bin/*.bat

# Add sysconfig file and init script
cp ${root_dir}/tomcat.rc ${build_dir}/etc/init.d/tomcat
cp ${root_dir}/tomcat.sysconfig ${build_dir}/etc/sysconfig/tomcat

tar xzf "${tmp_dir}/mysql-connector-java-5.1.31.tar.gz" -C "${tmp_dir}/"
mv "${tmp_dir}/mysql-connector-java-5.1.31/mysql-connector-java-5.1.31-bin.jar" "${build_dir}/${prefix_dir}/${package_name}/lib/"

# Add the new user if it doesn't already exist
cat > ${tmp_dir}/pre-install <<EOF
adduser \
  --home-dir /${prefix_dir}/${package_name} \
  --no-create-home \
  --shell /bin/bash \
  --user-group \
  $user >/dev/null 2>&1 || true
EOF

cat > ${tmp_dir}/post-install <<EOF
chown root:root /etc/sysconfig/tomcat /etc/init.d/tomcat
EOF

cd "$build_dir"

echo "Building RPM..."
fpm \
  -s dir \
  -t rpm \
  --name ${package_name} \
  --provides "${package_name}" \
  --version $version \
  --license 'Apache' \
  --description "$package_name - Built from release apache-tomcat-${version}.tar.gz" \
  --architecture "$arch" \
  --maintainer "$maintainer" \
  --directories /${prefix_dir}/${package_name} \
  --directories /var/run/${package_name} \
  --directories /var/log/${package_name} \
  --config-files /etc/sysconfig/$package_name \
  --config-files /etc/init.d/$package_name \
  --config-files /${prefix_dir}/$package_name/conf/server.xml \
  --config-files /${prefix_dir}/$package_name/conf/tomcat-users.xml \
  --config-files /${prefix_dir}/$package_name/conf/logging.properties \
  --config-files /${prefix_dir}/$package_name/conf/catalina.properties \
  --iteration $build_number \
  --url "http://tomcat.apache.org/" \
  --rpm-user "$user" \
  --rpm-group "$group" \
  --before-install "${root_dir}/${tmp_dir}/pre-install" \
  --after-install "${root_dir}/${tmp_dir}/post-install" \
  --package $root_dir \
  "$prefix_dir" etc var


