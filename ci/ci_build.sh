#!/usr/bin/env bash

# Get the directory of the current script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ASTRO_NIX_SRC_DIR="${SCRIPT_DIR}/../"

ASTRO_NIX_S3_CACHE_URL="s3://astro-nix?region=weur&endpoint=711ba62cd0e23d50ede0bc15f1000186.r2.cloudflarestorage.com&scheme=https&secret-key=${HOME}/.nix/keys/astro-nix.key"

set -x

# Function to build a derivation with nix and print build log on stdout
build_derivation() {
    local derivation_name="$1"
    echo "Building derivation: $derivation_name"
    nix build -f "${ASTRO_NIX_SRC_DIR}" --no-link --print-out-paths --print-build-logs  "${derivation_name}"
    if [ $? -eq 0 ]; then
        echo "Build successful for ${derivation_name}"
    else
        echo "Build failed for ${derivation_name}"
        return 1
    fi
}

# Function to push a derivation to an S3 cache
push_to_s3_cache() {
    local derivation_name="$1"
    local s3_cache_url="$2"
    echo "Pushing derivation to S3 cache: ${derivation_name}"
    nix copy -f "${ASTRO_NIX_SRC_DIR}" --to "${s3_cache_url}"  "${derivation_name}"
    if [ $? -eq 0 ]; then
        echo "Push successful for ${derivation_name}"
    else
        echo "Push failed for ${derivation_name}"
        return 1
    fi
}



# Function to setup S3 credentials from GitHub Actions secrets
setup_aws_credentials() {
    
    # Create .aws directory if it doesn't exist
    mkdir -p "${HOME}/.aws"
    
    # Create credentials file with proper permissions
    cat > "${HOME}/.aws/credentials" <<EOF
[default]
aws_access_key_id = ${aws_access_key_id}
aws_secret_access_key = ${aws_secret_access_key}
region = eu-west-2
EOF
    
    # Set appropriate permissions
    chmod 600 "${HOME}/.aws/credentials"
    
    echo "S3 credentials have been set up successfully."
}


# Function to setup NIX_SIGN_KEY from GitHub Actions secrets
setup_nix_sign_key() {
    
    # Test that NIX_SIGN_KEY environment variable exists
    if [[ ! -v NIX_SIGN_KEY ]]; then
        echo "Error: NIX_SIGN_KEY environment variable is not set or is empty."
        return 1
    fi
    
    # Create .nix/keys directory if it doesn't exist
    mkdir -p "${HOME}/.nix/keys"
    
    # Write the signing key to the file
    cat > "${HOME}/.nix/keys/astro-nix.key" <<EOF
${NIX_SIGN_KEY}
EOF
    
    # Set appropriate permissions (600 = owner read/write only)
    chmod 600 "${HOME}/.nix/keys/astro-nix.key"
    echo "NIX_SIGN_KEY has been set up successfully."
}


# build all derivation and push them to the cache, in order
build_all_derivation(){
    for drv in $(nix run -f ${ASTRO_NIX_SRC_DIR} jq -- -r ".default[]" ${SCRIPT_DIR}/astro-derivations.json); do
        build_derivation "$drv"
        if [ $? -ne 0 ]; then
            echo "Fail to build $drv"
        fi
        # push if success
        setup_aws_credentials
        setup_nix_sign_key
        push_to_s3_cache "$drv" "$ASTRO_NIX_S3_CACHE_URL"
    done
}

# Example usage:
# build_derivation "path/to/derivation.nix"
# push_to_s3_cache "path/to/derivation.nix" "s3://your-cache-url"
