#!/bin/bash

# Function to print progress messages
print_progress() {
    echo "==> $1"
    sleep 1  # Add a 1-second delay
}

# Function to print success or failure
print_result() {
    if [ $1 -eq 0 ]; then
        echo "==> SUCCESS: $2"
    else
        echo "==> FAILED: $2"
        exit 1
    fi
    sleep 1  # Add a 1-second delay
}

# Step 1: Prompt for AWS credentials
read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
read -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
read -p "Enter your AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1} # Default to us-east-1 if no region is provided
sleep 1  # Add a 1-second delay

# Step 2: Install AWS CLI (if not already installed)
if ! command -v aws &> /dev/null; then
    print_progress "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
    print_result $? "AWS CLI installed."
else
    print_progress "AWS CLI is already installed."
fi
sleep 1  # Add a 1-second delay

# Step 3: Configure AWS CLI with provided credentials
print_progress "Configuring AWS CLI..."
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_REGION
print_result $? "AWS CLI configured."
sleep 1  # Add a 1-second delay

# Step 4: Prompt for S3 bucket name and check if it already exists
while true; do
    read -p "Enter a name for the new S3 bucket: " S3_BUCKET_NAME
    print_progress "Checking if S3 bucket '$S3_BUCKET_NAME' already exists..."
    if aws s3api head-bucket --bucket $S3_BUCKET_NAME --region $AWS_REGION 2>/dev/null; then
        print_progress "Bucket '$S3_BUCKET_NAME' already exists. Please choose a different name."
    else
        break
    fi
    sleep 1  # Add a 1-second delay
done

# Step 5: Create the S3 bucket (handle us-east-1 differently)
print_progress "Creating S3 bucket '$S3_BUCKET_NAME'..."
if [ "$AWS_REGION" == "us-east-1" ]; then
    # us-east-1 does not require a LocationConstraint
    aws s3api create-bucket --bucket $S3_BUCKET_NAME --region $AWS_REGION
else
    # Other regions require a LocationConstraint
    aws s3api create-bucket --bucket $S3_BUCKET_NAME --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION
fi
print_result $? "S3 bucket '$S3_BUCKET_NAME' created."
sleep 1  # Add a 1-second delay

# Step 6: Install Velero CLI (version 1.15.2)
print_progress "Downloading and installing Velero CLI (version 1.15.2)..."
VELERO_VERSION="v1.15.2" # Set Velero version to 1.15.2
wget https://github.com/vmware-tanzu/velero/releases/download/$VELERO_VERSION/velero-$VELERO_VERSION-linux-amd64.tar.gz
tar -xvf velero-$VELERO_VERSION-linux-amd64.tar.gz
sudo mv velero-$VELERO_VERSION-linux-amd64/velero /usr/local/bin/
rm -rf velero-$VELERO_VERSION-linux-amd64.tar.gz velero-$VELERO_VERSION-linux-amd64
print_result $? "Velero CLI installed."
sleep 1  # Add a 1-second delay

# Step 7: Verify Velero CLI installation
print_progress "Verifying Velero installation..."
velero version
print_result $? "Velero version check."
sleep 1  # Add a 1-second delay

# Step 8: Create credentials file for AWS
CREDENTIALS_FILE="$HOME/credentials-velero" # Use a file in the home directory
print_progress "Creating AWS credentials file for Velero..."
cat <<EOF > $CREDENTIALS_FILE
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF
print_result $? "AWS credentials file created."
sleep 1  # Add a 1-second delay

print_progress "Installing Velero with AWS plugin (version 1.11.1) in the Kubernetes cluster..."
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.11.1 \
  --bucket $S3_BUCKET_NAME \
  --backup-location-config region=$AWS_REGION \
  --snapshot-location-config region=$AWS_REGION \
  --secret-file $CREDENTIALS_FILE
print_result $? "Velero with AWS plugin installed."

# Step 10: Wait for Velero pod to be running
print_progress "Waiting for Velero pod to be running..."
while true; do
    POD_STATUS=$(kubectl get pods -n velero -l component=velero -o jsonpath='{.items[0].status.phase}')
    if [ "$POD_STATUS" == "Running" ]; then
        print_progress "Velero pod is running."
        break
    else
        print_progress "Velero pod status: $POD_STATUS. Waiting..."
        sleep 10
    fi
    sleep 1  # Add a 1-second delay
done

# Step 11: Verify Velero installation in the cluster
print_progress "Verifying Velero installation in the cluster..."
kubectl get pods -n velero
print_result $? "Velero pods check."
sleep 1  # Add a 1-second delay

# Step 12: Create a backup with timestamped name
BACKUP_NAME="cluster-backup-$(date +%Y%m%d-%H%M%S)"
print_progress "Creating a backup with name: $BACKUP_NAME..."
velero backup create $BACKUP_NAME
print_result $? "Backup '$BACKUP_NAME' created."
sleep 1  # Add a 1-second delay

# Step 13: Cleanup (optional)
print_progress "Cleaning up temporary files..."
rm -f $CREDENTIALS_FILE
print_result $? "Temporary files cleaned up."
sleep 1  # Add a 1-second delay

print_progress "Velero and AWS plugin installation completed successfully!"
