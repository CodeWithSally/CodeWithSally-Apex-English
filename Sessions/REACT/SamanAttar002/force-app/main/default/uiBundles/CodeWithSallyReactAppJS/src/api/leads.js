/**
 * Calls the Apex REST endpoint to create a Lead from the Contact Us form.
 *
 * createDataSDK() gives us data.fetch() — window.fetch pre-wired with the org's
 * instance URL and bearer token — so a relative path resolves to your org and
 * is authenticated automatically.
 */
import { createDataSDK } from '@salesforce/sdk-data';

// POST /services/apexrest/lead — `input` has { firstName, lastName, email, message? },
// matching the parameters of LeadResource.createLead on the Apex side.
export async function createLead(input) {
  const data = await createDataSDK();
  const response = await data.fetch?.('/services/apexrest/lead', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(input),
  });
  if (!response?.ok) {
    throw new Error(`Lead create failed: ${response?.status}`);
  }
  return response.json();
}
