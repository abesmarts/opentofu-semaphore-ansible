#!/bin/bash
set -e

echo "Setting up Enhanced OpenTofu, Semaphore, Ansible, and ELK Stack"

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

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check available memory (ELK stack needs at least 4GB)
    total_mem=$(free -g | awk '/^Mem:/{print $2}' 2>/dev/null || sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    if [ $total_mem -lt 4 ]; then
        print_error "Insufficient memory. ELK stack requires at least 4GB RAM."
        print_error "Current available memory: ${total_mem}GB"
        exit 1
    fi
    
    print_status "System requirements check passed"
}

# Install Homebrew if not present (macOS)
install_homebrew() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            source ~/.zshrc
        else 
            print_status "Homebrew already installed"
        fi
    fi
}

# Update package manager
update_packages() {
    print_status "Updating package manager..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew update
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update
    fi
}

# Install required packages
install_packages() {
    print_status "Installing required packages..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install opentofu ansible kubectl jq git curl wget docker-compose
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt install -y opentofu ansible kubectl jq git curl wget docker-compose
    fi
}

# Check Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not running."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            print_status "Please install Docker Desktop from https://www.docker.com/products/docker-desktop/"
        else
            print_status "Please install Docker using your package manager"
        fi
        print_status "After installation, start Docker and run this script again."
        exit 1
    fi

    # Check if Docker is running 
    if ! docker info &> /dev/null; then
        print_error "Docker is not running."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            print_status "Starting Docker Desktop..."
            open -a Docker
        else
            print_status "Starting Docker service..."
            sudo systemctl start docker
        fi
        print_status "Please wait for Docker to start and run this script again."
        exit 1
    fi
}

# Generate SSH keys
generate_ssh_keys() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        print_status "Generating SSH Keys..."
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
    else 
        print_status "SSH keys already exist"
    fi
}

# Set up vm.max_map_count for Elasticsearch
setup_elasticsearch_requirements() {
    print_status "Setting up Elasticsearch requirements..."
    
    # For macOS, we need to configure Docker Desktop settings
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_warning "On macOS, you may need to increase Docker Desktop memory allocation to at least 4GB"
        print_warning "Go to Docker Desktop > Settings > Resources > Advanced"
    else
        # For Linux
        if [ -w /proc/sys/vm/max_map_count ]; then
            echo 262144 > /proc/sys/vm/max_map_count
            print_status "Set vm.max_map_count to 262144"
        else
            print_warning "Could not set vm.max_map_count. You may need to run: sudo sysctl -w vm.max_map_count=262144"
        fi
    fi
}


# Initialize OpenTofu 
initialize_opentofu() {
    print_status "Initializing OpenTofu..." 
    cd ..
    cd opentofu
    tofu init
    cd ..
}

# Start enhanced services
start_services() {
    print_status "Starting enhanced services with ELK Stack..."
    cd semaphore
    
    # Stop any existing services
    docker-compose down -v
    
    # Build and start services
    docker-compose build --no-cache
    docker-compose up -d
    
    print_status "Services started. Waiting for initialization..."
    
    # Wait for services to be healthy
    print_status "Waiting for Elasticsearch to be ready..."
    timeout=200
    while ! curl -s http://localhost:9200/_cluster/health | grep -q "green\|yellow"; do
        sleep 10
        timeout=$((timeout - 10))
        if [ $timeout -le 0 ]; then
            print_error "Elasticsearch failed to start within timeout"
            exit 1
        fi
    done
    
    print_status "Waiting for Kibana to be ready..."
    timeout=200
    while ! curl -s http://localhost:5601/api/status | grep -q "available"; do
        sleep 10
        timeout=$((timeout - 10))
        if [ $timeout -le 0 ]; then
            print_error "Kibana failed to start within timeout"
            exit 1
        fi
    done
    
    print_status "All services are ready!"
    cd ..
}

# Verify installations
verify_installations() {
    print_status "Verifying installations..."
    
    echo "=================================="
    echo "Verifying OpenTofu installation..."
    docker-compose -f semaphore/docker-compose.yaml exec -T semaphore tofu version || print_warning "OpenTofu verification failed"
    
    echo "Verifying Ansible installation..."
    docker-compose -f semaphore/docker-compose.yaml exec -T semaphore ansible --version || print_warning "Ansible verification failed"
    
    echo "Verifying ELK Stack..."
    curl -s http://localhost:9200/_cluster/health | jq . || print_warning "Elasticsearch verification failed"
    curl -s http://localhost:5601/api/status | jq . || print_warning "Kibana verification failed"
}

# Main execution
main() {
    print_status "Starting enhanced setup process..."
    
    check_requirements
    install_homebrew
    update_packages
    install_packages
    check_docker
    generate_ssh_keys
    setup_elasticsearch_requirements
    initialize_opentofu
    start_services
    verify_installations
    
    print_status "Enhanced setup completed successfully!"
    
    echo ""
    echo "=========================================="
    echo "Access Information"
    echo "=========================================="
    echo "Semaphore UI: http://localhost:3000"
    echo "Username: admin"
    echo "Password: semaphorepassword"
    echo ""
    echo "Kibana Dashboard: http://localhost:5601"
    echo "Elasticsearch API: http://localhost:9200"
    echo "Logstash API: http://localhost:9600"
    echo ""
    echo "=========================================="
    echo "Next Steps"
    echo "=========================================="
    echo "1. Access Semaphore UI and configure your project"
    echo "2. Add SSH keys to the Key store"
    echo "3. Create inventories and task templates"
    echo "4. Access Kibana to view logs and create dashboards"
    echo "5. Run your first CI/CD pipeline with full logging"
}

# Run main function
main "$@"
