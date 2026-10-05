import { createElement } from "lwc";
import RegressionCalculator from "c/regressionCalculator";
import createRecord from "@salesforce/apex/CalcHistoryController.createRecord";

jest.mock(
    "@salesforce/apex/CalcHistoryController.createRecord",
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const INVALID_RESULT_MESSAGE = "That calculation did not produce a valid number.";
const DEFAULT_SAVE_ERROR = "Unable to save the calculation.";

// Maps the keys used in test sequences to the button data-ids in the template.
const KEY_TO_DATA_ID = {
    "+": "add-button",
    "-": "subtract-button",
    "*": "multiply-button",
    "/": "divide-button",
    "=": "equals-button",
    ".": "decimal-button",
    C: "clear-button"
};

function flushPromises() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    return new Promise((resolve) => setTimeout(resolve, 0));
}

function createCalculator() {
    const element = createElement("c-regression-calculator", {
        is: RegressionCalculator
    });
    document.body.appendChild(element);
    return element;
}

// Clicks each key in order, e.g. press(element, "12+3=").
async function press(element, keys) {
    for (const key of keys) {
        const dataId = KEY_TO_DATA_ID[key] || `digit-${key}`;
        const button = element.shadowRoot.querySelector(`[data-id="${dataId}"]`);
        if (!button) {
            throw new Error(`No button for key "${key}"`);
        }
        button.click();
        // eslint-disable-next-line no-await-in-loop
        await flushPromises();
    }
}

function screenText(element) {
    return element.shadowRoot.querySelector('[data-id="screen"]').textContent;
}

function errorElement(element) {
    return element.shadowRoot.querySelector('[data-id="error-message"]');
}

function errorText(element) {
    const error = errorElement(element);
    return error ? error.textContent.trim() : null;
}

describe("c-regression-calculator", () => {
    beforeEach(() => {
        createRecord.mockResolvedValue("a00000000000001AAA");
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    describe("initial render", () => {
        it("shows 0 on the screen", () => {
            const element = createCalculator();
            expect(screenText(element)).toBe("0");
        });

        it("does not render an error message", () => {
            const element = createCalculator();
            expect(errorElement(element)).toBeNull();
        });
    });

    describe("digit entry", () => {
        it("replaces the leading 0 with the first digit", async () => {
            const element = createCalculator();
            await press(element, "7");
            expect(screenText(element)).toBe("7");
        });

        it("appends subsequent digits", async () => {
            const element = createCalculator();
            await press(element, "123");
            expect(screenText(element)).toBe("123");
        });

        it("collapses leading zeros", async () => {
            const element = createCalculator();
            await press(element, "005");
            expect(screenText(element)).toBe("5");
        });
    });

    describe("decimal entry", () => {
        it("shows 0. when decimal is pressed on a fresh screen", async () => {
            const element = createCalculator();
            await press(element, ".");
            expect(screenText(element)).toBe("0.");
        });

        it("builds a decimal number", async () => {
            const element = createCalculator();
            await press(element, "1.5");
            expect(screenText(element)).toBe("1.5");
        });

        it("ignores a second decimal point", async () => {
            const element = createCalculator();
            await press(element, "1..5");
            expect(screenText(element)).toBe("1.5");
        });

        it("starts the second operand as 0. when decimal follows an operator", async () => {
            const element = createCalculator();
            await press(element, "5+.");
            expect(screenText(element)).toBe("0.");

            await press(element, "5=");
            expect(createRecord).toHaveBeenCalledWith(
                expect.objectContaining({ number1: 5, number2: 0.5, answer: 5.5 })
            );
        });
    });

    describe("operations", () => {
        it.each([
            ["2+3=", 2, 3, "Add", 5],
            ["9-4=", 9, 4, "Subtract", 5],
            ["6*7=", 6, 7, "Multiply", 42],
            ["8/2=", 8, 2, "Divide", 4]
        ])("%s displays the result and saves it", async (keys, number1, number2, operation, answer) => {
            const element = createCalculator();
            await press(element, keys);

            expect(screenText(element)).toBe(String(answer));
            expect(createRecord).toHaveBeenCalledTimes(1);
            expect(createRecord).toHaveBeenCalledWith({ number1, number2, operation, answer });
        });

        it("keeps the first operand on screen until the second operand is typed", async () => {
            const element = createCalculator();
            await press(element, "12+");
            expect(screenText(element)).toBe("12");

            await press(element, "3");
            expect(screenText(element)).toBe("3");
        });

        it("uses the last operator pressed when operators are pressed back to back", async () => {
            const element = createCalculator();
            await press(element, "5+*3=");
            expect(screenText(element)).toBe("15");
            expect(createRecord).toHaveBeenCalledWith(expect.objectContaining({ operation: "Multiply" }));
        });

        // Current behaviour: operators do not chain. The second operator replaces
        // operand 1 with the number on screen, so the 2 is dropped.
        it("does not chain operations (2+3+4= gives 7)", async () => {
            const element = createCalculator();
            await press(element, "2+3+4=");
            expect(screenText(element)).toBe("7");
            expect(createRecord).toHaveBeenCalledTimes(1);
            expect(createRecord).toHaveBeenCalledWith(
                expect.objectContaining({ number1: 3, number2: 4, operation: "Add", answer: 7 })
            );
        });

        // Current behaviour: pressing equals straight after an operator reuses
        // the number on screen as operand 2.
        it("reuses the on-screen number when equals follows an operator (5+= gives 10)", async () => {
            const element = createCalculator();
            await press(element, "5+=");
            expect(screenText(element)).toBe("10");
            expect(createRecord).toHaveBeenCalledWith({ number1: 5, number2: 5, operation: "Add", answer: 10 });
        });
    });

    describe("result formatting", () => {
        it("rounds results to 2 decimal places", async () => {
            const element = createCalculator();
            await press(element, "10/3=");
            expect(screenText(element)).toBe("3.33");
            expect(createRecord).toHaveBeenCalledWith(expect.objectContaining({ answer: 3.33 }));
        });

        it("rounds up at the second decimal place", async () => {
            const element = createCalculator();
            await press(element, "2/3=");
            expect(screenText(element)).toBe("0.67");
        });

        it("hides floating point noise", async () => {
            const element = createCalculator();
            await press(element, ".1+.2=");
            expect(screenText(element)).toBe("0.3");
        });

        it("displays negative results", async () => {
            const element = createCalculator();
            await press(element, "3-5=");
            expect(screenText(element)).toBe("-2");
            expect(createRecord).toHaveBeenCalledWith(expect.objectContaining({ answer: -2 }));
        });
    });

    describe("after a calculation", () => {
        it("starts a new number when a digit is pressed", async () => {
            const element = createCalculator();
            await press(element, "2+3=7");
            expect(screenText(element)).toBe("7");
        });

        it("starts 0. when decimal is pressed", async () => {
            const element = createCalculator();
            await press(element, "2+3=.");
            expect(screenText(element)).toBe("0.");
        });

        it("uses the result as the first operand when an operator is pressed", async () => {
            const element = createCalculator();
            await press(element, "2+3=*4=");
            expect(screenText(element)).toBe("20");
            expect(createRecord).toHaveBeenCalledTimes(2);
            expect(createRecord).toHaveBeenLastCalledWith({
                number1: 5,
                number2: 4,
                operation: "Multiply",
                answer: 20
            });
        });

        it("ignores a repeated equals press", async () => {
            const element = createCalculator();
            await press(element, "2+3==");
            expect(screenText(element)).toBe("5");
            expect(createRecord).toHaveBeenCalledTimes(1);
        });
    });

    describe("equals with nothing pending", () => {
        it("does nothing on a fresh screen", async () => {
            const element = createCalculator();
            await press(element, "=");
            expect(screenText(element)).toBe("0");
            expect(errorElement(element)).toBeNull();
            expect(createRecord).not.toHaveBeenCalled();
        });

        it("does nothing when no operator was chosen", async () => {
            const element = createCalculator();
            await press(element, "5=");
            expect(screenText(element)).toBe("5");
            expect(createRecord).not.toHaveBeenCalled();
        });
    });

    describe("invalid results", () => {
        it.each([
            ["divide by zero", "5/0="],
            ["zero divided by zero", "0/0="]
        ])("%s shows an error, resets the screen and does not save", async (label, keys) => {
            const element = createCalculator();
            await press(element, keys);

            expect(errorText(element)).toBe(INVALID_RESULT_MESSAGE);
            expect(screenText(element)).toBe("0");
            expect(createRecord).not.toHaveBeenCalled();
        });

        it("drops the pending operation so the next calculation starts clean", async () => {
            const element = createCalculator();
            await press(element, "5/0=");

            // With the division cleared, equals alone must not calculate anything.
            await press(element, "=");
            expect(createRecord).not.toHaveBeenCalled();

            await press(element, "2+2=");
            expect(screenText(element)).toBe("4");
            expect(errorElement(element)).toBeNull();
            expect(createRecord).toHaveBeenCalledTimes(1);
        });
    });

    describe("Apex save failures", () => {
        it.each([
            ["an array body", { body: [{ message: "Array error" }] }, "Array error"],
            ["an object body", { body: { message: "Object error" } }, "Object error"],
            ["an empty array body", { body: [] }, DEFAULT_SAVE_ERROR],
            ["no body", new Error("boom"), DEFAULT_SAVE_ERROR],
            ["an undefined error", undefined, DEFAULT_SAVE_ERROR]
        ])("shows the right message for %s", async (label, error, expected) => {
            createRecord.mockRejectedValue(error);
            const element = createCalculator();
            await press(element, "2+3=");

            expect(errorText(element)).toBe(expected);
        });

        it("still displays the result", async () => {
            createRecord.mockRejectedValue({ body: { message: "Save failed" } });
            const element = createCalculator();
            await press(element, "2+3=");

            expect(screenText(element)).toBe("5");
        });

        it("still finishes the calculation so the next digit starts a new number", async () => {
            createRecord.mockRejectedValue({ body: { message: "Save failed" } });
            const element = createCalculator();
            await press(element, "2+3=7");

            expect(screenText(element)).toBe("7");
            expect(errorElement(element)).toBeNull();
        });
    });

    describe("error clearing", () => {
        it.each([
            ["a digit", "7"],
            ["decimal", "."],
            ["an operator", "+"],
            ["clear", "C"]
        ])("clears the error when %s is pressed", async (label, key) => {
            const element = createCalculator();
            await press(element, "5/0=");
            expect(errorText(element)).toBe(INVALID_RESULT_MESSAGE);

            await press(element, key);
            expect(errorElement(element)).toBeNull();
        });
    });

    describe("clear", () => {
        it("resets the screen to 0", async () => {
            const element = createCalculator();
            await press(element, "123C");
            expect(screenText(element)).toBe("0");
        });

        it("discards a pending operation", async () => {
            const element = createCalculator();
            await press(element, "5+C3=");
            expect(screenText(element)).toBe("3");
            expect(createRecord).not.toHaveBeenCalled();
        });

        it("resets the screen after a result", async () => {
            const element = createCalculator();
            await press(element, "2+3=C");
            expect(screenText(element)).toBe("0");
        });
    });
});
