#!/bin/bash

# GitHub organization name
ORG_NAME="MYORG"

# GitHub Personal Access Token (required)
GITHUB_TOKEN="TOKEN"

# Directory containing the local repositories (Try using my other project snatch.sh to get a folder of repos from an org)
LOCAL_REPOS_DIR="./my_repos"

# GitHub API endpoint for creating repositories
API_URL="https://api.github.com/orgs/$ORG_NAME/repos"

# Function to create a repository on GitHub
create_repo() {
    local repo_name=$1
    curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github.v3+json" \
         -d "{\"name\":\"$repo_name\", \"private\": false}" \
         "$API_URL"
}

# Function to push local repository to GitHub
push_repo() {
    local repo_path=$1
    local repo_name=$(basename "$repo_path")
    local remote_url="https://x-access-token:$GITHUB_TOKEN@github.com/$ORG_NAME/$repo_name.git"

    cd "$repo_path"
    
    # Initialize git if not already a git repository
    if [ ! -d .git ]; then
        git init
        git add .
        git commit -m "Initial commit"
    fi

    # Check if origin remote exists
    if git remote | grep -q '^origin$'; then
        git remote set-url origin "$remote_url"
    else
        git remote add origin "$remote_url"
    fi

    # Determine the current branch name
    local current_branch=$(git rev-parse --abbrev-ref HEAD)

    # Push to the current branch
    git push -u origin "$current_branch"

    cd - > /dev/null
}

# Configure Git to use credentials from environment
git config --global credential.helper store
echo "https://x-access-token:$GITHUB_TOKEN@github.com" > ~/.git-credentials

# Main script
echo "Starting to process repositories..."

for repo_path in "$LOCAL_REPOS_DIR"/*; do
    if [ -d "$repo_path" ]; then
        repo_name=$(basename "$repo_path")
        echo "Processing $repo_name..."

        # Create repo on GitHub
        create_repo "$repo_name"
        echo "Created remote repository: $repo_name"

        # Push local repo to GitHub
        push_repo "$repo_path"
        echo "Pushed $repo_name to GitHub"

        echo "Completed processing $repo_name"
        echo "------------------------"
    fi
done

# Clean up credentials
rm ~/.git-credentials
git config --global --unset credential.helper

echo "All repositories have been processed and pushed to GitHub."
