#!/bin/sh -e
# To use this, run `opam travis --help`

default_user=ocaml
default_branch=master

fork_user=${FORK_USER:-$default_user}
fork_branch=${FORK_BRANCH:-$default_branch}

# create env file
echo PACKAGE="$PACKAGE" > env.list
echo EXTRA_REMOTES="$EXTRA_REMOTES" >> env.list
echo PINS="$PINS" >> env.list
echo INSTALL="$INSTALL" >> env.list
echo DEPOPTS="$DEPOPTS" >> env.list
echo TESTS="$TESTS" >> env.list
echo REVDEPS="$REVDEPS" >> env.list
echo EXTRA_DEPS="$EXTRA_DEPS" >> env.list
echo PRE_INSTALL_HOOK="$PRE_INSTALL_HOOK" >> env.list
echo POST_INSTALL_HOOK="$POST_INSTALL_HOOK" >> env.list
echo $EXTRA_ENV_VARS >> env.list

# build a local image to trigger any ONBUILDs
echo FROM ocaml/opam:${DISTRO}_ocaml-${OCAML_VERSION} > Dockerfile
echo WORKDIR /home/opam/opam-repository >> Dockerfile
echo RUN git pull origin master >> Dockerfile

if [ $fork_user != $default_user -o $fork_branch != $default_branch ]; then
    echo RUN opam pin add travis-opam \
         https://github.com/$fork_user/ocaml-ci-scripts.git#$fork_branch \
         >> Dockerfile
fi

echo RUN opam update -u -y >> Dockerfile
echo VOLUME /repo >> Dockerfile
echo WORKDIR /repo >> Dockerfile
docker build -t local-build .

echo Dockerfile:
cat Dockerfile
echo env.list:
cat env.list
echo Command:
OS=~/build/$TRAVIS_REPO_SLUG
echo docker run --env-file=env.list -v ${OS}:/repo local-build travis-opam

# run ci-opam with the local repo volume mounted
chmod -R a+w $OS
docker run --env-file=env.list -v ${OS}:/repo local-build ci-opam
