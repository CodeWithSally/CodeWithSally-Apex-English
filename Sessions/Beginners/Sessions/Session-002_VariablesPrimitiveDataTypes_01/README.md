# Salesforce Apex: Variables & Primitive Data Types - Part 1

## 🚀 Overview
Session 2 of the Beginners series. This session covers:
✔ What a **variable** is (a labelled container for a value)
✔ **Declaration vs. initialization**
✔ **Primitive vs. complex** data types
✔ Whole numbers: **Integer** and **Long**
✔ Decimal numbers: **Decimal** and **Double**
✔ Text: **String**, concatenation with `+`, and String methods
✔ Using the Apex documentation to find **data type methods**

## 🔥 Live Code Examples in This Session
Run each file in the Developer Console (Debug, Open Execute Anonymous Window), tick **Open Log**, then **Debug Only**.

| File | What it shows | Debug output in the session |
|---|---|---|
| `01_Integer.apex` | Initialize an Integer, `Integer.valueOf` (String to Integer), update a variable | `Check Age: 22`, `myInt: 123`, `Updated myInt: 125` |
| `02_Long_TryIt.apex` | Integer vs. Long (from the blog). **Try it:** remove the `L` at the end of the Long value and run it again | Without the `L`: `Illegal integer` |
| `03_DecimalVsDouble.apex` | The same 17-decimal value in a Decimal and a Double | Decimal keeps `...979396`, Double shows `3.141592653589794` |
| `04_DecimalIntValue.apex` | `intValue()` keeps the whole-number part, no rounding | `3`, `1` |
| `05_StringBasics.apex` | A String holding a sentence | `Hello, coding to our 1st session!` |
| `06_StringConcatenation.apex` | Joining Strings with `+` | `Welcome Note Value: Welcome to my Online Session : Sally Elghoul` |
| `07_StringToLowerCase.apex` | `toLowerCase()` | `Lower:hello coding crew!` |
| `08_StringMethods.apex` | `length()`, `substring(startIndex, endIndex)`, `toUpperCase()`, `toLowerCase()` | `16`, `Sale`, `HELLO SALESFORCE`, `hello salesforce` |
| `09_StringContains.apex` | `contains()`. **Try it:** change `'Crew'` to a word that is not in the text | `Value:true` |

## 📌 Resources
🎥 **Watch the Full Session on YouTube**: [https://youtu.be/ixx8AUy9p5Y](https://youtu.be/ixx8AUy9p5Y)
📖 **Primitive Data Types guide**: [https://codewithsally.com/beginners-guide/salesforce-primitive-data-types-guide-beginners/](https://codewithsally.com/beginners-guide/salesforce-primitive-data-types-guide-beginners/)
🔗 **More Salesforce Apex Tutorials**: [https://codewithsally.com/](https://codewithsally.com/)
