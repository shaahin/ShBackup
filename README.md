ShBackup Script
===============

The ShBackup script is a Bash shell script designed to automate the backup of local folders to Cloudflare R2 cloud storage. It uses the rclone utility to synchronize data with Cloudflare R2.

Features
--------

*   Backup multiple local folders to Cloudflare R2.
*   Sync each local folder to a corresponding subdirectory in the R2 bucket.
*   Supports Cloudflare R2 as a cloud storage provider.
*   Automatic versioning and syncing of files to the cloud.
*   Optional setup of a cron job for automatic periodic backups (every hour by default).

Requirements
------------

*   Linux operating system.
*   Bash shell.
*   rclone utility (installed separately or using the provided setup instructions).

Usage
-----

1\. Clone the ShBackup repository to your local machine.

    git clone https://github.com/shaahin/ShBackup.git

2\. Create a .env file in the same directory as the ShBackup script with the following environment variables:

    
    ACCOUNT_ID="your_cloudflare_account_id"
    ACCESS_KEY="your_access_key"
    SECRET_ACCESS_KEY="your_secret_access_key"
    LOCAL_FOLDERS="/path/to/local/folder1,/path/to/local/folder2"  # Replace with the actual local folder paths separated by commas
    R2_BUCKET="your_r2_bucket"  # Replace with the Cloudflare R2 bucket name
    

3\. (Optional) If you need to skip the rclone installation and cron job setup, use the --skip-setup flag:

    
    ./ShBackup --env-file /path/to/custom_env_file --skip-setup
    

4\. Run the ShBackup script to perform the initial backup and optionally set up the cron job:

    
    ./ShBackup --env-file /path/to/.env
    

Important Note
--------------

Always review the script and the .env file to ensure the correct configurations before running. Be cautious with your sensitive data and API keys in the .env file.

License
-------

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Contribution
------------

Contributions to the project are welcome! Feel free to open issues or submit pull requests on the project's GitHub repository.