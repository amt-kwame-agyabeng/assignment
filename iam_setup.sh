#!/bin/bash

# Define variables
USER_FILE="users.txt"
LOG_FILE="iam_setup.log"
DEFAULT_PASSWORD="Passw0rd@9586!"
EMAIL_SUBJECT="Your User Account has been Created"
SMTP_FROM="kwameagyabeng63@gmail.com"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Send email via Gmail SMTP
send_email() {
    local email="$1"
    local username="$2"

    local email_body="To: $email\nSubject: $EMAIL_SUBJECT\n\nHello $username,\n\nYour account has been successfully created.\n\nYour temporary password is: $DEFAULT_PASSWORD\nPlease change your password upon your first login.\n\nRegards,\nAdmin Team"

    echo -e "$email_body" | msmtp --from="$SMTP_FROM" -t
    log "Email sent to $email for user $username."
}

# Password policy check function
check_password_policy() {
    local pw="$1"
    if [[ ${#pw} -lt 8 ]] ||
       [[ ! "$pw" =~ [a-z] ]] ||
       [[ ! "$pw" =~ [A-Z] ]] ||
       [[ ! "$pw" =~ [0-9] ]] ||
       [[ ! "$pw" =~ [\@\#\$\%\^\&\*\!\?] ]]; then
        log "Password '$pw' does not meet the custom policy requirements."
        echo "Password must contain at least one lowercase, one uppercase, one number, one special character (@#$%^&*!?), and be at least 8 characters."
        return 1
    fi
    log "Password meets the custom policy requirements."
    return 0
}

log "-----IAM script started-----"

while IFS=',' read -r username fullname group email; do
    [[ -z "$username" || "$username" == \#* || "$username" == "username" ]] && continue

    username=$(echo "$username" | xargs)
    fullname=$(echo "$fullname" | xargs)
    group=$(echo "$group" | xargs)
    email=$(echo "$email" | xargs)

    # 1. Create user first
    if ! id "$username" &>/dev/null; then
        useradd -m -c "$fullname" "$username"
        log "User '$username' created with fullname '$fullname'."
    else
        log "User $username already exists. Skipping."
        continue
    fi

    # 2. Create group
    if ! getent group "$group" &>/dev/null; then
        groupadd "$group"
        log "Group $group created."
    else
        log "Group $group already exists. Skipping."
    fi

    # 3. Assign user to group
    usermod -g "$group" "$username"

    # 4. Check password policy
    check_password_policy "$DEFAULT_PASSWORD"
    if [[ $? -ne 0 ]]; then
        log "Password policy check failed. Skipping user '$username'."
        continue
    fi

    # 5. Set password and expiry
    echo "$username:$DEFAULT_PASSWORD" | chpasswd
    log "Default password set for user '$username'."

    chage -d 0 "$username"
    log "Force password change on first login for user '$username'."

    # 6. Set permissions
    if [ -d "/home/$username" ]; then
        chmod 700 "/home/$username"
        log "Set user home directory to 700 for user '$username'."
    else
        log "Home directory for user '$username' not found. Skipping permission set."
    fi

    # 7. Send email
    send_email "$email" "$username"

done < "$USER_FILE"

log "-----IAM script completed-----"
