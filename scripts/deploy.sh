#!/bin/bash

# scripts/deploy.sh

set -e

if [ $# -lt 11 ]; then
    echo "Usage: $0 <deployment_id> <app_name> <primary_domain> <domains_json> <nginx_config> <public_dir> <active_port_file> <port1> <port2> <node_version> <environment> [include_www] [package_manager] [max_memory_restart]"
    exit 1
fi

if [ -z "$DEPLOY_PATH" ]; then
    echo "DEPLOY_PATH environment variable is required"
    exit 1
fi

DEPLOYMENT_ID=$1
APP_NAME_BASE=$2
PRIMARY_DOMAIN=$3
DOMAINS_JSON=$4
NGINX_CONFIG=$5
PUBLIC_DIR=$6
ACTIVE_PORT_FILE=$7
PORT1=$8
PORT2=$9
NODE_VERSION=${10}
ENVIRONMENT=${11}
INCLUDE_WWW=${12:-false}
PACKAGE_MANAGER=${13:-pnpm}
MAX_MEMORY_RESTART=${14:-"400M"}

PREVIOUS_DEPLOYMENT_FILE="$DEPLOY_PATH/previous_deployment"
RELEASE_PATH="$DEPLOY_PATH/releases/$DEPLOYMENT_ID"
CURRENT_LINK="$DEPLOY_PATH/current"

if [ -z "$DEPLOYMENT_ID" ]; then
    echo "Deployment ID is required"
    exit 1
fi

export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export PATH="/root/.nvm/versions/node/v${NODE_VERSION}.12.2/bin:$PATH"

# Configure package manager path
if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
    export PNPM_HOME="/root/.local/share/pnpm"
    export PATH="$PNPM_HOME:$PATH"
fi

echo "Starting deployment process for $APP_NAME_BASE using $PACKAGE_MANAGER..."

# Function to check and manage certificates for all domains
manage_certificates() {
    echo "Checking and managing SSL certificates for all domains..."
    
    # Collect all domains that need certificates
    local domains_to_check=("$PRIMARY_DOMAIN")
    
    # Add additional domains from JSON
    if [ "$DOMAINS_JSON" != "[]" ] && [ "$DOMAINS_JSON" != "null" ]; then
        while read -r domain; do
            if [ -n "$domain" ] && [ "$domain" != "null" ] && [ "$domain" != "$PRIMARY_DOMAIN" ]; then
                domains_to_check+=("$domain")
            fi
        done < <(jq -r '.[]' "$TEMP_JSON_FILE" 2>/dev/null || echo "")
    fi
    
    # Add www domains if includeWWW is true (only for primary domain)
    if [ "$INCLUDE_WWW" = "true" ]; then
        # Only add www for the primary domain, not for additional domains
        if [[ "$PRIMARY_DOMAIN" != www.* ]]; then
            domains_to_check+=("www.$PRIMARY_DOMAIN")
        fi
    fi
    
    echo "Domains to check for certificates: ${domains_to_check[*]}"
    
    # Check each domain for certificate validity
    for domain in "${domains_to_check[@]}"; do
        echo "Checking certificate for domain: $domain"
        
        # Check if certificate exists and is valid
        if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            # Check if certificate is not expired (valid for at least 7 days)
            local expiry_date=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" | cut -d= -f2)
            local expiry_timestamp=$(date -d "$expiry_date" +%s)
            local current_timestamp=$(date +%s)
            local seven_days_from_now=$((current_timestamp + 7 * 24 * 60 * 60))
            
            if [ $expiry_timestamp -gt $seven_days_from_now ]; then
                echo "✅ Certificate for $domain is valid (expires: $expiry_date)"
            else
                echo "⚠️ Certificate for $domain expires soon ($expiry_date), attempting renewal..."
                if certbot renew --cert-name "$domain" --quiet; then
                    echo "✅ Successfully renewed certificate for $domain"
                else
                    echo "❌ Failed to renew certificate for $domain, will issue new one..."
                    # Try to issue new certificate
                    if certbot certonly --nginx --non-interactive --agree-tos --email admin@$domain -d $domain; then
                        echo "✅ Successfully issued new certificate for $domain"
                    else
                        echo "❌ Failed to issue certificate for $domain"
                    fi
                fi
            fi
        else
            echo "⚠️ No certificate found for $domain, attempting to issue new one..."
            # Try to issue new certificate
            if certbot certonly --nginx --non-interactive --agree-tos --email admin@$domain -d $domain; then
                echo "✅ Successfully issued new certificate for $domain"
            else
                echo "❌ Failed to issue certificate for $domain"
            fi
        fi
    done
    
    echo "Certificate management completed."
}

# Check for .env file in DEPLOY_PATH and copy to RELEASE_PATH if found
if [ -f "$DEPLOY_PATH/.env" ]; then
    echo "Found .env file in $DEPLOY_PATH, copying to $RELEASE_PATH"
    cp "$DEPLOY_PATH/.env" "$RELEASE_PATH/.env"
elif [ ! -f "$RELEASE_PATH/.env" ]; then
    echo "❌ Error: .env file not found in $RELEASE_PATH or $DEPLOY_PATH. Please ensure a .env file is present in either location."
    exit 1
fi

CURRENT_PORT=""
if [ -f "$ACTIVE_PORT_FILE" ]; then
    CURRENT_PORT=$(cat "$ACTIVE_PORT_FILE")
fi

if [ "$CURRENT_PORT" = "$PORT1" ]; then
    NEW_PORT="$PORT2"
    OLD_APP_NAME="${APP_NAME_BASE}-${ENVIRONMENT}-${PORT1}"
    NEW_APP_NAME="${APP_NAME_BASE}-${ENVIRONMENT}-${PORT2}"
else
    NEW_PORT="$PORT1"
    OLD_APP_NAME="${APP_NAME_BASE}-${ENVIRONMENT}-${PORT2}"
    NEW_APP_NAME="${APP_NAME_BASE}-${ENVIRONMENT}-${PORT1}"
fi

echo "Current port: $CURRENT_PORT (app: $OLD_APP_NAME), New port: $NEW_PORT (app: $NEW_APP_NAME)"

if [ -L "$CURRENT_LINK" ] && [ -d "$CURRENT_LINK" ]; then
    PREVIOUS_DEPLOYMENT=$(basename $(readlink -f "$CURRENT_LINK"))
    echo "$PREVIOUS_DEPLOYMENT:$CURRENT_PORT" > "$PREVIOUS_DEPLOYMENT_FILE"
    echo "Previous deployment: $PREVIOUS_DEPLOYMENT on port $CURRENT_PORT"
fi

# Create a temporary JSON file for jq to process
TEMP_JSON_FILE=$(mktemp)
echo "$DOMAINS_JSON" > "$TEMP_JSON_FILE"

# Prepare switch-traffic command with proper flags
SWITCH_TRAFFIC_CMD="./scripts/switch-traffic.sh --port $NEW_PORT --nginx-config $NGINX_CONFIG --active-port-file $ACTIVE_PORT_FILE --public-dir $PUBLIC_DIR --domain $PRIMARY_DOMAIN"

# Add additional domains from the domains array using jq
if [ "$DOMAINS_JSON" != "[]" ] && [ "$DOMAINS_JSON" != "null" ]; then
    # Use jq to iterate through the array and extract each domain
    while read -r domain; do
        if [ -n "$domain" ] && [ "$domain" != "null" ]; then
            SWITCH_TRAFFIC_CMD="$SWITCH_TRAFFIC_CMD --domain $domain"
        fi
    done < <(jq -r '.[]' "$TEMP_JSON_FILE" 2>/dev/null || echo "")
fi

# Add include-www flag if enabled (only applies to primary domain)
if [ "$INCLUDE_WWW" = "true" ]; then
    SWITCH_TRAFFIC_CMD="$SWITCH_TRAFFIC_CMD --include-www"
fi

rollback() {
    echo "⚠️ Deployment failed! Rolling back to previous version..."
    
    if [ ! -f "$PREVIOUS_DEPLOYMENT_FILE" ]; then
        echo "No previous deployment found. Cannot rollback."
        exit 1
    fi
    
    ROLLBACK_INFO=$(cat "$PREVIOUS_DEPLOYMENT_FILE")
    ROLLBACK_DEPLOYMENT=$(echo "$ROLLBACK_INFO" | cut -d':' -f1)
    ROLLBACK_PORT=$(echo "$ROLLBACK_INFO" | cut -d':' -f2)
    
    if [ -z "$ROLLBACK_DEPLOYMENT" ] || [ -z "$ROLLBACK_PORT" ]; then
        echo "Invalid rollback information. Cannot rollback."
        exit 1
    fi
    
    echo "Rolling back to deployment $ROLLBACK_DEPLOYMENT on port $ROLLBACK_PORT"
    
    ROLLBACK_PATH="$DEPLOY_PATH/releases/$ROLLBACK_DEPLOYMENT"
    if [ -d "$ROLLBACK_PATH" ]; then
        ln -sfn "$ROLLBACK_PATH" "$CURRENT_LINK"
        
        ROLLBACK_APP_NAME="${APP_NAME_BASE}-${ENVIRONMENT}-${ROLLBACK_PORT}"
        
        pm2 describe "$ROLLBACK_APP_NAME" > /dev/null 2>&1 || pm2 start "$ROLLBACK_PATH/ecosystem.config.js"
        
        echo "Switching traffic back to port $ROLLBACK_PORT..."
        # Create rollback switch-traffic command
        ROLLBACK_CMD="./scripts/switch-traffic.sh --port $ROLLBACK_PORT --nginx-config $NGINX_CONFIG --active-port-file $ACTIVE_PORT_FILE --public-dir $PUBLIC_DIR --domain $PRIMARY_DOMAIN"
        
        # Add additional domains from domains array for rollback using jq
        if [ "$DOMAINS_JSON" != "[]" ] && [ "$DOMAINS_JSON" != "null" ]; then
            # Use jq to iterate through the array and extract each domain
            while read -r domain; do
                if [ -n "$domain" ] && [ "$domain" != "null" ]; then
                    ROLLBACK_CMD="$ROLLBACK_CMD --domain $domain"
                fi
            done < <(jq -r '.[]' "$TEMP_JSON_FILE" 2>/dev/null || echo "")
        fi
        
        if [ "$INCLUDE_WWW" = "true" ]; then
            ROLLBACK_CMD="$ROLLBACK_CMD --include-www"
        fi
        
        bash $ROLLBACK_CMD
        
        echo "Rollback completed successfully."
    else
        echo "Rollback path $ROLLBACK_PATH does not exist. Cannot rollback."
        exit 1
    fi
    
    echo "Cleaning up failed deployment..."
    rm -rf "$RELEASE_PATH"
    
    exit 1
}

# Check if this is a pre-built deployment
if [ -f "$RELEASE_PATH/PREBUILT" ]; then
    echo "Detected pre-built deployment, skipping build step..."
    cd "$RELEASE_PATH"

    # Install only production dependencies
    if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
        $PACKAGE_MANAGER install --prod --frozen-lockfile || { echo "Failed to install dependencies"; rollback; }
    else
        $PACKAGE_MANAGER ci --only=production || { echo "Failed to install dependencies"; rollback; }
    fi
else
    echo "Installing dependencies and building with $PACKAGE_MANAGER..."
    cd "$RELEASE_PATH"
    
    # Check if .next directory exists
    if [ -d "$RELEASE_PATH/.next" ]; then
        echo "Found existing .next directory, skipping build step"
        # Install only production dependencies
        if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
            $PACKAGE_MANAGER install --prod --frozen-lockfile || { echo "Failed to install dependencies"; rollback; }
        else
            $PACKAGE_MANAGER ci --only=production || { echo "Failed to install dependencies"; rollback; }
        fi
    else
        # Full install and build
        $PACKAGE_MANAGER install --frozen-lockfile || { echo "Failed to install dependencies"; rollback; }
        if [ "$PACKAGE_MANAGER" = "pnpm" ]; then
            $PACKAGE_MANAGER build || { echo "Failed to build application"; rollback; }
        else
            $PACKAGE_MANAGER run build || { echo "Failed to build application"; rollback; }
        fi
    fi
fi

# Manage certificates for all domains
manage_certificates

echo "Creating PM2 config for port $NEW_PORT with app name $NEW_APP_NAME..."
cat > "$RELEASE_PATH/ecosystem.config.js" << EOL
module.exports = {
  apps: [{
    name: "$NEW_APP_NAME",
    script: "node_modules/next/dist/bin/next",
    args: "start",
    instances: 1,
    watch: false,
    exec_mode: 'fork',
    max_memory_restart: "$MAX_MEMORY_RESTART",
    env_file: "$RELEASE_PATH/.env",
    env: {
      PORT: "$NEW_PORT",
      NODE_ENV: "production"
    }
  }]
}
EOL

echo "Starting new application $NEW_APP_NAME on port $NEW_PORT..."
pm2 delete "$NEW_APP_NAME" || true
pm2 start "$RELEASE_PATH/ecosystem.config.js" || { echo "Failed to start application"; rollback; }
pm2 save

echo "Performing local health check on port $NEW_PORT..."
HEALTH_CHECK_PASSED=false
for i in {1..30}; do
    if curl -s http://localhost:$NEW_PORT/_next/static/ > /dev/null; then
        echo "✅ Local health check passed"
        HEALTH_CHECK_PASSED=true
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Local health check failed after 30 attempts"
        rollback
    fi
    
    echo "Waiting for service to be healthy... (attempt $i/30)"
    sleep 2
done

if [ "$HEALTH_CHECK_PASSED" = false ]; then
    echo "❌ Local health check did not complete successfully"
    rollback
fi

echo "Updating symlink..."
ln -sfn "$RELEASE_PATH" "$CURRENT_LINK"

echo "Switching traffic to new application on port $NEW_PORT..."
echo "Executing: $SWITCH_TRAFFIC_CMD"
bash $SWITCH_TRAFFIC_CMD || { echo "Failed to switch traffic"; rollback; }

echo "Waiting for traffic to fully switch..."
sleep 15  # Increased wait time to account for DNS propagation

# Function to perform domain health check with improved status code checking
domain_health_check() {
    local domain=$1
    local is_critical=$2
    local max_attempts=$3
    local health_path=$4
    
    echo "Performing health check for domain: $domain"
    
    for i in $(seq 1 $max_attempts); do
        # Get HTTP status code and save it to a variable for inspection
        local status_code=$(curl -s -k -L -o /dev/null -w "%{http_code}" "https://$domain$health_path")
        echo "Attempt $i/$max_attempts: Domain $domain returned status code: $status_code"
        
        # Check if status code starts with 2 or 3 (success or redirect)
        if [[ $status_code =~ ^[23][0-9][0-9]$ ]]; then
            echo "✅ Domain health check passed for $domain (Status: $status_code)"
            return 0
        fi
        
        if [ $i -eq $max_attempts ]; then
            if [ "$is_critical" = true ]; then
                echo "❌ Critical domain health check failed for $domain after $max_attempts attempts (Last status: $status_code)"
                return 1
            else
                echo "⚠️ Warning: Domain health check failed for $domain after $max_attempts attempts (Last status: $status_code), but continuing deployment"
                return 0
            fi
        fi
        
        echo "Waiting for domain $domain to be accessible... (attempt $i/$max_attempts, status: $status_code)"
        sleep 3
    done
}

# Perform domain health checks
echo "Starting domain health checks..."
DOMAIN_HEALTH_CHECKS_PASSED=true
HEALTH_CHECK_PATH=""  # Changed to root path for more reliable checks
MAX_ATTEMPTS=10

# Primary domain (critical)
if ! domain_health_check "$PRIMARY_DOMAIN" true $MAX_ATTEMPTS "$HEALTH_CHECK_PATH"; then
    DOMAIN_HEALTH_CHECKS_PASSED=false
fi

# WWW domain (critical if includeWWW is true)
if [ "$INCLUDE_WWW" = "true" ]; then
    if ! domain_health_check "www.$PRIMARY_DOMAIN" true $MAX_ATTEMPTS "$HEALTH_CHECK_PATH"; then
        DOMAIN_HEALTH_CHECKS_PASSED=false
    fi
fi

# Additional domains (non-critical)
if [ "$DOMAINS_JSON" != "[]" ] && [ "$DOMAINS_JSON" != "null" ]; then
    while read -r domain; do
        if [ -n "$domain" ] && [ "$domain" != "null" ] && [ "$domain" != "$PRIMARY_DOMAIN" ]; then
            domain_health_check "$domain" false $MAX_ATTEMPTS "$HEALTH_CHECK_PATH"
        fi
    done < <(jq -r '.[]' "$TEMP_JSON_FILE" 2>/dev/null || echo "")
fi

# Rollback if critical domain checks failed
if [ "$DOMAIN_HEALTH_CHECKS_PASSED" = false ]; then
    echo "❌ Critical domain health checks failed"
    rollback
fi

if [ -n "$CURRENT_PORT" ] && [ "$CURRENT_PORT" != "$NEW_PORT" ]; then
    echo "Stopping old application $OLD_APP_NAME on port $CURRENT_PORT to save resources..."
    pm2 stop "$OLD_APP_NAME" || echo "Warning: Could not stop old application instance (it may not be running)"
    pm2 save
    echo "Deployment successful. Old instance has been stopped."
fi

# Clean up the temporary JSON file
rm -f "$TEMP_JSON_FILE"

echo "Cleaning up old deployments..."
cd "$DEPLOY_PATH/releases" && ls -1t | tail -n +6 | xargs -r rm -rf

echo "✅ Deployment completed successfully! Application is running on port $NEW_PORT"