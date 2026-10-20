import { LightningElement, api } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import completeJob from "@salesforce/apex/MaintenanceCompleteController.completeJob";

export default class MaintenanceComplete extends LightningElement {
  @api recordId;
  isSaving = false;

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async handleComplete() {
    if (this.isSaving) {
      return;
    }
    this.isSaving = true;
    try {
      await completeJob({ jobId: this.recordId });
      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Service completed.",
          variant: "success"
        })
      );
      this.dispatchEvent(new CloseActionScreenEvent());
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error completing service",
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
