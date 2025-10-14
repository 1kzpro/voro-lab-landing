#!/bin/bash

# scripts/switch-traffic.sh
# Switches traffic from one port to another to avoid downtime

set -e

# Initialize variables with defaults
NEW_PORT=""
NGINX_CONFIG=""
ACTIVE_PORT_FILE=""
PUBLIC_DIR=""
DOMAINS=()
INCLUDE_WWW=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-www)
            INCLUDE_WWW=true
            shift
            ;;
        --port)
            NEW_PORT="$2"
            shift 2
            ;;
        --nginx-config)
            NGINX_CONFIG="$2"
            shift 2
            ;;
        --active-port-file)
            ACTIVE_PORT_FILE="$2"
            shift 2
            ;;
        --public-dir)
            PUBLIC_DIR="$2"
            shift 2
            ;;
        --domain)
            # Skip empty or "null" domains
            if [ -n "$2" ] && [ "$2" != "null" ]; then
                DOMAINS+=("$2")
            else
                echo "Warning: Skipping empty or null domain value"
            fi
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 --port <new_port> --nginx-config <nginx_config_file> --active-port-file <active_port_file> --public-dir <public_dir> --domain <domain1> [--domain <domain2> ...] [--include-www]"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$NEW_PORT" ] || [ -z "$NGINX_CONFIG" ] || [ -z "$ACTIVE_PORT_FILE" ] || [ -z "$PUBLIC_DIR" ]; then
    echo "Missing required parameters"
    echo "Usage: $0 --port <new_port> --nginx-config <nginx_config_file> --active-port-file <active_port_file> --public-dir <public_dir> --domain <domain1> [--domain <domain2> ...] [--include-www]"
    exit 1
fi

# Check if we have at least one valid domain
if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "Error: At least one valid domain is required"
    echo "Usage: $0 --port <new_port> --nginx-config <nginx_config_file> --active-port-file <active_port_file> --public-dir <public_dir> --domain <domain1> [--domain <domain2> ...] [--include-www]"
    exit 1
fi

PRIMARY_DOMAIN=${DOMAINS[0]}

# Extract the project name from the nginx config filename
CONFIG_FILENAME=$(basename "$NGINX_CONFIG")
PROJECT_NAME=${CONFIG_FILENAME%.conf} # Remove .conf extension

# Create backup directory
BACKUP_DIR="/etc/nginx/conf.d/${PROJECT_NAME}"
mkdir -p "$BACKUP_DIR"

# Create backup of the current config if it exists
if [ -f "$NGINX_CONFIG" ]; then
    TIMESTAMP=$(date +%Y%m%d%H%M%S)
    BACKUP_FILE="${BACKUP_DIR}/${CONFIG_FILENAME}.backup.${TIMESTAMP}"
    echo "Creating backup of current nginx config: $BACKUP_FILE"
    cp "$NGINX_CONFIG" "$BACKUP_FILE"
fi

mkdir -p "$(dirname "$NGINX_CONFIG")"

if [ -f "$ACTIVE_PORT_FILE" ]; then
    OLD_PORT=$(cat "$ACTIVE_PORT_FILE")
    echo "Current port is $OLD_PORT, switching to $NEW_PORT"
else
    echo "No active port found, setting initial port to $NEW_PORT"
fi

echo "Generating Nginx configuration for domains: ${DOMAINS[*]}"
if [ "$INCLUDE_WWW" == "true" ]; then
    echo "WWW redirects will be included"
fi

# Function to check if a certificate is valid and not expired
check_certificate_validity() {
    local domain=$1
    local cert_path=$2
    
    if [ ! -f "$cert_path" ]; then
        return 1
    fi
    
    # Check if certificate is not expired (valid for at least 7 days)
    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
    local expiry_timestamp=$(date -d "$expiry_date" +%s)
    local current_timestamp=$(date +%s)
    local seven_days_from_now=$((current_timestamp + 7 * 24 * 60 * 60))
    
    if [ $expiry_timestamp -gt $seven_days_from_now ]; then
        return 0
    else
        echo "Certificate for $domain expires on $expiry_date (less than 7 days remaining)" >&2
        return 1
    fi
}

# Function to automatically issue certificate for a domain
issue_certificate() {
    local domain=$1
    local include_www=$2
    
    echo "Issuing certificate for domain: $domain" >&2
    
    # Prepare certbot command
    local certbot_cmd="certbot certonly --nginx --non-interactive --agree-tos --email admin@$domain"
    
    # Add domains to the command
    if [ "$include_www" == "true" ]; then
        certbot_cmd="$certbot_cmd -d $domain -d www.$domain"
    else
        certbot_cmd="$certbot_cmd -d $domain"
    fi
    
    echo "Running: $certbot_cmd" >&2
    
    # Execute certbot command
    if eval $certbot_cmd; then
        echo "✅ Successfully issued certificate for $domain" >&2
        return 0
    else
        echo "❌ Failed to issue certificate for $domain" >&2
        return 1
    fi
}

# Function to find the correct certificate paths for a domain
get_certificate_paths() {
    local domain=$1
    local cert_info
    local cert_name
    local cert_path
    local key_path
    local best_match=""
    local best_match_score=0
    local current_score=0
    local wildcard_domain
    
    # First, check if there's a direct path to the certificate
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]; then
        # Check if the certificate is valid
        if check_certificate_validity "$domain" "/etc/letsencrypt/live/$domain/fullchain.pem"; then
            echo "Found valid direct certificate path for $domain" >&2
            echo "/etc/letsencrypt/live/$domain/fullchain.pem:/etc/letsencrypt/live/$domain/privkey.pem"
            return 0
        else
            echo "Certificate for $domain is expired or will expire soon, attempting to renew..." >&2
            # Try to renew the certificate
            if certbot renew --cert-name "$domain" --quiet; then
                if check_certificate_validity "$domain" "/etc/letsencrypt/live/$domain/fullchain.pem"; then
                    echo "Successfully renewed certificate for $domain" >&2
                    echo "/etc/letsencrypt/live/$domain/fullchain.pem:/etc/letsencrypt/live/$domain/privkey.pem"
                    return 0
                fi
            fi
            echo "Failed to renew certificate for $domain, will issue new one..." >&2
        fi
    fi
    
    # If domain starts with *, we need special handling
    if [[ "$domain" == \** ]]; then
        wildcard_domain="$domain"
    else
        wildcard_domain="*.$domain"
        # Get base domain for wildcard checking (remove first subdomain)
        base_domain=$(echo "$domain" | sed -E 's/^[^.]+\.//')
        wildcard_base_domain="*.$base_domain"
    fi
    
    # Check using certbot
    cert_info=$(certbot certificates 2>/dev/null)
    
    # If we found certificates with certbot, parse them
    if [ -n "$cert_info" ]; then
        # Parse through the certificate information
        while IFS= read -r line; do
            if [[ "$line" == *"Certificate Name:"* ]]; then
                cert_name=${line#*Certificate Name: }
                current_score=0
            elif [[ "$line" == *"Domains:"* ]]; then
                domains_line=${line#*Domains: }
                
                # Split domains by whitespace and check each one individually
                for domain_entry in $domains_line; do
                    # Exact match has highest priority
                    if [[ "$domain_entry" == "$domain" ]]; then
                        current_score=100
                        echo "Debug: Found exact match for $domain in certificate $cert_name" >&2
                        break
                    # Wildcard match has second priority
                    elif [[ "$domain_entry" == "$wildcard_domain" ]]; then
                        current_score=75
                        echo "Debug: Found wildcard match $wildcard_domain in certificate $cert_name" >&2
                        break
                    # Parent wildcard match has third priority
                    elif [[ -n "$base_domain" && "$domain_entry" == "$wildcard_base_domain" ]]; then
                        current_score=50
                        echo "Debug: Found parent wildcard match $wildcard_base_domain in certificate $cert_name" >&2
                        break
                    fi
                done
                
                # If this is a better match, save it
                if [[ $current_score -gt $best_match_score ]]; then
                    best_match=$cert_name
                    best_match_score=$current_score
                fi
            elif [[ "$line" == *"Certificate Path:"* && "$best_match" == "$cert_name" ]]; then
                cert_path=${line#*Certificate Path: }
            elif [[ "$line" == *"Private Key Path:"* && "$best_match" == "$cert_name" ]]; then
                key_path=${line#*Private Key Path: }
            fi
        done <<< "$cert_info"
        
        # If we found a match with sufficient score, check validity and return the paths
        if [[ -n "$cert_path" && -n "$key_path" && $best_match_score -gt 0 ]]; then
            if [ -f "$cert_path" ] && [ -f "$key_path" ]; then
                if check_certificate_validity "$domain" "$cert_path"; then
                    echo "Using certificate for $best_match (match score: $best_match_score)" >&2
                    echo "$cert_path:$key_path"
                    return 0
                else
                    echo "Certificate for $domain is expired or will expire soon, attempting to renew..." >&2
                    # Try to renew the certificate
                    if certbot renew --cert-name "$best_match" --quiet; then
                        if check_certificate_validity "$domain" "$cert_path"; then
                            echo "Successfully renewed certificate for $domain" >&2
                            echo "$cert_path:$key_path"
                            return 0
                        fi
                    fi
                    echo "Failed to renew certificate for $domain, will issue new one..." >&2
                fi
            fi
        fi
    fi
    
    # No valid certificates found - try to issue a new one
    echo "No valid SSL certificate found for domain $domain, attempting to issue new certificate..." >&2
    
    # Determine if we should include www subdomain (only for primary domain)
    local include_www_for_issue="false"
    if [ "$INCLUDE_WWW" == "true" ] && [[ "$domain" != www.* ]] && [ "$domain" == "$PRIMARY_DOMAIN" ]; then
        include_www_for_issue="true"
    fi
    
    # Try to issue certificate
    if issue_certificate "$domain" "$include_www_for_issue"; then
        # Check if the certificate was created successfully
        if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/$domain/privkey.pem" ]; then
            if check_certificate_validity "$domain" "/etc/letsencrypt/live/$domain/fullchain.pem"; then
                echo "Successfully issued and validated certificate for $domain" >&2
                echo "/etc/letsencrypt/live/$domain/fullchain.pem:/etc/letsencrypt/live/$domain/privkey.pem"
                return 0
            fi
        fi
    fi
    
    # If we still don't have a valid certificate, show error and exit
    echo "Error: Failed to obtain valid SSL certificate for domain $domain" >&2
    echo "Available certificates:" >&2
    echo "$cert_info" >&2
    echo "Please manually create a certificate with: certbot certonly --nginx -d $domain -d www.$domain" >&2
    exit 1
}

# Clear the config file
> $NGINX_CONFIG

# Process each domain and generate the Nginx config
for DOMAIN in "${DOMAINS[@]}"; do
    echo "Adding configuration for domain: $DOMAIN"
    
    # Get certificate paths for this domain
    CERT_PATHS=$(get_certificate_paths "$DOMAIN")
    
    CERT_PATH=$(echo "$CERT_PATHS" | cut -d':' -f1)
    KEY_PATH=$(echo "$CERT_PATHS" | cut -d':' -f2)
    
    echo "Using certificates: $CERT_PATH and $KEY_PATH"
    
    # Add the main server configuration
    cat >> $NGINX_CONFIG << EOF
server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate $CERT_PATH;
    ssl_certificate_key $KEY_PATH;
    
    # Set maximum upload size to 20MB
    client_max_body_size 20M;

    location /public/ {
        alias $PUBLIC_DIR/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    # Explicitly route all Next.js assets—including the image optimizer—to the backend
    location ^~ /_next/ {
        proxy_pass http://127.0.0.1:${NEW_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
    }

    # General catch-all location block
    location / {
        proxy_pass http://127.0.0.1:${NEW_PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
    }
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
}
EOF

    # If include_www is true, add www redirect configuration (only for primary domain)
    if [ "$INCLUDE_WWW" == "true" ] && [ "$DOMAIN" == "$PRIMARY_DOMAIN" ]; then
        WWW_DOMAIN="www.$DOMAIN"
        
        # Check if the domain already starts with www
        if [[ "$DOMAIN" == www.* ]]; then
            echo "Domain $DOMAIN already starts with www, skipping www redirect"
            continue
        fi
        
        # Try to get certificate for www domain, with fallback handling
        WWW_CERT_PATHS=$(get_certificate_paths "$WWW_DOMAIN") || {
            # If getting certificate for www domain fails, use the main domain certificate
            WWW_CERT_PATH=$CERT_PATH
            WWW_KEY_PATH=$KEY_PATH
        }
        
        if [ -n "$WWW_CERT_PATHS" ]; then
            WWW_CERT_PATH=$(echo "$WWW_CERT_PATHS" | cut -d':' -f1)
            WWW_KEY_PATH=$(echo "$WWW_CERT_PATHS" | cut -d':' -f2)
        else
            WWW_CERT_PATH=$CERT_PATH
            WWW_KEY_PATH=$KEY_PATH
        fi
        
        echo "Adding www redirect for: $WWW_DOMAIN"
        echo "Using certificates: $WWW_CERT_PATH and $WWW_KEY_PATH"
        
        cat >> $NGINX_CONFIG << EOF

# Redirect www to non-www version (HTTPS)
server {
    listen 443 ssl;
    server_name $WWW_DOMAIN;

    ssl_certificate $WWW_CERT_PATH;
    ssl_certificate_key $WWW_KEY_PATH;
    
    # Set maximum upload size to 20MB
    client_max_body_size 20M;

    return 301 https://$DOMAIN\$request_uri;
}

# Redirect www to non-www version (HTTP)
server {
    listen 80;
    server_name $WWW_DOMAIN;
    return 301 https://$DOMAIN\$request_uri;
}
EOF
    fi
done

echo "Testing Nginx configuration..."
nginx -t
if [ $? -ne 0 ]; then
    echo "❌ Nginx configuration test failed"
    
    # If nginx test fails, restore the backup
    if [ -f "$BACKUP_FILE" ]; then
        echo "Restoring backup from $BACKUP_FILE"
        cp "$BACKUP_FILE" "$NGINX_CONFIG"
        nginx -t
        if [ $? -ne 0 ]; then
            echo "Warning: Even the backup configuration failed the Nginx test!"
        else
            echo "Backup configuration restored successfully"
        fi
    else
        echo "No backup file exists"
    fi
    exit 1
fi

echo "Reloading Nginx..."
systemctl reload nginx
if [ $? -ne 0 ]; then
    echo "Failed to reload Nginx"
    
    # Restore the backup if reload fails
    if [ -f "$BACKUP_FILE" ]; then
        echo "Restoring backup from $BACKUP_FILE"
        cp "$BACKUP_FILE" "$NGINX_CONFIG"
        systemctl reload nginx
        if [ $? -ne 0 ]; then
            echo "Warning: Failed to reload Nginx even with the backup configuration!"
        else
            echo "Backup configuration restored and Nginx reloaded successfully"
        fi
    fi
    exit 1
fi

echo $NEW_PORT > $ACTIVE_PORT_FILE

DOMAINS_LIST=$(printf ", %s" "${DOMAINS[@]}")
DOMAINS_LIST=${DOMAINS_LIST:2}

echo "✅ Successfully switched traffic to port $NEW_PORT for domains: $DOMAINS_LIST"
echo "✅ Backup created at: $BACKUP_FILE"