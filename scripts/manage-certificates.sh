#!/bin/bash

# scripts/manage-certificates.sh
# Manages SSL certificates for domains - checks, renews, and issues new certificates

set -e

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to issue certificate for a domain
issue_certificate() {
    local domain=$1
    local include_www=$2
    
    echo -e "${BLUE}Issuing certificate for domain: $domain${NC}"
    
    # Prepare certbot command
    local certbot_cmd="certbot certonly --nginx --non-interactive --agree-tos --email admin@$domain"
    
    # Add domains to the command
    if [ "$include_www" == "true" ]; then
        certbot_cmd="$certbot_cmd -d $domain -d www.$domain"
    else
        certbot_cmd="$certbot_cmd -d $domain"
    fi
    
    echo "Running: $certbot_cmd"
    
    # Execute certbot command
    if eval $certbot_cmd; then
        echo -e "${GREEN}✅ Successfully issued certificate for $domain${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to issue certificate for $domain${NC}"
        return 1
    fi
}

# Function to renew certificate for a domain
renew_certificate() {
    local domain=$1
    
    echo -e "${YELLOW}Renewing certificate for domain: $domain${NC}"
    
    if certbot renew --cert-name "$domain" --quiet; then
        echo -e "${GREEN}✅ Successfully renewed certificate for $domain${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to renew certificate for $domain${NC}"
        return 1
    fi
}

# Function to manage certificate for a single domain
manage_domain_certificate() {
    local domain=$1
    local include_www=$2
    local is_primary_domain=$3  # New parameter to indicate if this is the primary domain
    
    echo -e "${BLUE}Checking certificate for domain: $domain${NC}"
    
    # Check if certificate exists and is valid
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        if check_certificate_validity "$domain" "/etc/letsencrypt/live/$domain/fullchain.pem"; then
            echo -e "${GREEN}✅ Certificate for $domain is valid${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️ Certificate for $domain expires soon, attempting renewal...${NC}"
            if renew_certificate "$domain"; then
                if check_certificate_validity "$domain" "/etc/letsencrypt/live/$domain/fullchain.pem"; then
                    echo -e "${GREEN}✅ Successfully renewed certificate for $domain${NC}"
                    return 0
                fi
            fi
            echo -e "${YELLOW}⚠️ Failed to renew certificate for $domain, will issue new one...${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ No certificate found for $domain, will issue new one...${NC}"
    fi
    
    # Try to issue new certificate
    # Only include www if this is the primary domain and include_www is true
    local should_include_www="$include_www"
    if [ "$should_include_www" == "true" ] && [ "$is_primary_domain" != "true" ]; then
        should_include_www="false"
    fi
    
    if issue_certificate "$domain" "$should_include_www"; then
        if check_certificate_validity "$domain" "/etc/letsencrypt/live/$domain/fullchain.pem"; then
            echo -e "${GREEN}✅ Successfully issued and validated certificate for $domain${NC}"
            return 0
        fi
    fi
    
    echo -e "${RED}❌ Failed to obtain valid certificate for $domain${NC}"
    return 1
}

# Function to list all certificates
list_certificates() {
    echo -e "${BLUE}=== Current Certificates ===${NC}"
    certbot certificates 2>/dev/null || echo "No certificates found or certbot not available"
}

# Function to show certificate details
show_certificate_details() {
    local domain=$1
    
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        echo -e "${BLUE}=== Certificate Details for $domain ===${NC}"
        echo "Certificate Path: /etc/letsencrypt/live/$domain/fullchain.pem"
        echo "Private Key Path: /etc/letsencrypt/live/$domain/privkey.pem"
        
        # Show expiry date
        local expiry_date=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" | cut -d= -f2)
        echo "Expiry Date: $expiry_date"
        
        # Show issuer
        local issuer=$(openssl x509 -issuer -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" | cut -d= -f2)
        echo "Issuer: $issuer"
        
        # Show validity status
        if check_certificate_validity "$domain" "/etc/letsencrypt/live/$domain/fullchain.pem"; then
            echo -e "${GREEN}Status: Valid${NC}"
        else
            echo -e "${RED}Status: Expired or expiring soon${NC}"
        fi
    else
        echo -e "${RED}No certificate found for $domain${NC}"
    fi
}

# Main function to manage certificates for multiple domains
manage_certificates() {
    local domains=("$@")
    local include_www=${domains[-1]}
    unset domains[-1]  # Remove the last element (include_www flag)
    
    if [ ${#domains[@]} -eq 0 ]; then
        echo -e "${RED}Error: No domains provided${NC}"
        echo "Usage: $0 <domain1> [domain2] ... [--include-www]"
        exit 1
    fi
    
    echo -e "${BLUE}=== Certificate Management ===${NC}"
    echo "Domains to manage: ${domains[*]}"
    echo "Include WWW: $include_www"
    echo ""
    
    local success_count=0
    local total_count=${#domains[@]}
    
    for i in "${!domains[@]}"; do
        local domain="${domains[$i]}"
        local is_primary_domain="false"
        
        # Check if this is the primary domain (first domain in the list)
        if [ $i -eq 0 ]; then
            is_primary_domain="true"
        fi
        
        if manage_domain_certificate "$domain" "$include_www" "$is_primary_domain"; then
            ((success_count++))
        fi
        echo ""
    done
    
    echo -e "${BLUE}=== Summary ===${NC}"
    echo "Successfully managed: $success_count/$total_count domains"
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}✅ All certificates are valid and up to date${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Some certificates could not be managed successfully${NC}"
        return 1
    fi
}

# Parse command line arguments
case "${1:-}" in
    "list")
        list_certificates
        exit 0
        ;;
    "details")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Domain required for details command${NC}"
            echo "Usage: $0 details <domain>"
            exit 1
        fi
        show_certificate_details "$2"
        exit 0
        ;;
    "renew")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Domain required for renew command${NC}"
            echo "Usage: $0 renew <domain>"
            exit 1
        fi
        renew_certificate "$2"
        exit $?
        ;;
    "issue")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Domain required for issue command${NC}"
            echo "Usage: $0 issue <domain> [--include-www]"
            exit 1
        fi
        local include_www="false"
        if [ "$3" = "--include-www" ]; then
            include_www="true"
        fi
        issue_certificate "$2" "$include_www"
        exit $?
        ;;
    "help"|"-h"|"--help")
        echo "SSL Certificate Management Script"
        echo ""
        echo "Usage:"
        echo "  $0 <domain1> [domain2] ... [--include-www]  # Manage certificates for domains"
        echo "  $0 list                                      # List all certificates"
        echo "  $0 details <domain>                          # Show certificate details"
        echo "  $0 renew <domain>                            # Renew certificate for domain"
        echo "  $0 issue <domain> [--include-www]           # Issue new certificate for domain"
        echo "  $0 help                                      # Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 example.com www.example.com --include-www"
        echo "  $0 details example.com"
        echo "  $0 renew example.com"
        echo "  $0 issue newdomain.com --include-www"
        exit 0
        ;;
    *)
        # Default behavior: manage certificates for provided domains
        local include_www="false"
        local domains=()
        
        for arg in "$@"; do
            if [ "$arg" = "--include-www" ]; then
                include_www="true"
            else
                domains+=("$arg")
            fi
        done
        
        if [ ${#domains[@]} -eq 0 ]; then
            echo -e "${RED}Error: No domains provided${NC}"
            echo "Usage: $0 <domain1> [domain2] ... [--include-www]"
            echo "Use '$0 help' for more information"
            exit 1
        fi
        
        # Add include_www flag to the domains array for the manage_certificates function
        domains+=("$include_www")
        manage_certificates "${domains[@]}"
        exit $?
        ;;
esac 