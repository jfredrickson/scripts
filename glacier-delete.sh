#!/usr/bin/env bash
# Bulk delete Glacier archives
# usage: glacier-delete.sh ACCOUNT_ID VAULT PREFIX

# Steps:
# 1. Build an archive inventory: aws glacier initiate-job --account-id ACCOUNT_ID --vault-name VAULT_NAME --job-parameters '{"Type": "inventory-retrieval"}'
# 2. Optionally, set a SNS notification on the vault so that it notifies you when the job is complete
# 3. Get the job output: aws glacier get-job-output --account-id ACCOUNT_ID --vault-name VAULT_NAME --job-id JOB_ID inventory.json
# 4. Extract archive names: jq '.ArchiveList[].ArchiveId' inventory.json > archives.txt
# 5. Split the list: split -l 5000 archives.txt archives-
# 6. Run this script: glacier-delete.sh ACCOUNT_ID VAULT_NAME archives-

account_id=$1
vault=$2
prefix=$3

delete_archives() {
  local archive_list=$1
  local count=0
  while read archive_id ; do
    count=$((count + 1))
    echo "[$archive_list:$count] $archive_id"
    AWS_PAGER= aws glacier delete-archive --account-id $account_id --vault-name $vault --archive-id $archive_id
  done < $archive_list
}

for file in $prefix* ; do
  delete_archives $file &
done

wait
