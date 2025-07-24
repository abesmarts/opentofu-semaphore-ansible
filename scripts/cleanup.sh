#!/bin/bash
set -e

echo "==== Cleaning up Enhanced OpenTofu, Semaphore, and ELK Stack resources ===="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Stop and remove all containers and volumes
cleanup_containers() {
    print_status "Stopping and removing all containers and volumes..."
    
    cd semaphore
    
    # Stop all services
    docker-compose down -v --remove-orphans
    
    # Remove unused volumes
    docker volume prune -f
    
    # Remove unused networks
    docker network prune -f
    
    print_status "Containers and volumes cleaned up"
    cd ..
}

# Clean up OpenTofu resources
cleanup_opentofu() {
    print_status "Destroying OpenTofu resources..."
    cd opentofu
    
    if [ -f terraform.tfstate ]; then 
        tofu destroy -auto-approve
    fi
    
    # Clean up state files
    rm -f terraform.tfstate*
    rm -f .terraform.lock.hcl
    rm -rf .terraform/
    
    cd ..
    print_status "OpenTofu resources cleaned up"
}

# Clean up Docker resources
cleanup_docker() {
    print_status "Cleaning up Docker resources..."
    
    # Remove unused images
    docker image prune -a -f
    
    # Remove unused containers
    docker container prune -f
    
    # System cleanup
    docker system prune -a -f --volumes
    
    print_status "Docker resources cleaned up"
}

# Main cleanup function
main() {
    print_status "Starting comprehensive cleanup..."
    
    cleanup_containers
    cleanup_opentofu
    cleanup_docker
    
    print_status "Cleanup completed successfully!"
}

# Run main function
main "$@"
