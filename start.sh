#!/bin/bash
set -e

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
commit=$(git rev-parse --verify HEAD)

INPUT_AUTHOR_EMAIL=${INPUT_AUTHOR_EMAIL:-'github-actions[bot]@users.noreply.github.com'}
INPUT_AUTHOR_NAME=${INPUT_AUTHOR_NAME:-'github-actions[bot]'}
INPUT_COAUTHOR_EMAIL=${INPUT_COAUTHOR_EMAIL:-''}
INPUT_COAUTHOR_NAME=${INPUT_COAUTHOR_NAME:-''}
INPUT_MESSAGE=${INPUT_MESSAGE:-"CI ${timestamp} [${commit}]"}
INPUT_MESSAGE=${INPUT_MESSAGE//'${timestamp}'/$timestamp}
INPUT_MESSAGE=${INPUT_MESSAGE//'${commit}'/$commit}
INPUT_BRANCH=${INPUT_BRANCH:-master}
INPUT_DISTBRANCH=$INPUT_DISTBRANCH
INPUT_DISTFILES=$INPUT_DISTFILES
INPUT_FORCE=${INPUT_FORCE:-false}
INPUT_TAGS=${INPUT_TAGS:-false}
INPUT_EMPTY=${INPUT_EMPTY:-false}
INPUT_DIRECTORY=${INPUT_DIRECTORY:-'.'}
REPOSITORY=${INPUT_REPOSITORY:-$GITHUB_REPOSITORY}

echo 'Push to branch $INPUT_BRANCH of $REPOSITORY';
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

exit 0
#remote_repo="https://${GITHUB_ACTOR}:${INPUT_GITHUB_TOKEN}@github.com/${REPOSITORY}.git"
remote_repo="ssh://git@github.com/${REPOSITORY}.git"

git config http.sslVerify false
git config --local user.email "${INPUT_AUTHOR_EMAIL}"
git config --local user.name "${INPUT_AUTHOR_NAME}"

git add -A

if [ -n "${INPUT_COAUTHOR_EMAIL}" ] && [ -n "${INPUT_COAUTHOR_NAME}" ]; then
    git commit -m "${INPUT_MESSAGE}
    

Co-authored-by: ${INPUT_COAUTHOR_NAME} <${INPUT_COAUTHOR_EMAIL}>" $_EMPTY || exit 0
else
    git commit -m "${INPUT_MESSAGE}" $_EMPTY || exit 0
fi

# Push to main branch
git push -v "${remote_repo}" "${INPUT_BRANCH}" --follow-tags $_FORCE_OPTION $_TAGS;

# Optionally push to dist branch
if [ ! "${INPUT_DISTBRANCH}" == "" ]; then
    git checkout -f --recurse-submodules "${INPUT_DISTBRANCH}"
    
    IFS=':' read -r -a DISTFILES <<< "${INPUT_DISTFILES}"
    fcnt=${#DISTFILES[@]}
    for (( i=0; i<fcnt; i++ )); do git checkout -f "${INPUT_BRANCH}" -- "${DISTFILES[i]}"; done

    if [ -n "${INPUT_COAUTHOR_EMAIL}" ] && [ -n "${INPUT_COAUTHOR_NAME}" ]; then
        git commit -m "${INPUT_MESSAGE}


    Co-authored-by: ${INPUT_COAUTHOR_NAME} <${INPUT_COAUTHOR_EMAIL}>" $_EMPTY || exit 0
    else
        git commit -m "${INPUT_MESSAGE}" $_EMPTY || exit 0
    fi

    git push -v "${remote_repo}" "${INPUT_DISTBRANCH}" --follow-tags $_FORCE_OPTION $_TAGS;
fi
