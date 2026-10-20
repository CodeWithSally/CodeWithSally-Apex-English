import { LightningElement, api } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import dispatchWarehouse from "@salesforce/apex/WarehouseDispatchController.dispatchWarehouse";

export default class WarehouseDispatch extends LightningElement {
  @api recordId;
  isSaving = false;

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async handleDispatch() {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await dispatchWarehouse({ warehouseId: this.recordId });
      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Warehouse dispatched.",
          variant: "success"
        })
      );
      this.dispatchEvent(new CloseActionScreenEvent());
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error dispatching warehouse",
          message: this.reduceError(error),
          variant: "error"
        })
      );
    } finally {
      this.isSaving = false;
    }
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
