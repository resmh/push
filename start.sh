#!/bin/bash
set -e

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
commit=$(git rev-parse --verify HEAD)

INPUT_AUTHOR_EMAIL=${INPUT_AUTHOR_EMAIL:-'github-actions[bot]@users.noreply.github.com'}
INPUT_AUTHOR_NAME=${INPUT_AUTHOR_NAME:-'github-actions[bot]'}
INPUT_COAUTHOR_EMAIL=${INPUT_COAUTHOR_EMAIL:-''}
INPUT_COAUTHOR_NAME=${INPUT_COAUTHOR_NAME:-''}
INPUT_MESSAGE=${INPUT_MESSAGE:-"$timestamp [$commit]"}
INPUT_BRANCH=${INPUT_BRANCH:-master}
INPUT_DISTBRANCH=$INPUT_DISTBRANCH
INPUT_DISTFILES=$INPUT_DISTFILES
INPUT_FORCE=${INPUT_FORCE:-false}
INPUT_TAGS=${INPUT_TAGS:-false}
INPUT_EMPTY=${INPUT_EMPTY:-false}
INPUT_DIRECTORY=${INPUT_DIRECTORY:-'.'}
REPOSITORY=${INPUT_REPOSITORY:-$GITHUB_REPOSITORY}

echo "Push to branch $INPUT_BRANCH";
[ -z "${INPUT_GITHUB_TOKEN}" ] && {
    echo 'Missing input "github_token: ${{ secrets.GITHUB_TOKEN }}".';
    exit 1;
};

if ${INPUT_EMPTY}; then
    _EMPTY='--allow-empty'
fi

if ${INPUT_FORCE}; then
    _FORCE_OPTION='--force'
fi

if ${INPUT_TAGS}; then
    _TAGS='--tags'
fi

cd "${INPUT_DIRECTORY}"

remote_repo="https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${REPOSITORY}.git"

git config http.sslVerify false
git config --local user.email "${INPUT_AUTHOR_EMAIL}"
git config --local user.name "${INPUT_AUTHOR_NAME}"

git add -A

if [ -n "${INPUT_COAUTHOR_EMAIL}" ] && [ -n "${INPUT_COAUTHOR_NAME}" ]; then
    git commit -m "${INPUT_MESSAGE}
    

Co-authored-by: ${INPUT_COAUTHOR_NAME} <${INPUT_COAUTHOR_EMAIL}>" $_EMPTY || exit 0
else
    git commit -m "{$INPUT_MESSAGE}" $_EMPTY || exit 0
fi

# Push to main branch
git pull "${remote_repo}"
git push "${remote_repo}" HEAD:"${INPUT_BRANCH}" --follow-tags $_FORCE_OPTION $_TAGS;

# Optionally push to dist branch
if [ ! "${INPUT_DISTBRANCH}" == "" ]; then
    git checkout -f --recurse-submodules "${INPUT_DISTBRANCH}"
    fcnt=${#INPUT_DISTFILES[@]}
    # for (( i=0; i<fcnt; i++ )); do rm "${INPUT_DISTFILES[i]}"; done
    # git pull "${remote_repo}"
    
    for (( i=0; i<fcnt; i++ )); do rm "${INPUT_DISTFILES[i]}"; git checkout -f "${INPUT_BRANCH}" -- "${INPUT_DISTFILES[i]}"; done

    if [ -n "${INPUT_COAUTHOR_EMAIL}" ] && [ -n "${INPUT_COAUTHOR_NAME}" ]; then
        git commit -m "${INPUT_MESSAGE}


    Co-authored-by: ${INPUT_COAUTHOR_NAME} <${INPUT_COAUTHOR_EMAIL}>" $_EMPTY || exit 0
    else
        git commit -m "{$INPUT_MESSAGE}" $_EMPTY || exit 0
    fi
    
    git push "${remote_repo}" HEAD:"${INPUT_DISTBRANCH}" --follow-tags $_FORCE_OPTION $_TAGS;
fi
