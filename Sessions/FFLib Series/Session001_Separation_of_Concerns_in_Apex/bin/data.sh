#!/usr/bin/env sh

# Sample data for Session 001 (Accounts, Products, Opportunities, line items).
# Adapted from applink-apex-integration/data — see data/import-plan.json.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$SESSION_ROOT/data"
CLEANUP=false
SCRATCH_ORG_ALIAS=""

show_usage() {
	echo "Usage: $0 [-cleanup] [-o org-alias]"
	echo "  -cleanup   Delete existing sample Accounts, Products, and Opportunities first"
	echo "  -o alias   Target org (default: sf target-org)"
	exit 1
}

while [ $# -gt 0 ]; do
	case $1 in
		-cleanup)
			CLEANUP=true
			shift
			;;
		-o)
			SCRATCH_ORG_ALIAS="$2"
			shift 2
			;;
		-*)
			show_usage
			;;
		*)
			show_usage
			;;
	esac
done

if [ -z "$SCRATCH_ORG_ALIAS" ]; then
	SCRATCH_ORG_ALIAS=$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty')
fi

if [ -z "$SCRATCH_ORG_ALIAS" ]; then
	echo "Error: No target org. Use -o alias or: sf config set target-org <alias>"
	exit 1
fi

echo "Loading sample data into org: $SCRATCH_ORG_ALIAS"

if [ "$CLEANUP" = true ]; then
	echo "Cleaning up existing sample data..."
	set +e
	sf apex run -o "$SCRATCH_ORG_ALIAS" << 'EOF'
delete [SELECT Id FROM OpportunityLineItem];
delete [SELECT Id FROM Opportunity];
delete [SELECT Id FROM PricebookEntry WHERE Product2Id IN (SELECT Id FROM Product2)];
delete [SELECT Id FROM Product2];
delete [SELECT Id FROM Account WHERE Name != 'Sample Account for Entitlements'];
EOF
	set -e
	echo "Cleanup completed"
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

cp "$DATA_DIR"/*.json "$TMP_DIR/"

echo "Querying standard price book ID..."
PRICEBOOK_ID=$(sf data query -q "SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.records[0].Id')

if [ -z "$PRICEBOOK_ID" ] || [ "$PRICEBOOK_ID" = "null" ]; then
	echo "Error: Could not find standard price book ID"
	exit 1
fi

jq --arg id "$PRICEBOOK_ID" \
	'(.records[] | select(.Pricebook2Id == "@standardPricebookId")).Pricebook2Id = $id' \
	"$TMP_DIR/pricebook-entries.json" > "$TMP_DIR/pricebook-entries.json.tmp" \
	&& mv "$TMP_DIR/pricebook-entries.json.tmp" "$TMP_DIR/pricebook-entries.json"

echo "Applying org sample settings (before import)..."
sf apex run -o "$SCRATCH_ORG_ALIAS" -f "$SESSION_ROOT/scripts/apex/sample-data-post.apex" > /dev/null

echo "Importing sample data tree..."
( cd "$TMP_DIR" && sf data import tree --plan import-plan.json --target-org "$SCRATCH_ORG_ALIAS" )

echo "Backfilling opportunity discount type from org settings..."
sf apex run -o "$SCRATCH_ORG_ALIAS" -f "$SESSION_ROOT/scripts/apex/sample-data-post.apex" > /dev/null

echo "Verifying..."
echo "Accounts: $(sf data query -q "SELECT COUNT() FROM Account WHERE Name != 'Sample Account for Entitlements'" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "Products: $(sf data query -q "SELECT COUNT() FROM Product2" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "Opportunities: $(sf data query -q "SELECT COUNT() FROM Opportunity" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "Ready to invoice: $(sf data query -q "SELECT COUNT() FROM Opportunity WHERE InvoicedStatus__c = 'Ready'" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "OpportunityLineItems: $(sf data query -q "SELECT COUNT() FROM OpportunityLineItem" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo ""
echo "Sample data loaded successfully."
