#!/bin/bash

# Set working directory to the script directory
cd "$(dirname "${BASH_SOURCE[0]}")"

DEFAULT_ENV_FILE="$PWD/.env"

# Set the .env file path to the default if --env-file option is not provided
ENV_FILE=${DEFAULT_ENV_FILE}

# Function to print script usage information
print_usage() {
  echo "Usage: $0 [--env-file path/to/env_file] [--skip-setup] [-y]"
}

# Check for command-line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  --env-file)
    ENV_FILE="$2"
    shift
    shift
    ;;
  --skip-setup)
    SKIP_SETUP="true"
    shift
    ;;
  -y)
    AUTO_CONFIRM="true"
    shift
    ;;
  *)
    echo "Error: Unknown option '$key'"
    print_usage
    exit 1
    ;;
  esac
done

if [[ $SKIP_SETUP != "true" ]]; then

  # Step 1: Install rclone (uncomment the appropriate command for your package manager)
  sudo apt-get install rclone
  # sudo yum install rclone
  # sudo pacman -S rclone

fi

# Read ACCOUNT_ID, ACCESS_KEY, SECRET_ACCESS_KEY, LOCAL_FOLDERS, and R2_BUCKET from .env file
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
else
  echo "Error: .env file not found. Please create the .env file with required environment variables."
  print_usage
  exit 1
fi

# Check if all environment variables are not empty
if [[ -z $ACCOUNT_ID || -z $ACCESS_KEY || -z $SECRET_ACCESS_KEY || -z $LOCAL_FOLDERS || -z $R2_BUCKET ]]; then
  echo "Error: Some environment variables are empty. Please ensure all variables are set in the .env file."
  print_usage
  exit 1
fi

# Print environment variables read from .env
echo "Local folders to sync:"
echo "$LOCAL_FOLDERS"
echo "Destination Cloudflare R2 bucket: $R2_BUCKET"

# Check if -y flag is passed (auto confirmation)
if [[ $AUTO_CONFIRM == "true" ]]; then
  confirmation="y"
else
  # Ask for confirmation before continuing with synchronization
  read -p "Do you want to proceed with the synchronization? (y/n): " confirmation
fi

if [[ ! $confirmation =~ ^[Yy]$ ]]; then
  echo "Synchronization aborted."
  exit 0
fi

if [[ $SKIP_SETUP != "true" ]]; then

  # Step 2: Create rclone.conf with Cloudflare configuration
  CONFIG_FILE="$HOME/.config/rclone/rclone.conf"

  # Create necessary directories
  mkdir -p "$HOME/.config/rclone"

  # Write rclone.conf content
  cat >"$CONFIG_FILE" <<EOL
[R2]
type = s3
provider = Cloudflare
access_key_id = $ACCESS_KEY
secret_access_key = $SECRET_ACCESS_KEY
region = auto
endpoint = https://$ACCOUNT_ID.r2.cloudflarestorage.com
acl = private
EOL

fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Split LOCAL_FOLDERS by commas into an array
IFS=',' read -ra LOCAL_FOLDERS_ARRAY <<<"$LOCAL_FOLDERS"

# Step 3: Synchronize your local folders with Cloudflare R2
for local_folder in "${LOCAL_FOLDERS_ARRAY[@]}"; do
  echo "Syncing folder: $local_folder"
  # Extract the folder name from the path
  folder_name=$(basename "$local_folder")
  # Add trailing slash if not present
  [[ $local_folder != */ ]] && local_folder="$local_folder/"
  # Synchronize each local folder to a corresponding subdirectory with the same name in the Cloudflare R2 bucket
  rclone sync "$local_folder" "R2:$R2_BUCKET/$folder_name/"
  echo "Folder: $local_folder synced."
done

if [[ $SKIP_SETUP != "true" ]]; then
  # Step 4: Automate the sync with cron (optional)
  # Check if the cron job entry already exists before adding the new rule
  if ! crontab -l | grep -q "$SCRIPT_DIR/shbackup.sh"; then
    # Uncomment and modify the following line to schedule the sync with cron
    # (run the script with './shbackup.sh' once before enabling cron to set up rclone)
    # (0 */2 * * * runs the sync every 2 hours)
    # 0 */2 * * * /bin/bash "$SCRIPT_DIR/shbackup.sh" >> "$SCRIPT_DIR/shbackup.log" 2>&1
    echo "Adding the cron job..."
    # (crontab -l; echo "0 */2 * * * /bin/bash \"$SCRIPT_DIR/shbackup.sh -y\" >> \"$SCRIPT_DIR/shbackup.log\" 2>&1") | crontab -
    (
      crontab -l
      echo "0 * * * * /bin/bash \"$SCRIPT_DIR/shbackup.sh\" -y --skip-setup >> \"$SCRIPT_DIR/shbackup.log\" 2>&1"
    ) | crontab -
    echo "Cron job added successfully!"
  else
    echo "The cron job already exists in the crontab. Skipping adding a new rule."
  fi

fi

echo "All done!"
