#!/bin/bash

# Logging function
log() {
    echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] $1\n"
}

log "STARTING RELEASE PROCESS"

log "STEP 1: Switching to develop branch"
git checkout develop
if [ $? -ne 0 ]; then
    log "ERROR: Failed to switch to develop branch"
    exit 1
fi

log "STEP 2: Getting the new version from Commitizen"
cz_new_version=$(cz bump --dry-run --yes | grep 'tag to create:' | awk '{print $4}')
if [ -z "$cz_new_version" ]; then
    log "ERROR: Failed to get new version from Commitizen"
    exit 1
fi
log "New version to be released: $cz_new_version"

log "STEP 3: Starting git flow release with version $cz_new_version"
git flow release start $cz_new_version
if [ $? -ne 0 ]; then
    log "ERROR: Failed to start git flow release"
    exit 1
fi

log "STEP 4: Bumping the version using Commitizen"
cz bump
if [ $? -ne 0 ]; then
    log "ERROR: Failed to bump version using Commitizen"
    exit 1
fi

log "STEP 5: Generating changelog incrementally"
cz changelog --incremental
if [ $? -ne 0 ]; then
    log "ERROR: Failed to generate changelog incrementally"
    exit 1
fi

log "STEP 6: Adding CHANGELOG.md to git"
git add CHANGELOG.md
if [ $? -ne 0 ]; then
    log "ERROR: Failed to add CHANGELOG.md to git"
    exit 1
fi

log "STEP 7: Committing the updated changelog"
git commit -m "docs(changelog): updating changelog with changes of current release

auto generating changelog incrementally using commitizen"
if [ $? -ne 0 ]; then
    log "ERROR: Failed to commit updated changelog"
    exit 1
fi

log "STEP 8: Creating a temporary changelog for release finish"
cz ch $cz_new_version --dry-run | sed -e 's/^## //' -e 's/^### //' -e 's/^-\(.*\)$/\t- \1/' > temp.txt
if [ $? -ne 0 ]; then
    log "ERROR: Failed to create temporary changelog"
    exit 1
fi

log "STEP 9: Deleting the tag to prevent conflicts"
git tag -d $cz_new_version
if [ $? -ne 0 ]; then
    log "ERROR: Failed to delete tag"
    exit 1
fi

log "STEP 10: Setting GIT_MERGE_AUTOEDIT to no to prevent merge messages"
export GIT_MERGE_AUTOEDIT=no

log "STEP 11: Finishing the git flow release"
git flow release finish -f temp.txt "$cz_new_version"
if [ $? -ne 0 ]; then
    log "ERROR: Failed to finish git flow release"
    unset GIT_MERGE_AUTOEDIT
    rm temp.txt
    exit 1
fi

log "STEP 12: Unsetting GIT_MERGE_AUTOEDIT"
unset GIT_MERGE_AUTOEDIT

log "STEP 13: Cleaning up temporary changelog"
rm temp.txt

log "RELEASE PROCESS COMPLETED SUCCESSFULLY"
