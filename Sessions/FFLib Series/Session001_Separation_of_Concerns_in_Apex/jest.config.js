const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

const componentNames = [
  "opportunityApplyDiscount",
  "opportunityCreateInvoice",
  "opportunityInvoiceJob",
  "quickOpportunityWizard"
];

function lwcMapper(packageLwcRoot) {
  const mapper = { ...(jestConfig.moduleNameMapper || {}) };
  for (const name of componentNames) {
    mapper[`^c/${name}$`] = `<rootDir>/${packageLwcRoot}/${name}/${name}`;
  }
  return mapper;
}

module.exports = {
  projects: [
    {
      ...jestConfig,
      displayName: "with-soc",
      testMatch: ["<rootDir>/force-app.with-soc/**/__tests__/**/*.js"],
      modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
      moduleNameMapper: lwcMapper("force-app.with-soc/main/lwc")
    },
    {
      ...jestConfig,
      displayName: "without-soc",
      testMatch: ["<rootDir>/force-app.without-soc/**/__tests__/**/*.js"],
      modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
      moduleNameMapper: lwcMapper("force-app.without-soc/main/default/lwc")
    }
  ]
};
