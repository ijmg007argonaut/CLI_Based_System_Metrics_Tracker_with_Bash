#!/bin/bash
# health_check.sh — Logs system health and sends alerts if thresholds are exceeded.
# Collects: CPU load, memory usage, disk space.
# Outputs: health.log and optional email alerts.

# === health_check.sh ===
# Name the file, "health.log", where health checks will be stored
LOGFILE="health.log"
# Capture the current time in a variable "TIMESTAMP" that will be included in the report
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Send a line of text "=== Server Health Report @ $TIMESTAMP ==="
#   containing the variable $TIMESTAMP to the logfile.
echo "=== Server Health Report @ $TIMESTAMP ===" >> $LOGFILE

# Write the computer's hostname and system uptime to the log file using command line tools.
# "hostname" gets the device's network name.
# "uptime -p" shows the system uptime in a clean, human-readable format (e.g., "up 1 day, 3 hours").
echo "Hostname: $(hostname)" >> $LOGFILE
echo "Uptime: $(uptime -p)" >> $LOGFILE
echo "" >> $LOGFILE # Add a blank line to log file for readability.

# === CPU Load ===
# Extract CPU load averages (at 1/5/15 minutes) from the end of the uptime output.
# "awk -F'load average:'" splits the uptime output line at 'load average:', keeping the part after it.
# "{ print $2 }" prints the second half (the load values).
# The pipe symbol links the output from one command line tool as the input of the 
#   next command line tool 
echo "CPU Load (1/5/15 min): $(uptime | awk -F'load average:' '{ print $2 }')" >> $LOGFILE

# === Memory Usage ===
# Send a text string to the logfile to mark a new section of report data
echo "Memory Usage:" >> $LOGFILE
# Send to logfile memory used, free memory, swap memory using -h human readable format
# "free -h" shows RAM and swap in MB/GB.
free -h >> $LOGFILE

# === Disk Usage ===
# Send a text string to the logfile to mark a new section of report data
echo "Disk Usage:" >> $LOGFILE
# Send to logfile disk usage for all mounted file systems using -h human readable format
df -h >> $LOGFILE

echo "" >> $LOGFILE  # Add a blank line to log file for readability.

# === Alert Thresholds ===
# Define CPU_THRESHOLD variable and set it to 1 (this is load avg, not %)
CPU_THRESHOLD=1.00   
RAM_THRESHOLD=90     # Define RAM_THRESHOLD variable and set it to 90%

# === CPU Load Alert ===
# Get the 1-minute CPU load average and store it in the variable CPU_LOAD.
# Set CPU_LOAD equal to the results of a piped "|" command substitution defined by $().  
# 1. "uptime" prints system status including CPU load averages.
# 2. "awk -F'load average:'" splits the output and prints the part after 'load average:'.
# 3. "cut -d',' -f1" extracts the first value (1-minute CPU load average).
# 4. "xargs" trims whitespace from the 1-minute CPU load average result.
# Result: CPU_LOAD holds just the 1-minute CPU load (e.g., "0.52")
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d',' -f1 | xargs)

# If statement with conditional that checks if variable CPU_LOAD > variable CPU_THRESHOLD
# The double parenthesis (( )) allow arithmetic comparisons in Bash.
# The comparison "$CPU_LOAD > $CPU_THRESHOLD" is a math expression passed to 'bc'.
# Because Bash can't do floating-point math directly, the condition is passed to 'bc -l'.
# The variables are compared using the command line calculator (bc)
# The "-l" flag lets the calculator handle floating point math
# If the CPU_LOAD is > CPU_THRESHOLD, then an alert message is printed to logfile and to the screen
if (( $(echo "$CPU_LOAD > $CPU_THRESHOLD" | bc -l) )); then
    echo "⚠️ ALERT: CPU load is high ($CPU_LOAD)" >> $LOGFILE
    echo "⚠️ ALERT: CPU load is high ($CPU_LOAD)"
fi

# === RAM Usage Alert ===
# Create a variable to hold the result of a command substitution, $().
# The command line tool "free" shows how much memory (RAM and swap) is used and free.
# The result is sent to the command line tool awk which selects the line beginning with "Mem:"
# From the "Mem:" line divide the third column ($3) by the second column ($2) and multiply by 100
# Print the resulting percentage with no digits after the decimal, "{printf("%.0f", ..." 
RAM_USED_PCT=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')

# The conditional [ "$RAM_USED_PCT" -gt "$RAM_THRESHOLD" ] checks whether current RAM usage (in percent)
# is greater than the defined RAM usage threshold. This is a string to string comparison
# # If the RAM_USED_PCT is > RAM_THRESHOLD, then an alert message is printed to logfile and to the screen
if [ "$RAM_USED_PCT" -gt "$RAM_THRESHOLD" ]; then
    echo "⚠️ ALERT: RAM usage is high (${RAM_USED_PCT}%)" >> $LOGFILE
    echo "⚠️ ALERT: RAM usage is high (${RAM_USED_PCT}%)"
fi

ALERT_MSG="Health Alert on $(hostname) at $TIMESTAMP"

# CPU Alert Email
# Again, the comparison "$CPU_LOAD > $CPU_THRESHOLD" is a math expression passed to 'bc'.
# If the CPU_LOAD is > CPU_THRESHOLD, an alert message with CPU_LOAD value is printed to the screen
# The alert message is emailed using 'mail', where echo provides the message body and -s sets the subject line.
if (( $(echo "$CPU_LOAD > $CPU_THRESHOLD" | bc -l) )); then
    echo "$ALERT_MSG: CPU load is high ($CPU_LOAD)" \
    | mail -s "⚠️ CPU Load Alert: $CPU_LOAD" ijmg007argonaut@gmail.com
fi

# RAM Alert Email
# The conditional ""$RAM_USED_PCT" -gt "$RAM_THRESHOLD"" checks whether the RAM usage (as a percentage) 
#   is greater than the defined threshold. This is a string to string comparison
# If the RAM_USED_PCT is > RAM_THRESHOLD, then an alert message with RAM_USED_PCT value is printed to the screen
# The alert message is emailed using 'mail', where echo provides the message body and -s sets the subject line.
if [ "$RAM_USED_PCT" -gt "$RAM_THRESHOLD" ]; then
    echo "$ALERT_MSG: RAM usage is high (${RAM_USED_PCT}%)" \
    | mail -s "⚠️ RAM Usage Alert: ${RAM_USED_PCT}%" ijmg007argonaut@gmail.com
fi
