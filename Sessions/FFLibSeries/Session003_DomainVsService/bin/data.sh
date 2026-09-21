#!/usr/bin/env sh

# Warehouse Operations sample data for Session 003.
# Loads force-app/scripts/demo-data.apex (North Hub teaching story plus extra draft work).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLEANUP=false
SCRATCH_ORG_ALIAS=""

show_usage() {
	echo "Usage: $0 [-cleanup] [-o org-alias]"
	echo "  -cleanup   Delete warehouse sample objects first, then reload"
	echo "  -o alias   Target org (default: sf target-org, then session003-mfg)"
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
	SCRATCH_ORG_ALIAS="session003-mfg"
fi

echo "Loading warehouse sample data into org: $SCRATCH_ORG_ALIAS"

if [ "$CLEANUP" = true ]; then
	echo "Cleaning up existing warehouse sample data..."
	set +e
	sf apex run -o "$SCRATCH_ORG_ALIAS" << 'EOF'
delete [SELECT Id FROM FulfillmentLine__c];
delete [SELECT Id FROM FulfillmentOrder__c];
delete [SELECT Id FROM MaintenanceJob__c];
delete [SELECT Id FROM Robot__c];
delete [SELECT Id FROM RobotModel__c];
delete [SELECT Id FROM Warehouse__c];
EOF
	set -e
	echo "Cleanup completed"
fi

echo "Applying North Hub fixtures..."
sf apex run -o "$SCRATCH_ORG_ALIAS" -f "$SESSION_ROOT/force-app/scripts/demo-data.apex"

echo "Verifying..."
echo "Warehouses: $(sf data query -q "SELECT COUNT() FROM Warehouse__c" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "Robot models: $(sf data query -q "SELECT COUNT() FROM RobotModel__c" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "Robots: $(sf data query -q "SELECT COUNT() FROM Robot__c" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "Fulfillment orders: $(sf data query -q "SELECT COUNT() FROM FulfillmentOrder__c" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo "Pending unassigned lines: $(sf data query -q "SELECT COUNT() FROM FulfillmentLine__c WHERE Status__c = 'Pending' AND AssignedRobot__c = null" -o "$SCRATCH_ORG_ALIAS" --json | jq -r '.result.totalSize')"
echo ""
echo "Sample data loaded successfully."
