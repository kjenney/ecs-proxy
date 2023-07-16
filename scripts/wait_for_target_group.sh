#!/bin/bash

# Get the target group ARN
target_group_arn=$1

# Set the maximum number of attempts
max_attempts=40

# Set the delay between attempts
delay=15

# Initialize the counter
attempts=0

# Loop until the target group has at least one healthy instance
while [ $attempts -lt $max_attempts ]; do

  # Get the health of the target group
  health=$(aws elbv2 describe-target-health --target-group-arn $target_group_arn | jq -r '.TargetHealthDescriptions[0].TargetHealth.State')

  # If the target group has at least one healthy instance, break out of the loop
  if [ "$health" == "healthy" ]; then
    break
  fi

  # Sleep for the specified delay
  sleep $delay

  # Increment the counter
  attempts=$((attempts + 1))

done

# If the target group still does not have at least one healthy instance after the maximum number of attempts, exit with an error
if [ $attempts -eq $max_attempts ]; then
  echo "Failed to wait for target group to have at least one healthy instance"
  exit 1
fi

# The target group now has at least one healthy instance
echo "Target group has at least one healthy instance"

