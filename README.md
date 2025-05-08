# IAM User Setup Script
This Bash script streamlines the process of creating Linux users and groups from a CSV file, enforces a custom password policy, adjusts home directory permissions, and optionally sends email notifications to newly created users.

## Features

- Takes a CSV file as input (via command-line argument)
- Creates groups when they do not already exist
- Establishes users with designated full names and assigns them to their respective groups
- Configures a default password that complies with security standards
- Requires users to change their password upon their first login
- Sets home directory permissions to `700`
- Sends an email containing credentials (requires `msmtp` configuration)

## Usage

```bash
sudo ./iam_setup.sh users.csv
``` 

Please note that the script needs to be executed with sudo privileges as it alters system user settings.