#!/usr/bin/env bash
# Drive the OpportunityOperations employee agent through sf agent preview,
# then SOQL-assert that a discount was applied and an invoice was created.
# Requires the force-app.with-soc actions and agent bundle to be deployed,
# plus Agentforce preview support in the target org.
#
# Usage: scripts/agent/opportunity-operations.sh [-o org-alias] [--deploy]
# --deploy also publishes the authoring bundle and activates OpportunityOperations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$SESSION_ROOT"

AGENT_BUNDLE="OpportunityOperations"
DISCOUNT_PERCENT=10
UNIT_PRICE=1000
EXPECTED_DISCOUNTED_PRICE=900
DEPLOY=false
ORG_ALIAS=""
ORG_FLAG=()

show_usage() {
	echo "Usage: $0 [-o org-alias] [--deploy]"
	echo "  -o alias   Target org (default: sf target-org)"
	echo "  --deploy   Deploy force-app.with-soc, publish, and activate OpportunityOperations"
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
	echo "Error: No target org. Use -o alias or: sf config set target-org <alias>" >&2
	exit 1
fi

ORG_FLAG=(--target-org "$ORG_ALIAS")
RUN_ID="$(date +%s)"
SESSION_ID=""

json_field() {
	local json="$1"
	local expr="$2"
	jq -er "$expr" <<<"$json"
}

create_record() {
	local sobject="$1"
	local values="$2"
	local json id
	json="$(sf data create record --sobject "$sobject" --values "$values" "${ORG_FLAG[@]}" --json)"
	id="$(json_field "$json" '.result.id')"
	printf '%s' "$id"
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

assert_number() {
	local actual="$1"
	local expected="$2"
	local label="$3"
	if ! awk -v a="$actual" -v e="$expected" 'BEGIN { exit ((a + 0) == (e + 0)) ? 0 : 1 }'; then
		echo "ASSERT FAIL: $label (expected $expected, got $actual)" >&2
		exit 1
	fi
	echo "PASS $label ($actual)"
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
	echo "==> Deploying force-app.with-soc to $ORG_ALIAS"
	sf project deploy start --source-dir force-app.with-soc --ignore-errors "${ORG_FLAG[@]}" || true
	echo "==> Publishing $AGENT_BUNDLE"
	sf agent publish authoring-bundle --api-name "$AGENT_BUNDLE" --skip-retrieve "${ORG_FLAG[@]}"
	echo "==> Activating $AGENT_BUNDLE"
	sf agent activate --api-name "$AGENT_BUNDLE" --json "${ORG_FLAG[@]}" >/dev/null
	echo "==> Redeploying force-app.with-soc (permission set needs published Bot)"
	sf project deploy start --source-dir force-app.with-soc "${ORG_FLAG[@]}"
fi

echo "==> Validating $AGENT_BUNDLE"
sf agent validate authoring-bundle --api-name "$AGENT_BUNDLE" "${ORG_FLAG[@]}"

echo "==> Creating fixture opportunities (runId=$RUN_ID)"
PRICEBOOK_ID="$(soql_value "SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE" '.result.records[0].Id')"
ACCOUNT_ID="$(create_record Account "Name='Agent Ops Account ${RUN_ID}'")"
PRODUCT_ID="$(create_record Product2 "Name='Agent Ops Product ${RUN_ID}' ProductCode=AOPS-${RUN_ID} IsActive=true DiscountingApproved__c=true")"
PBE_ID="$(create_record PricebookEntry "Pricebook2Id=${PRICEBOOK_ID} Product2Id=${PRODUCT_ID} UnitPrice=${UNIT_PRICE} IsActive=true UseStandardPrice=false")"

CLOSE_DATE="$(date -u +%Y-%m-%d)"
DISCOUNT_OPP_ID="$(create_record Opportunity "Name='Agent Discount ${RUN_ID}' AccountId=${ACCOUNT_ID} StageName=Prospecting CloseDate=${CLOSE_DATE} Pricebook2Id=${PRICEBOOK_ID}")"
INVOICE_OPP_ID="$(create_record Opportunity "Name='Agent Invoice ${RUN_ID}' AccountId=${ACCOUNT_ID} StageName=Prospecting CloseDate=${CLOSE_DATE} Pricebook2Id=${PRICEBOOK_ID}")"

create_record OpportunityLineItem "OpportunityId=${DISCOUNT_OPP_ID} PricebookEntryId=${PBE_ID} Quantity=1 UnitPrice=${UNIT_PRICE}" >/dev/null
create_record OpportunityLineItem "OpportunityId=${INVOICE_OPP_ID} PricebookEntryId=${PBE_ID} Quantity=1 UnitPrice=${UNIT_PRICE}" >/dev/null

BEFORE_DISCOUNT_AMOUNT="$(soql_value "SELECT Amount FROM Opportunity WHERE Id = '${DISCOUNT_OPP_ID}'" '.result.records[0].Amount')"
BEFORE_INVOICE_COUNT="$(soql_value "SELECT COUNT() FROM Invoice__c WHERE Opportunity__c = '${INVOICE_OPP_ID}'" '.result.totalSize')"
assert_number "$BEFORE_DISCOUNT_AMOUNT" "$UNIT_PRICE" "discount fixture starting Amount"
assert_equals "$BEFORE_INVOICE_COUNT" "0" "invoice fixture starts with no Invoice__c"

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

send_utterance "Hi, I need help with opportunities."
send_utterance "Apply a ${DISCOUNT_PERCENT} percent discount to Opportunity ${DISCOUNT_OPP_ID}. Use the apply opportunity discount action with opportunityId ${DISCOUNT_OPP_ID} and discountPercentage ${DISCOUNT_PERCENT}."
send_utterance "Create an invoice from Opportunity ${INVOICE_OPP_ID}. Use the create opportunity invoice action with opportunityId ${INVOICE_OPP_ID}. Do not apply a discount."

echo "==> Asserting SOQL outcomes"
AFTER_DISCOUNT_AMOUNT="$(soql_value "SELECT Amount FROM Opportunity WHERE Id = '${DISCOUNT_OPP_ID}'" '.result.records[0].Amount')"
AFTER_DISCOUNT_UNIT_PRICE="$(soql_value "SELECT UnitPrice FROM OpportunityLineItem WHERE OpportunityId = '${DISCOUNT_OPP_ID}'" '.result.records[0].UnitPrice')"
AFTER_INVOICE_COUNT="$(soql_value "SELECT COUNT() FROM Invoice__c WHERE Opportunity__c = '${INVOICE_OPP_ID}'" '.result.totalSize')"
AFTER_INVOICE_LINE_COUNT="$(soql_value "SELECT COUNT() FROM InvoiceLine__c WHERE Invoice__r.Opportunity__c = '${INVOICE_OPP_ID}'" '.result.totalSize')"
AFTER_INVOICE_NAME="$(soql_value "SELECT Name FROM Invoice__c WHERE Opportunity__c = '${INVOICE_OPP_ID}'" '.result.records[0].Name')"

assert_number "$AFTER_DISCOUNT_AMOUNT" "$EXPECTED_DISCOUNTED_PRICE" "Opportunity Amount after discount"
assert_number "$AFTER_DISCOUNT_UNIT_PRICE" "$EXPECTED_DISCOUNTED_PRICE" "OpportunityLineItem UnitPrice after discount"
assert_equals "$AFTER_INVOICE_COUNT" "1" "Invoice__c created for invoice opportunity"
assert_equals "$AFTER_INVOICE_LINE_COUNT" "1" "InvoiceLine__c created for invoice opportunity"
case "$AFTER_INVOICE_NAME" in
	INV-*) echo "PASS Invoice Name is auto-number ($AFTER_INVOICE_NAME)" ;;
	*)
		echo "ASSERT FAIL: Invoice Name is auto-number (expected INV-*, got $AFTER_INVOICE_NAME)" >&2
		exit 1
		;;
esac

echo "==> Opportunity Operations agent checks passed"
echo "    discountOpportunityId=$DISCOUNT_OPP_ID"
echo "    invoiceOpportunityId=$INVOICE_OPP_ID"
echo "    invoiceName=$AFTER_INVOICE_NAME"
