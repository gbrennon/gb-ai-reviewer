#!/bin/bash

check_required_vars() {
    local missing=()
    
    for var in "$@"; do
        local value
        value=$(eval "echo \$$var" 2>/dev/null || echo "")
        if [ -z "$value" ]; then
            missing+=("$var")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: The following required environment variables are not defined:" >&2
        for var in "${missing[@]}"; do
            echo "  - $var" >&2
        done
        exit 1
    fi
}