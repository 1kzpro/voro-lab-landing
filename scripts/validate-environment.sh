#!/bin/bash

# scripts/validate-environment.sh
# Validates that all required dependencies are installed

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Environment Validation ==="
echo "Checking required dependencies..."

# Determine environment and package manager
if [ -n "$DEPLOY_PATH" ] && [ -d "$DEPLOY_PATH/.easyd/configs" ]; then
    # Find the active environment based on branch or other criteria
    ENVIRONMENT="production" # Default
    for config_file in "$DEPLOY_PATH/.easyd/configs"/*.config.json; do
        if [ -f "$config_file" ]; then
            if command -v jq &> /dev/null; then
                PACKAGE_MANAGER=$(jq -r '.packageManager // "pnpm"' "$config_file")
                ENV_NAME=$(jq -r '.environment' "$config_file")
                if [ -n "$ENV_NAME" ]; then
                    ENVIRONMENT="$ENV_NAME"
                    echo "Detected environment from config: $ENVIRONMENT"
                    echo "Detected package manager from config: $PACKAGE_MANAGER"
                    break
                fi
            fi
        fi
    done
else
    # Fallback to defaults
    PACKAGE_MANAGER="pnpm"
    echo "No config found, using default package manager: $PACKAGE_MANAGER"
fi

# Load NVM if available
if [ -f "$HOME/.nvm/nvm.sh" ]; then
  echo "Loading NVM from $HOME/.nvm/nvm.sh"
  export NVM_DIR="$HOME/.nvm"
  # This loads nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
elif [ -f "/root/.nvm/nvm.sh" ]; then
  echo "Loading NVM from /root/.nvm/nvm.sh"
  export NVM_DIR="/root/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Load pnpm path if it exists and we're using pnpm
if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
  if [ -d "$HOME/.local/share/pnpm" ]; then
    echo "Adding pnpm to PATH from $HOME/.local/share/pnpm"
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
  elif [ -d "/root/.local/share/pnpm" ]; then
    echo "Adding pnpm to PATH from /root/.local/share/pnpm"
    export PNPM_HOME="/root/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
  fi
fi

# Print the current PATH for debugging
echo "Current PATH: $PATH"

# Set initial status
VALIDATION_PASSED=true

# Function to check command
check_command() {
  local cmd="$1"
  local name="$2"
  local min_version="$3"
  local cmd_path=""

  echo -n "Checking $name... "
  
  # Try multiple ways to find the command
  if command -v $cmd &> /dev/null; then
    cmd_path=$(command -v $cmd)
  # Special case for pnpm
  elif [ "$cmd" = "pnpm" ] && [ -f "/root/.local/share/pnpm/pnpm" ]; then
    cmd_path="/root/.local/share/pnpm/pnpm"
  elif [ "$cmd" = "pnpm" ] && [ -f "$HOME/.local/share/pnpm/pnpm" ]; then
    cmd_path="$HOME/.local/share/pnpm/pnpm"
  # Try with NVM-managed path
  elif [ -n "$NVM_DIR" ] && [ -f "$NVM_DIR/versions/node/$(nvm current 2>/dev/null || echo "")/bin/$cmd" ]; then
    cmd_path="$NVM_DIR/versions/node/$(nvm current 2>/dev/null || echo "")/bin/$cmd"
  # Check additional locations for Node.js
  elif [ "$cmd" = "node" ] && [ -f "/usr/local/bin/node" ]; then
    cmd_path="/usr/local/bin/node"
  elif [ "$cmd" = "node" ] && [ -f "/usr/bin/node" ]; then
    cmd_path="/usr/bin/node"
  # Check additional locations for nginx
  elif [ "$cmd" = "nginx" ] && [ -f "/usr/sbin/nginx" ]; then
    cmd_path="/usr/sbin/nginx"
  else
    echo -e "${RED}❌ Not installed or not found${NC}"
    echo -e "${YELLOW}Please install $name${NC}"
    if [ "$cmd" = "pnpm" ]; then
      echo -e "${YELLOW}Try: npm install -g pnpm${NC}"
      echo -e "${YELLOW}Or check its location with: find / -name pnpm -type f 2>/dev/null${NC}"
    fi
    VALIDATION_PASSED=false
    return 1
  fi
  
  echo -e "${GREEN}✅ Found at $cmd_path${NC}"
  
  # Get version information
  local version=""
  if [ "$cmd" = "nginx" ] || [[ "$cmd_path" == *"nginx"* ]]; then
    version=$($cmd_path -v 2>&1 | grep -oE "nginx/[0-9]+\.[0-9]+\.[0-9]+" | cut -d'/' -f2)
  else
    version=$($cmd_path --version 2>&1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -n 1)
  fi
  
  if [ -n "$version" ]; then
    echo -e "${GREEN}✅ Version: $version${NC}"
    
    # Version validation if min_version is provided
    if [ ! -z "$min_version" ]; then
      if [ "$(printf '%s\n' "$min_version" "$version" | sort -V | head -n1)" != "$min_version" ]; then
        echo -e "${YELLOW}⚠️  Warning: $name version $version is older than recommended minimum version $min_version${NC}"
      fi
    fi
  else
    echo -e "${YELLOW}⚠️ Could not determine version${NC}"
  fi
  
  return 0
}

# Check all required dependencies
check_command "nginx" "Nginx"
check_command "node" "Node.js" "14.0.0"
check_command "npm" "npm" "6.0.0"

# Check package manager based on configuration
if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
  check_command "pnpm" "pnpm" "6.0.0"
else
  echo "Using npm as the package manager"
fi

check_command "certbot" "Certbot"
check_command "openssl" "OpenSSL"
check_command "pm2" "PM2"

# Check if Nginx is running
echo -n "Checking Nginx status... "
if systemctl is-active --quiet nginx || service nginx status &> /dev/null; then
  echo -e "${GREEN}✅ Nginx is running${NC}"
else
  echo -e "${YELLOW}⚠️ Nginx status check failed${NC}"
  echo -e "${YELLOW}This could be due to permission issues in the SSH session${NC}"
fi

# Check if PM2 is running
echo -n "Checking PM2 status... "
PM2_PATH=$(command -v pm2 || echo "")
if [ -z "$PM2_PATH" ]; then
  if [ -n "$NVM_DIR" ]; then
    PM2_PATH="$NVM_DIR/versions/node/$(nvm current 2>/dev/null || echo "")/bin/pm2"
  fi
fi

if [ -n "$PM2_PATH" ] && $PM2_PATH ping &> /dev/null; then
  echo -e "${GREEN}✅ PM2 daemon is running${NC}"
else
  echo -e "${YELLOW}⚠️ PM2 daemon status check failed${NC}"
  echo -e "${YELLOW}It will be started during deployment if needed${NC}"
fi

# Check if Let's Encrypt certificates exist
echo -n "Checking Let's Encrypt certificates... "
if [ -d "/etc/letsencrypt/live" ] && [ "$(ls -A /etc/letsencrypt/live 2>/dev/null)" ]; then
  echo -e "${GREEN}✅ Let's Encrypt certificates found${NC}"
else
  echo -e "${YELLOW}⚠️ No Let's Encrypt certificates found${NC}"
  echo -e "${YELLOW}This might be a first deployment or permission issue${NC}"
fi

# Final validation result
echo "=== Validation Summary ==="
if [ "$VALIDATION_PASSED" = true ]; then
  echo -e "${GREEN}✅ All critical dependencies are installed${NC}"
  exit 0
else
  echo -e "${RED}❌ Validation failed. Please fix the issues above before proceeding with deployment${NC}"
  exit 1
fi