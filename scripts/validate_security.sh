#!/bin/bash

# Security Validation Script for HelpingHand
# Run this before any Git commit to ensure no sensitive data is included

# Set colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Navigate to project root directory regardless of where script is run from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo -e "${BLUE}${BOLD}🔍 Running Security Validation...${NC}"
echo -e "${BLUE}${BOLD}==================================${NC}"

# Check for hardcoded API keys
echo -e "${BOLD}1. Checking for hardcoded API keys...${NC}"
if grep -r -E "sk-[a-zA-Z0-9]{20,}" --include="*.swift" --include="*.md" --include="*.json" --include="*.plist" --exclude="validate_security.sh" --exclude-dir=".git" . 2>/dev/null; then
    echo -e "${RED}❌ SECURITY ISSUE: Hardcoded API keys found!${NC}"
    exit 1
else
    echo -e "${GREEN}✅ No hardcoded API keys found${NC}"
fi

# Check for personal information
echo -e "${BOLD}2. Checking for personal information...${NC}"
if grep -r -E "/Users/[^/]+" --include="*.swift" --include="*.json" --include="*.sh" --include="*.plist" --exclude="validate_security.sh" --exclude-dir=".git" --exclude-dir="build" --exclude-dir="DerivedData" . 2>/dev/null | grep -v "SECURITY_AUDIT.md" | grep -v "FINAL_STATUS.md" | grep -v "# filepath:"; then
    echo -e "${RED}❌ SECURITY ISSUE: Personal paths found!${NC}"
    echo -e "${YELLOW}Run this to find all occurrences:${NC}"
    echo -e "grep -r -n -E \"/Users/[^/]+\" --include=\"*.swift\" --include=\"*.json\" --include=\"*.sh\" --include=\"*.plist\" . | grep -v \"# filepath:\" | grep -v \"SECURITY_AUDIT.md\" | grep -v \"FINAL_STATUS.md\""
    exit 1
else
    echo -e "${GREEN}✅ No personal information found${NC}"
fi

# Check for passwords/secrets
echo -e "${BOLD}3. Checking for passwords and secrets...${NC}"
SECRET_PATTERNS=(
    "password.*=.*['\"]" 
    "secret.*=.*['\"]" 
    "token.*=.*['\"]"
    "apiKey.*=.*['\"]"
    "api_key.*=.*['\"]"
)

FOUND_SECRETS=false
for pattern in "${SECRET_PATTERNS[@]}"; do
    if grep -r -E "$pattern" --include="*.swift" --include="*.json" --include="*.plist" --exclude-dir=".git" --exclude-dir="build" --exclude-dir="DerivedData" . 2>/dev/null | grep -v "ProcessInfo" | grep -v "environment" | grep -v "placeholder" | grep -v "template"; then
        echo -e "${RED}❌ SECURITY ISSUE: Potential secrets found with pattern: $pattern${NC}"
        FOUND_SECRETS=true
    fi
done

if [ "$FOUND_SECRETS" = true ]; then
    exit 1
else
    echo -e "${GREEN}✅ No passwords or secrets found${NC}"
fi

# Verify gitignore includes security patterns
echo -e "${BOLD}4. Checking .gitignore security patterns...${NC}"

REQUIRED_PATTERNS=(
    "secrets.json"
    "*.secrets.json"
    ".env"
    "build/"
    "DerivedData/"
)

MISSING_PATTERNS=()
for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -q "$pattern" .gitignore; then
        MISSING_PATTERNS+=("$pattern")
    fi
done

if [ ${#MISSING_PATTERNS[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ Security patterns in .gitignore confirmed${NC}"
else
    echo -e "${RED}❌ SECURITY ISSUE: Missing security patterns in .gitignore!${NC}"
    echo -e "${YELLOW}Missing patterns:${NC}"
    for pattern in "${MISSING_PATTERNS[@]}"; do
        echo "  - $pattern"
    done
    exit 1
fi

# Check that secrets template exists but actual secrets don't
echo -e "${BOLD}5. Checking configuration security...${NC}"
if [ -f "Config/secrets.json.template" ]; then
    echo -e "${GREEN}✅ Template configuration file exists${NC}"
    
    if [ -f "Config/secrets.json" ]; then
        echo -e "${YELLOW}⚠️  WARNING: Config/secrets.json exists locally${NC}"
        echo -e "${YELLOW}This file should not be committed to Git (should be in .gitignore)${NC}"
        
        # Check if it's in .gitignore
        if grep -q "Config/secrets.json" .gitignore; then
            echo -e "${GREEN}✅ Config/secrets.json is properly ignored in .gitignore${NC}"
        else
            echo -e "${RED}❌ SECURITY ISSUE: Config/secrets.json is not in .gitignore!${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ No secrets.json file to accidentally commit${NC}"
    fi
else
    echo -e "${RED}❌ SECURITY ISSUE: Missing security configuration template!${NC}"
    echo "The template should be located at Config/secrets.json.template"
    exit 1
fi

# Check if API key reading implementation is secure
echo -e "${BOLD}6. Checking API key implementation...${NC}"
if [ -f "App/Source/Configuration/APIConfig.swift" ]; then
    if grep -q "ProcessInfo.processInfo.environment" "App/Source/Configuration/APIConfig.swift"; then
        echo -e "${GREEN}✅ APIConfig.swift uses environment variables (secure)${NC}"
    else
        echo -e "${YELLOW}⚠️ WARNING: APIConfig.swift might not use environment variables${NC}"
        echo "Please verify the implementation is secure and doesn't contain hardcoded keys"
    fi
else
    echo -e "${YELLOW}⚠️ WARNING: Couldn't find APIConfig.swift${NC}"
fi

# Check build artifacts
echo -e "${BOLD}7. Checking for build artifacts...${NC}"
BUILD_DIRS=("build" "DerivedData" ".build")
for dir in "${BUILD_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${YELLOW}⚠️ WARNING: $dir directory exists and might contain user-specific paths${NC}"
        echo -e "Consider removing it with: ${BOLD}rm -rf $dir${NC}"
    fi
done

echo -e "${BLUE}${BOLD}==================================${NC}"
echo -e "${GREEN}${BOLD}🎉 SECURITY VALIDATION PASSED${NC}"
echo -e "${GREEN}${BOLD}✅ Repository is secure and ready for Git commit${NC}"
echo ""
echo -e "${BOLD}📋 Summary:${NC}"
echo -e "  ${GREEN}✓${NC} No hardcoded API keys"
echo -e "  ${GREEN}✓${NC} No personal information"
echo -e "  ${GREEN}✓${NC} No passwords or secrets"
echo -e "  ${GREEN}✓${NC} Proper .gitignore security"
echo -e "  ${GREEN}✓${NC} Secure configuration setup"
echo ""
echo -e "${GREEN}${BOLD}🚀 Safe to commit to GitHub!${NC}"

# Add instructions for GitHub setup
echo ""
echo -e "${BLUE}${BOLD}Next steps to upload to GitHub:${NC}"
echo -e "1. Create a new repository on GitHub"
echo -e "2. Initialize with these commands:"
echo -e "   ${BOLD}git init${NC}"
echo -e "   ${BOLD}git add .${NC}"
echo -e "   ${BOLD}git commit -m \"Initial commit of Helping Hand app\"${NC}"
echo -e "   ${BOLD}git branch -M main${NC}"
echo -e "   ${BOLD}git remote add origin <your-github-repo-url>${NC}"
echo -e "   ${BOLD}git push -u origin main${NC}"
