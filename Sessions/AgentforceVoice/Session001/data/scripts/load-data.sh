#!/usr/bin/env bash
#
# Loads the Cairn Outdoor Co. sample data (REQUIREMENTS.md #3) into a target
# org, per the load order and gotchas documented in SETUP_GUIDE.md #4.
#
# Usage:
#   data/scripts/load-data.sh <org-alias>
#
# Example:
#   data/scripts/load-data.sh sally-prep
#   data/scripts/load-data.sh sally-demo

set -euo pipefail

ORG_ALIAS="${1:?Usage: load-data.sh <org-alias>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RECORDS_DIR="${DATA_DIR}/records"
GENERATED_DIR="${RECORDS_DIR}/.generated"
PLANS_DIR="${DATA_DIR}/plans"

# Must match data/scripts/generate-orders.py's PRODUCTS list.
SKUS=(TENT-AP2 PACK-ST65 STOVE-BL1 FILTER-SP3 BAG-FG20 LAMP-TB500 BOOT-RL7 CHAIR-BC4)

echo "==> Loading sample data into org '${ORG_ALIAS}'"

echo "--> Resolving org-specific IDs (Standard Pricebook, Person Account record type)"

STANDARD_PRICEBOOK_ID="$(sf data query \
  --target-org "${ORG_ALIAS}" \
  --query "SELECT Id FROM Pricebook2 WHERE IsStandard = true" \
  --json | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['records'][0]['Id'])")"

if [ -z "${STANDARD_PRICEBOOK_ID}" ]; then
  echo "ERROR: could not resolve the Standard Pricebook Id for ${ORG_ALIAS}" >&2
  exit 1
fi

echo "    Standard Pricebook: ${STANDARD_PRICEBOOK_ID}"

sf data update record \
  --target-org "${ORG_ALIAS}" \
  --sobject Pricebook2 \
  --record-id "${STANDARD_PRICEBOOK_ID}" \
  --values "IsActive=true" >/dev/null

PERSON_ACCOUNT_RECORD_TYPE_ID="$(sf data query \
  --target-org "${ORG_ALIAS}" \
  --query "SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true AND IsActive = true ORDER BY DeveloperName ASC" \
  --json | python3 -c "
import json, sys
records = json.load(sys.stdin)['result']['records']
if not records:
    print('')
else:
    # Prefer the standard 'PersonAccount' developer name if present — some org
    # templates (e.g. SDO demo orgs) seed additional Person Account record types
    # alongside it, so the choice can't be a bare LIMIT 1.
    preferred = next((r for r in records if r['DeveloperName'] == 'PersonAccount'), None)
    print((preferred or records[0])['Id'])
")"

if [ -z "${PERSON_ACCOUNT_RECORD_TYPE_ID}" ]; then
  echo "ERROR: no Person Account record type found on ${ORG_ALIAS}." >&2
  echo "       Person Accounts must be enabled first (SETUP_GUIDE.md #1) — this cannot be done via CLI/metadata." >&2
  exit 1
fi

echo "    Person Account record type: ${PERSON_ACCOUNT_RECORD_TYPE_ID}"

mkdir -p "${GENERATED_DIR}"

export STANDARD_PRICEBOOK_ID
export PERSON_ACCOUNT_RECORD_TYPE_ID

echo "--> Rendering Product/PricebookEntry/Account record files"

envsubst '${STANDARD_PRICEBOOK_ID}' \
  < "${RECORDS_DIR}/pricebook-entries.json.tpl" \
  > "${GENERATED_DIR}/pricebook-entries.json"

envsubst '${PERSON_ACCOUNT_RECORD_TYPE_ID}' \
  < "${RECORDS_DIR}/person-accounts.json.tpl" \
  > "${GENERATED_DIR}/person-accounts.json"

echo "--> Importing Products, product files, and PricebookEntries"
sf data import tree \
  --target-org "${ORG_ALIAS}" \
  --plan "${PLANS_DIR}/01-products-plan.json"

echo "--> Resolving PricebookEntry Ids for order line items"
# OrderItem.PricebookEntryId can't use an @Ref token (SETUP_GUIDE.md #10):
# refs only resolve on top-level record fields, not on fields nested inside a
# child relationship like Order.OrderItems[].PricebookEntryId. So these are
# queried now and substituted as literal Ids into orders-*.json.tpl below.
SKU_LIST="$(printf "'%s'," "${SKUS[@]}")"
SKU_LIST="${SKU_LIST%,}" # drop trailing comma
PBE_QUERY="SELECT Id, Product2.ProductCode FROM PricebookEntry WHERE Pricebook2Id = '${STANDARD_PRICEBOOK_ID}' AND Product2.ProductCode IN (${SKU_LIST})"

PBE_ENV_ASSIGNMENTS="$(sf data query \
  --target-org "${ORG_ALIAS}" \
  --query "${PBE_QUERY}" \
  --json | python3 -c "
import json, sys
records = json.load(sys.stdin)['result']['records']
for r in records:
    var = 'PRICEBOOK_ENTRY_ID_' + r['Product2']['ProductCode'].replace('-', '_')
    print(f'{var}={r[\"Id\"]}')
")"

PBE_VARS=()
while IFS='=' read -r var_name var_value; do
  [ -z "${var_name}" ] && continue
  export "${var_name}=${var_value}"
  PBE_VARS+=("\${${var_name}}")
done <<<"${PBE_ENV_ASSIGNMENTS}"

if [ "${#PBE_VARS[@]}" -ne "${#SKUS[@]}" ]; then
  echo "ERROR: expected ${#SKUS[@]} PricebookEntry Ids, resolved ${#PBE_VARS[@]}." >&2
  echo "       Did 01-products-plan.json import cleanly?" >&2
  exit 1
fi

echo "--> Rendering Order record files"
for tpl in "${RECORDS_DIR}"/orders-*.json.tpl; do
  out="${GENERATED_DIR}/$(basename "${tpl%.tpl}")"
  # shellcheck disable=SC2086 # PBE_VARS entries are deliberately unquoted — envsubst needs them space-separated
  envsubst "\${STANDARD_PRICEBOOK_ID} ${PBE_VARS[*]}" < "${tpl}" > "${out}"
done

echo "--> Importing Person Accounts and Orders"
sf data import tree \
  --target-org "${ORG_ALIAS}" \
  --plan "${PLANS_DIR}/02-customers-orders-plan.json"

echo "--> Activating orders (Order.Status can't be set to Activated on insert)"
sf apex run \
  --target-org "${ORG_ALIAS}" \
  --file "${SCRIPT_DIR}/activate-orders.apex"

echo "--> Importing Knowledge articles (as Draft)"
sf data import tree \
  --target-org "${ORG_ALIAS}" \
  --plan "${PLANS_DIR}/03-knowledge-plan.json"

echo "--> Publishing Knowledge articles"
sf apex run \
  --target-org "${ORG_ALIAS}" \
  --file "${SCRIPT_DIR}/publish-knowledge-articles.apex"

echo "==> Sample data load complete for '${ORG_ALIAS}'"
