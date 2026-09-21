#!/usr/bin/env bash
# Drive the WarehouseFulfillment employee agent through sf agent preview,
# then SOQL-assert extra robots were created and North Hub lines were assigned.
# Requires the force-app actions and agent bundle to be deployed,
# plus Agentforce preview support in the target org.
#
# Usage: scripts/agent/warehouse-fulfillment.sh [-o org-alias] [--deploy]
# --deploy also publishes the authoring bundle and activates WarehouseFulfillment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$SESSION_ROOT"

AGENT_BUNDLE="WarehouseFulfillment"
DEPLOY=false
ORG_ALIAS=""
ORG_FLAG=()

show_usage() {
	echo "Usage: $0 [-o org-alias] [--deploy]"
	echo "  -o alias   Target org (default: sf target-org, then session003-mfg)"
	echo "  --deploy   Deploy force-app, publish, and activate WarehouseFulfillment"
	exit 1
}

while [ $# -gt 0 ]; do
	case $1 in
		-o)
			ORG_ALIAS="${2:-}"
			shift 2
			;;
		--deploy)
			DEPLOY=true
			shift
			;;
		-h|--help)
			show_usage
			;;
		-*)
			show_usage
			;;
		*)
			show_usage
			;;
	esac
done

if [ -z "$ORG_ALIAS" ]; then
	ORG_ALIAS="$(sf config get target-org --json 2>/dev/null | jq -r '.result[0].value // empty')"
fi

if [ -z "$ORG_ALIAS" ]; then
	ORG_ALIAS="session003-mfg"
fi

ORG_FLAG=(--target-org "$ORG_ALIAS")
SESSION_ID=""

json_field() {
	local json="$1"
	local expr="$2"
	jq -er "$expr" <<<"$json"
}

soql_json() {
	sf data query --query "$1" "${ORG_FLAG[@]}" --json
}

soql_value() {
	local query="$1"
	local expr="$2"
	json_field "$(soql_json "$query")" "$expr"
}

assert_equals() {
	local actual="$1"
	local expected="$2"
	local label="$3"
	if [ "$actual" != "$expected" ]; then
		echo "ASSERT FAIL: $label (expected $expected, got $actual)" >&2
		exit 1
	fi
	echo "PASS $label"
}

assert_gt() {
	local actual="$1"
	local expected="$2"
	local label="$3"
	if ! awk -v a="$actual" -v e="$expected" 'BEGIN { exit ((a + 0) > (e + 0)) ? 0 : 1 }'; then
		echo "ASSERT FAIL: $label (expected > $expected, got $actual)" >&2
		exit 1
	fi
	echo "PASS $label ($actual > $expected)"
}

end_preview() {
	if [ -n "${SESSION_ID:-}" ]; then
		sf agent preview end \
			--authoring-bundle "$AGENT_BUNDLE" \
			--session-id "$SESSION_ID" \
			"${ORG_FLAG[@]}" \
			--json >/dev/null || true
		SESSION_ID=""
	fi
}
trap end_preview EXIT

if [ "$DEPLOY" = true ]; then
	echo "==> Deploying force-app to $ORG_ALIAS"
	sf project deploy start --source-dir force-app --ignore-errors "${ORG_FLAG[@]}" || true
	echo "==> Publishing $AGENT_BUNDLE"
	sf agent publish authoring-bundle --api-name "$AGENT_BUNDLE" --skip-retrieve "${ORG_FLAG[@]}"
	echo "==> Activating $AGENT_BUNDLE"
	sf agent activate --api-name "$AGENT_BUNDLE" --json "${ORG_FLAG[@]}" >/dev/null
	echo "==> Redeploying force-app (permission set needs published Bot)"
	sf project deploy start --source-dir force-app "${ORG_FLAG[@]}"
	echo "==> Assigning permission sets"
	sf org assign permset --name WarehouseOperations "${ORG_FLAG[@]}"
	sf org assign permset --name UseSetupWithAgentforce "${ORG_FLAG[@]}"
fi

echo "==> Validating $AGENT_BUNDLE"
sf agent validate authoring-bundle --api-name "$AGENT_BUNDLE" "${ORG_FLAG[@]}"

echo "==> Loading warehouse fixtures (more pending lines than idle robots)"
"$SESSION_ROOT/bin/data.sh" -o "$ORG_ALIAS"

WAREHOUSE_ID="$(soql_value "SELECT Id FROM Warehouse__c WHERE Name = 'North Hub'" '.result.records[0].Id')"
BEFORE_ROBOTS="$(soql_value "SELECT COUNT() FROM Robot__c WHERE Warehouse__c = '${WAREHOUSE_ID}' AND Status__c IN ('Idle','Working')" '.result.totalSize')"
BEFORE_PENDING="$(soql_value "SELECT COUNT() FROM FulfillmentLine__c WHERE FulfillmentOrder__r.Warehouse__c = '${WAREHOUSE_ID}' AND Status__c = 'Pending' AND AssignedRobot__c = null" '.result.totalSize')"
BEFORE_DRAFT="$(soql_value "SELECT COUNT() FROM FulfillmentOrder__c WHERE Warehouse__c = '${WAREHOUSE_ID}' AND Status__c = 'Draft'" '.result.totalSize')"

echo "    warehouse=North Hub"
echo "    idleOrWorkingRobots=$BEFORE_ROBOTS pendingUnassignedLines=$BEFORE_PENDING draftOrders=$BEFORE_DRAFT"

if [ "$BEFORE_PENDING" -le "$BEFORE_ROBOTS" ]; then
	echo "ASSERT FAIL: seed must have more pending unassigned lines than idle robots (lines=$BEFORE_PENDING robots=$BEFORE_ROBOTS)" >&2
	exit 1
fi
if [ "$BEFORE_DRAFT" -lt 1 ]; then
	echo "ASSERT FAIL: seed must include Draft fulfillment orders" >&2
	exit 1
fi

echo "==> Starting live preview session ($AGENT_BUNDLE)"
START_JSON="$(sf agent preview start --authoring-bundle "$AGENT_BUNDLE" --use-live-actions "${ORG_FLAG[@]}" --json)"
SESSION_ID="$(json_field "$START_JSON" '.result.sessionId // .sessionId')"
echo "    sessionId=$SESSION_ID"

send_utterance() {
	local utterance="$1"
	local send_json
	echo "==> send: $utterance"
	send_json="$(sf agent preview send \
		--authoring-bundle "$AGENT_BUNDLE" \
		--session-id "$SESSION_ID" \
		--utterance "$utterance" \
		"${ORG_FLAG[@]}" \
		--json)"
	jq -r '
		.result.messages[0].message
		// .result.response
		// .result.agentResponse
		// .messages[0].message
		// .response
		// empty
	' <<<"$send_json"
	echo
}

send_utterance "Process North Hub orders optimally with one dispatch and create robots if necessary. Do this now. Do not ask for confirmation."

echo "==> Asserting SOQL outcomes"
AFTER_ROBOTS="$(soql_value "SELECT COUNT() FROM Robot__c WHERE Warehouse__c = '${WAREHOUSE_ID}' AND Status__c IN ('Idle','Working')" '.result.totalSize')"
AFTER_PENDING="$(soql_value "SELECT COUNT() FROM FulfillmentLine__c WHERE FulfillmentOrder__r.Warehouse__c = '${WAREHOUSE_ID}' AND FulfillmentOrder__r.Status__c IN ('Released','In Progress') AND Status__c = 'Pending' AND AssignedRobot__c = null" '.result.totalSize')"
AFTER_DRAFT="$(soql_value "SELECT COUNT() FROM FulfillmentOrder__c WHERE Warehouse__c = '${WAREHOUSE_ID}' AND Status__c = 'Draft'" '.result.totalSize')"
AFTER_RELEASED="$(soql_value "SELECT COUNT() FROM FulfillmentOrder__c WHERE Warehouse__c = '${WAREHOUSE_ID}' AND Status__c IN ('Released','In Progress')" '.result.totalSize')"

assert_gt "$AFTER_ROBOTS" "$BEFORE_ROBOTS" "North Hub idle/working robots increased"
assert_equals "$AFTER_PENDING" "0" "no pending unassigned lines on released or in-progress North Hub orders"
assert_equals "$AFTER_DRAFT" "0" "North Hub orders are no longer Draft"
assert_gt "$AFTER_RELEASED" "0" "North Hub orders are Released or In Progress"

echo "==> Warehouse Fulfillment agent checks passed"
echo "    warehouseId=$WAREHOUSE_ID"
echo "    robotsBefore=$BEFORE_ROBOTS robotsAfter=$AFTER_ROBOTS"
echo "    pendingUnassignedAfter=$AFTER_PENDING"
