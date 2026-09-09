import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import startJob from "@salesforce/apex/DispatchPendingJobController.startJob";

export default class WarehouseDispatchJob extends LightningElement {
  @api recordId;

  _isExecuting = false;

  @api
  async invoke() {
    if (this._isExecuting) {
      return;
    }
    this._isExecuting = true;
    try {
      await startJob();
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Dispatch job submitted",
          message: "Active warehouses will be dispatched in the background.",
          variant: "success"
        })
      );
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error submitting dispatch job",
          message: this.reduceError(error),
          variant: "error"
        })
      );
    } finally {
      this._isExecuting = false;
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
