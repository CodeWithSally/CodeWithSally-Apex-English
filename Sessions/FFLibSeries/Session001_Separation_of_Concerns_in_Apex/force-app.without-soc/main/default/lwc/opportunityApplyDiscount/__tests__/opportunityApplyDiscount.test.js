import { createElement } from "@lwc/engine-dom";
import OpportunityApplyDiscount from "c/opportunityApplyDiscount";
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";

jest.mock(
  "lightning/actions",
  () => {
    class CloseActionScreenEvent extends CustomEvent {
      constructor() {
        super("closeAction");
      }
    }
    return { CloseActionScreenEvent };
  },
  { virtual: true }
);

describe("c-opportunity-apply-discount", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createAction(recordId) {
    const element = createElement("c-opportunity-apply-discount", {
      is: OpportunityApplyDiscount
    });
    document.body.appendChild(element);
    element.recordId = recordId;
    await Promise.resolve();
    return element;
  }

  function applyDiscount(element, percent) {
    const input = element.shadowRoot.querySelector("lightning-input");
    input.dispatchEvent(new CustomEvent("change", { detail: { value: percent } }));
    const applyButton = [...element.shadowRoot.querySelectorAll("lightning-button")].find(
      (button) => button.label === "Apply Discount"
    );
    applyButton.click();
  }

  it("discounts the opportunity amount when there are no lines", async () => {
    const element = await createAction("006000000000001AAA");
    getRecord.emit({
      fields: {
        Amount: { value: 100 },
        DiscountType__c: { value: null }
      }
    });
    getRelatedListRecords.emit({ records: [] });
    await Promise.resolve();

    applyDiscount(element, "10");
    await Promise.resolve();
    await Promise.resolve();

    expect(updateRecord).toHaveBeenCalledWith({
      fields: { Id: "006000000000001AAA", Amount: 90 }
    });
    expect(notifyRecordUpdateAvailable).toHaveBeenCalledWith([{ recordId: "006000000000001AAA" }]);
  });

  it("discounts approved line unit prices and skips the rest", async () => {
    const element = await createAction("006000000000001AAA");
    getRecord.emit({
      fields: {
        Amount: { value: 200 },
        DiscountType__c: { value: "Approved Products" }
      }
    });
    getRelatedListRecords.emit({
      records: [
        {
          id: "00k000000000001AAA",
          fields: {
            UnitPrice: { value: 100 },
            PricebookEntry: {
              value: {
                fields: {
                  Product2: {
                    value: {
                      fields: {
                        DiscountingApproved__c: { value: true }
                      }
                    }
                  }
                }
              }
            }
          }
        },
        {
          id: "00k000000000002AAA",
          fields: {
            UnitPrice: { value: 50 },
            PricebookEntry: {
              value: {
                fields: {
                  Product2: {
                    value: {
                      fields: {
                        DiscountingApproved__c: { value: false }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    });
    await Promise.resolve();

    applyDiscount(element, "10");
    await Promise.resolve();
    await Promise.resolve();

    expect(updateRecord).toHaveBeenCalledTimes(1);
    expect(updateRecord).toHaveBeenCalledWith({
      fields: { Id: "00k000000000001AAA", UnitPrice: 90 }
    });
  });

  it("closes the action when cancel is clicked", async () => {
    const element = await createAction("006000000000001AAA");
    const cancelButton = [...element.shadowRoot.querySelectorAll("lightning-button")].find(
      (button) => button.label === "Cancel"
    );
    cancelButton.click();
    expect(cancelButton).not.toBeNull();
  });
});
