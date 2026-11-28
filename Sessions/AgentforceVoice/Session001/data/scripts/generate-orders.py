#!/usr/bin/env python3
"""
Generates data/records/orders-NN.json.tpl — Order + nested OrderItem sample
records for the 6 Person Account customers seeded in person-accounts.json.tpl,
chunked to stay under the SObject Tree Save API's 200-records-per-request cap
(an Order plus its OrderItems all count against that limit).

Static output is committed to git (per REQUIREMENTS.md #3.3 / SETUP_GUIDE.md
#4.1): re-run this script only if the sample order data needs to be
regenerated (e.g. to refresh dates relative to a new demo date), then commit
the resulting orders-*.json.tpl files and update
data/plans/02-customers-orders-plan.json's Order "files" list to match.

Usage:
    python3 data/scripts/generate-orders.py data/records
"""

import json
import random
import sys
from datetime import date, timedelta

MAX_RECORDS_PER_FILE = 200

# Anchor "today" for narrative-consistent statuses/dates. Update this (and
# re-run) if the sample data starts to look stale for a future recording date.
TODAY = date(2026, 8, 21)

random.seed(42)

CUSTOMERS = [
    "PersonAccountRef1",
    "PersonAccountRef2",
    "PersonAccountRef3",
    "PersonAccountRef4",
    "PersonAccountRef5",
    "PersonAccountRef6",
]

# (ProductCode, UnitPrice) — must match data/records/products.json /
# pricebook-entries.json.tpl. OrderItem.PricebookEntryId can't use an @Ref
# token here: refs only resolve on top-level record fields, not on fields
# inside a nested child (OrderItems.records[].PricebookEntryId) — confirmed
# empirically against sally-prep (AccountId, a top-level Order field, resolved
# fine via @PersonAccountRefN in the same run; PricebookEntryId, nested one
# level deeper, did not — MALFORMED_ID). So these render as
# ${PRICEBOOK_ENTRY_ID_<ProductCode>} placeholders that load-data.sh fills in
# with real Ids queried right after 01-products-plan.json runs.
PRODUCTS = [
    ("TENT-AP2", 349.0),
    ("PACK-ST65", 259.0),
    ("STOVE-BL1", 89.0),
    ("FILTER-SP3", 59.0),
    ("BAG-FG20", 189.0),
    ("LAMP-TB500", 45.0),
    ("BOOT-RL7", 175.0),
    ("CHAIR-BC4", 129.0),
]


def pbe_placeholder(sku):
    return "${PRICEBOOK_ENTRY_ID_%s}" % sku.replace("-", "_")


STATUS_WEIGHTS = [
    ("Delivered", 0.45),
    ("In Transit", 0.25),
    ("Processing", 0.25),
    ("Cancelled", 0.05),
]


def pick_status():
    r = random.random()
    cum = 0.0
    for status, weight in STATUS_WEIGHTS:
        cum += weight
        if r <= cum:
            return status
    return STATUS_WEIGHTS[-1][0]


def dates_for_status(status):
    if status == "Delivered":
        effective = TODAY - timedelta(days=random.randint(15, 80))
        delivery = effective + timedelta(days=random.randint(3, 8))
    elif status == "In Transit":
        effective = TODAY - timedelta(days=random.randint(2, 6))
        delivery = TODAY + timedelta(days=random.randint(0, 4))
    elif status == "Processing":
        effective = TODAY - timedelta(days=random.randint(0, 2))
        delivery = TODAY + timedelta(days=random.randint(5, 10))
    else:  # Cancelled
        effective = TODAY - timedelta(days=random.randint(5, 40))
        delivery = effective + timedelta(days=random.randint(3, 8))
    return effective, delivery


def build_order(order_ref, account_ref):
    status = pick_status()
    effective, delivery = dates_for_status(status)

    item_count = random.randint(2, 4)
    chosen = random.sample(PRODUCTS, item_count)

    items = []
    for i, (sku, unit_price) in enumerate(chosen, start=1):
        qty = random.randint(1, 3)
        items.append(
            {
                "attributes": {
                    "type": "OrderItem",
                    "referenceId": f"{order_ref}Item{i}",
                },
                "PricebookEntryId": pbe_placeholder(sku),
                "Quantity": qty,
                "UnitPrice": unit_price,
                # TotalPrice is system-calculated (Quantity * UnitPrice) —
                # the API rejects it on insert (INVALID_FIELD_FOR_INSERT_UPDATE).
            }
        )

    return {
        "attributes": {"type": "Order", "referenceId": order_ref},
        "AccountId": f"@{account_ref}",
        "Pricebook2Id": "${STANDARD_PRICEBOOK_ID}",
        "EffectiveDate": effective.isoformat(),
        # Orders must be inserted as Draft — the API rejects Activated on
        # insert ("FAILED_ACTIVATION ... choose Draft"). load-data.sh
        # activates them in a follow-up update via activate-orders.apex.
        "Status": "Draft",
        "Fulfillment_Status__c": status,
        "Estimated_Delivery_Date__c": delivery.isoformat(),
        "OrderItems": {"records": items},
    }


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."

    orders = []
    order_num = 1
    for account_ref in CUSTOMERS:
        num_orders = random.randint(10, 20)
        for _ in range(num_orders):
            order_ref = f"OrderRef{order_num}"
            orders.append(build_order(order_ref, account_ref))
            order_num += 1

    # Greedily pack orders into files, each staying at or under the API's
    # per-request record cap (1 Order record + its nested OrderItem records).
    chunks = []
    current_chunk = []
    current_count = 0
    for order in orders:
        order_size = 1 + len(order["OrderItems"]["records"])
        if current_chunk and current_count + order_size > MAX_RECORDS_PER_FILE:
            chunks.append(current_chunk)
            current_chunk = []
            current_count = 0
        current_chunk.append(order)
        current_count += order_size
    if current_chunk:
        chunks.append(current_chunk)

    filenames = []
    for i, chunk in enumerate(chunks, start=1):
        filename = f"orders-{i:02d}.json.tpl"
        filenames.append(filename)
        with open(f"{out_dir}/{filename}", "w") as f:
            json.dump({"records": chunk}, f, indent=2)
            f.write("\n")

    total_orders = len(orders)
    total_records = sum(1 + len(o["OrderItems"]["records"]) for o in orders)
    print(
        f"wrote {len(chunks)} file(s) for {total_orders} orders "
        f"({total_records} total Order+OrderItem records): {', '.join(filenames)}",
        file=sys.stderr,
    )


if __name__ == "__main__":
    main()
