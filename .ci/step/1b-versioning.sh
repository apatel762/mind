#!/usr/bin/env bash
# Pipeline configuration

Environment::set CURRENT_GIT_COMMIT "$(git rev-parse --short HEAD)"
Environment::set CURRENT_GIT_BRANCH "$(git rev-parse --abbrev-ref HEAD)"

PREVIOUS_TAG="$(git describe --tags --abbrev=0 --always)"

if Semver::is_valid "$PREVIOUS_TAG" &>/dev/null; then
    Environment::set PREVIOUS_VERSION "$PREVIOUS_TAG"
else
    # If no tag exists (or the last tag is not a valid semver), we will
    # start again at the very first version and bump it up from there.
    # To avoid this, just apply a valid semver tag to the previous commit.
    Environment::set PREVIOUS_VERSION "0.0.0"
fi

BUILD_VERSION=""

if [ -n "$(git tag --points-at HEAD)" ]; then
    # If the current commit is already tagged, use the existing tag as the build version
    # This means we'll essentially be rebuilding a previous release.
    BUILD_VERSION="${PREVIOUS_VERSION}"

elif [ "${CURRENT_GIT_BRANCH}" = "main" ] || [ "${CURRENT_GIT_BRANCH}" = "master" ]; then
    # On the mainline branch, we need to calculate the next semantic version
    # by reading the commit messages since the last last.
    COMMITS_FILE="$(mktemp)"

    if [ "${PREVIOUS_VERSION}" = "0.0.0" ]; then
        git log --no-decorate --pretty=format:"%s" > "${COMMITS_FILE}"
    else
        git log "${PREVIOUS_VERSION}..HEAD" --no-decorate --pretty=format:"%s" > "${COMMITS_FILE}"
    fi

    # Add a newline to the commits file if it doesn't have one
    # This prevents us from seeing an unexpected end of file
    # (which breaks parsing later on)
    sed -i -e '$a\' "${COMMITS_FILE}"

    # For now, take a copy of the previous version.
    # We will parse every commit message between the last build and figure
    # out how to bump the version...
    BUILD_VERSION="${PREVIOUS_VERSION}"
    increment_type=""

    while read -r commit_message; do
        echo "$commit_message"
        if [[ $commit_message =~ (([a-z]+)(\(.+\))?\!:)|(BREAKING CHANGE:) ]]; then
            echo "\_[major]"
            increment_type="major"
            break
        elif [[ $commit_message =~ (^(feat)(\(.+\))?:) ]]; then
            if [ -z "$increment_type" ] || [ "$increment_type" == "patch" ]; then
                echo "\_[minor]"
                increment_type="minor"
            fi
        else
            echo "\_[patch]"
            if [ -z "$increment_type" ]; then
                # only consider this a patch version if we haven't already set it
                # to something else
                increment_type="patch"
            fi
        fi
    done < "${COMMITS_FILE}"

    # using the calculated increment type, bump the version...
    case "${increment_type}" in
        patch)
            BUILD_VERSION="$(Semver::increment_patch "${BUILD_VERSION}")"
            ;;
        minor)
            BUILD_VERSION="$(Semver::increment_minor "${BUILD_VERSION}")"
            ;;
        major)
            BUILD_VERSION="$(Semver::increment_major "${BUILD_VERSION}")"
            :
            ;;
        *)
            log_error "Unrecognised version increment: ${increment_type:-"<blank>"} -- there was likely a problem parsing commits."
            exit 1
            ;;
    esac

    if is_ci; then
        (
            set -x
            git tag "${BUILD_VERSION}"
            git push origin "${BUILD_VERSION}"
        )
    else
        log_warning "Skipped git tagging... (you /are/ on the mainline branch BUT the pipeline is running locally)"
    fi
else
    # For all other branches, the version number is not finalised, so we will
    # take the current version and append some prerelease metadata onto it.
    SANITISED_BRANCH_NAME="$(echo "$CURRENT_GIT_BRANCH" | sed 's/[^0-9A-Za-z-]/-/g; s/-\+/-/g; s/^-//; s/-$//')"
    if test -n "$(git status --porcelain)"; then
        DIRTY="-dirty"
    else
        DIRTY=""
    fi

    BUILD_VERSION="${PREVIOUS_VERSION}-${SANITISED_BRANCH_NAME}+${CURRENT_GIT_COMMIT}${DIRTY}"
fi

Environment::set BUILD_VERSION "$BUILD_VERSION"
