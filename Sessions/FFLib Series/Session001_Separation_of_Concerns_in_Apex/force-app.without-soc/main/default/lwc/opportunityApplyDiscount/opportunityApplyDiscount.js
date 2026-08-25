import { LightningElement, api, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, getFieldValue, updateRecord, notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import AMOUNT_FIELD from "@salesforce/schema/Opportunity.Amount";
import DISCOUNT_TYPE_FIELD from "@salesforce/schema/Opportunity.DiscountType__c";

const OPP_FIELDS = [AMOUNT_FIELD, DISCOUNT_TYPE_FIELD];
const LINE_ITEM_FIELDS = [
  "OpportunityLineItem.Id",
  "OpportunityLineItem.UnitPrice",
  "OpportunityLineItem.PricebookEntry.Product2.DiscountingApproved__c"
];

export default class OpportunityApplyDiscount extends LightningElement {
  _recordId;
  discountPercentage;
  isSaving = false;

  @api
  get recordId() {
    return this._recordId;
  }
  set recordId(value) {
    this._recordId = value;
  }

  @wire(getRecord, { recordId: "$_recordId", fields: OPP_FIELDS })
  wiredOpportunity;

  @wire(getRelatedListRecords, {
    parentRecordId: "$_recordId",
    relatedListId: "OpportunityLineItems",
    fields: LINE_ITEM_FIELDS
  })
  wiredLineItems;

  handleDiscountChange(event) {
    this.discountPercentage = event.detail.value;
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async handleApply() {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      const opportunity = this.wiredOpportunity?.data;
      if (!opportunity) {
        throw new Error(
          this.reduceError(this.wiredOpportunity?.error) || "Opportunity has not loaded yet."
        );
      }
      if (this.wiredLineItems?.error) {
        throw new Error(this.reduceError(this.wiredLineItems.error));
      }

      const factor =
        1 - (this.discountPercentage == null || this.discountPercentage === "" ? 0 : Number(this.discountPercentage) / 100);
      const discountType = getFieldValue(opportunity, DISCOUNT_TYPE_FIELD);
      const lines = this.wiredLineItems?.data?.records || [];
      const recordsToUpdate = [];

      if (lines.length === 0) {
        const amount = getFieldValue(opportunity, AMOUNT_FIELD);
        recordsToUpdate.push({
          fields: {
            Id: this._recordId,
            Amount: amount == null ? null : amount * factor
          }
        });
      } else {
        for (const line of lines) {
          const approved = this.relatedFieldValue(
            line,
            "PricebookEntry.Product2.DiscountingApproved__c"
          );
          if (discountType === "Approved Products" && !approved) {
            continue;
          }
          const unitPrice = this.relatedFieldValue(line, "UnitPrice");
          recordsToUpdate.push({
            fields: {
              Id: line.id,
              UnitPrice: unitPrice == null ? null : unitPrice * factor
            }
          });
        }
      }

      await Promise.all(recordsToUpdate.map((record) => updateRecord(record)));
      await notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Discount applied.",
          variant: "success"
        })
      );
      this.dispatchEvent(new CloseActionScreenEvent());
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error applying discount",
          message: this.reduceError(error),
          variant: "error"
        })
      );
    } finally {
      this.isSaving = false;
    }
  }

  relatedFieldValue(record, path) {
    let current = record;
    for (const part of path.split(".")) {
      if (current == null) {
        return undefined;
      }
      if (current.fields && current.fields[part] !== undefined) {
        current = current.fields[part].value;
      } else {
        return undefined;
      }
    }
    return current;
  }

  reduceError(error) {
    if (typeof error === "string") {
      return error;
    }
    if (Array.isArray(error.body)) {
      return error.body.map((e) => e.message).join(", ");
    }
    return error?.body?.message || error?.message || "Unknown error";
  }
}
