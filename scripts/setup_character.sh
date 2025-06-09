#!/bin/zsh

# Character Image Generator for Helping Hand App
# This script helps create a placeholder character image

# Colors for formatted output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

ASSETS_DIR="$(dirname "$0")/../App/Resources/Assets.xcassets"
IMAGE_DIR="$ASSETS_DIR/helper_neutral.imageset"

clear
echo "${BLUE}${BOLD}======================================================${RESET}"
echo "${BLUE}${BOLD}   HELPING HAND - CHARACTER IMAGE GENERATOR           ${RESET}"
echo "${BLUE}${BOLD}======================================================${RESET}"
echo ""

echo "${GREEN}${BOLD}This script will help create a placeholder character image.${RESET}"
echo "The app has a built-in fallback to SF Symbols when no image is available,"
echo "but a custom character image can enhance the user experience."
echo ""

# Check if the image directory exists
if [ ! -d "$IMAGE_DIR" ]; then
  echo "${YELLOW}Creating image directory...${RESET}"
  mkdir -p "$IMAGE_DIR"
  
  # Create Contents.json if it doesn't exist
  if [ ! -f "$IMAGE_DIR/Contents.json" ]; then
    echo "{
  \"images\" : [
    {
      \"filename\" : \"helper_neutral.png\",
      \"idiom\" : \"universal\",
      \"scale\" : \"1x\"
    },
    {
      \"idiom\" : \"universal\",
      \"scale\" : \"2x\"
    },
    {
      \"idiom\" : \"universal\",
      \"scale\" : \"3x\"
    }
  ],
  \"info\" : {
    \"author\" : \"xcode\",
    \"version\" : 1
  }
}" > "$IMAGE_DIR/Contents.json"
  fi
fi

echo "${YELLOW}${BOLD}Options for creating a character image:${RESET}"
echo ""
echo "${BOLD}Option 1: Use an SF Symbol as placeholder${RESET}"
echo "The app will automatically use SF Symbols like:"
echo "- face.smiling for neutral mood"
echo "- face.smiling.fill for happy mood"
echo "- brain for thinking mood"
echo "- person.fill.checkmark for helping mood"
echo ""
echo "${BOLD}Option 2: Create a simple image${RESET}"
echo "1. Open Preview app on macOS"
echo "2. File > New File > Select 200x200 size"
echo "3. Use drawing tools to create a character"
echo "4. Save as PNG to your Desktop as 'helper_neutral.png'"
echo ""
echo "${BOLD}Option 3: Download a free-to-use character image${RESET}"
echo "1. Find a cartoon character image online (that's free to use)"
echo "2. Download and resize to approximately 200x200 pixels"
echo "3. Save as PNG on your Desktop as 'helper_neutral.png'"
echo ""

# Ask if they want to use an existing image
echo "${GREEN}Do you have a character image you want to use? (y/n)${RESET}"
read -r has_image

if [[ $has_image == "y" ]]; then
  echo "${YELLOW}Enter the path to your image file:${RESET}"
  read -r image_path
  
  # Copy the image to the assets folder
  if [ -f "$image_path" ]; then
    cp "$image_path" "$IMAGE_DIR/helper_neutral.png"
    echo "${GREEN}✅ Image successfully copied to the project!${RESET}"
  else
    echo "${RED}❌ Image file not found at: $image_path${RESET}"
    echo "The app will use SF Symbols as fallback."
  fi
else
  echo "${BLUE}No problem! The app will use SF Symbols as character images.${RESET}"
  echo "You can add custom images later by placing them in:"
  echo "${BOLD}$IMAGE_DIR${RESET}"
fi

echo ""
echo "${GREEN}${BOLD}Character setup complete!${RESET}"
echo "You can now run the app with:"
echo "${BOLD}./test_app.sh${RESET}"
echo ""
echo "${BLUE}${BOLD}======================================================${RESET}"
