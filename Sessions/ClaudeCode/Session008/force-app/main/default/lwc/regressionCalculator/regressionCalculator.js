import { LightningElement } from "lwc";
import createRecord from "@salesforce/apex/CalcHistoryController.createRecord";

const OPERATIONS = {
  Add: (a, b) => a + b,
  Subtract: (a, b) => a - b,
  Multiply: (a, b) => a * b,
  Divide: (a, b) => a / b
};

function roundTo2(value) {
  return Math.round(value * 100) / 100;
}

export default class RegressionCalculator extends LightningElement {
  display = "0";
  operand1;
  pendingOperation;
  awaitingOperand2 = false;
  justCalculated = false;
  errorMessage;
  recordId;

  get hasError() {
    return !!this.errorMessage;
  }

  handleDigitClick(event) {
    const digit = event.currentTarget.dataset.value;
    this.errorMessage = undefined;

    if (this.justCalculated) {
      this.display = "0";
      this.justCalculated = false;
    }

    if (this.display === "0" || this.awaitingOperand2) {
      this.display = digit;
      this.awaitingOperand2 = false;
    } else {
      this.display = this.display + digit;
    }
  }

  handleDecimalClick() {
    this.errorMessage = undefined;

    if (this.justCalculated || this.awaitingOperand2) {
      this.display = "0";
      this.justCalculated = false;
      this.awaitingOperand2 = false;
    }

    if (!this.display.includes(".")) {
      this.display = this.display + ".";
    }
  }

  handleOperatorClick(event) {
    const operation = event.currentTarget.dataset.operation;
    this.errorMessage = undefined;
    this.justCalculated = false;

    const currentValue = parseFloat(this.display);
    if (Number.isNaN(currentValue)) {
      this.errorMessage = "Enter a number first.";
      return;
    }

    this.operand1 = currentValue;
    this.pendingOperation = operation;
    this.awaitingOperand2 = true;
  }

  async handleEquals() {
    this.errorMessage = undefined;

    if (this.operand1 === undefined || !this.pendingOperation) {
      return;
    }

    const operand2 = parseFloat(this.display);
    if (Number.isNaN(operand2)) {
      this.errorMessage = "Enter a second number first.";
      return;
    }

    const fn = OPERATIONS[this.pendingOperation];
    const rawResult = fn(this.operand1, operand2);

    if (!Number.isFinite(rawResult)) {
      this.errorMessage = "That calculation did not produce a valid number.";
      this.display = "0";
      this.operand1 = undefined;
      this.pendingOperation = undefined;
      this.awaitingOperand2 = false;
      return;
    }

    const result = roundTo2(rawResult);
    const operationName = this.pendingOperation;
    const operand1 = this.operand1;

    try {
      const recordId = await createRecord({
        number1: operand1,
        number2: operand2,
        operation: operationName,
        answer: result
      });
      this.recordId = recordId;
      this.display = String(result);
    } catch (error) {
      this.display = String(result);
      this.errorMessage = this.extractErrorMessage(error);
    } finally {
      this.operand1 = undefined;
      this.pendingOperation = undefined;
      this.awaitingOperand2 = false;
      this.justCalculated = true;
    }
  }

  handleClear() {
    this.display = "0";
    this.operand1 = undefined;
    this.pendingOperation = undefined;
    this.awaitingOperand2 = false;
    this.justCalculated = false;
    this.errorMessage = undefined;
    this.recordId = undefined;
  }

  extractErrorMessage(error) {
    if (error && error.body) {
      if (
        Array.isArray(error.body) &&
        error.body.length > 0 &&
        error.body[0].message
      ) {
        return error.body[0].message;
      }
      if (error.body.message) {
        return error.body.message;
      }
    }
    return "Unable to save the calculation.";
  }
}
