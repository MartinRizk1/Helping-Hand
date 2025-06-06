#!/bin/zsh

# Colors for formatted output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo "${GREEN}Initializing Git repository for Helping Hand...${RESET}"

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    git init
    echo "${GREEN}Git repository initialized${RESET}"
else
    echo "${YELLOW}Git repository already exists${RESET}"
fi

# Create directories that should exist but be empty in git
mkdir -p test-results
mkdir -p quality-reports

# Add a .keep file to keep the directories in git
touch test-results/.keep
touch quality-reports/.keep

# Set git config for this repository
git config core.excludesfile .gitignore

echo "\n${GREEN}Setting up git remotes...${RESET}"
echo "${YELLOW}Enter your GitHub repository URL (e.g., https://github.com/username/Helping-Hand.git):${RESET}"
read repo_url

if [ ! -z "$repo_url" ]; then
    git remote add origin "$repo_url"
    echo "${GREEN}Remote 'origin' added${RESET}"
else
    echo "${YELLOW}No remote added. You can add it later with:${RESET}"
    echo "git remote add origin <repository-url>"
fi

echo "\n${GREEN}Adding files to git...${RESET}"
git add .

echo "\n${GREEN}Repository is ready for first commit${RESET}"
echo "You can now run:"
echo "git commit -m \"Initial commit\""
echo "git push -u origin main"
