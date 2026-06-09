/**
 * Thin GraphQL client: createDataSDK + data.graphql with centralized error handling.
 * Use with gql-tagged queries.
 */
import { createDataSDK } from '@salesforce/sdk-data';
export async function executeGraphQL(query, variables) {
  const data = await createDataSDK();
  const response = await data.graphql?.(query, variables);
  if (!response) {
    throw new Error('GraphQL response is undefined');
  }
  // A request-level failure (e.g. a 400) comes back as an array of
  // { errorCode, message }, not the usual { data, errors } shape. Surface it
  // here so the real reason isn't hidden behind a later "undefined" error.
  if (Array.isArray(response)) {
    const msg = response.map(e => e.message ?? e.errorCode).join('; ');
    throw new Error(`GraphQL request failed: ${msg}`);
  }
  if (response.errors?.length) {
    const msg = response.errors.map(e => e.message).join('; ');
    throw new Error(`GraphQL Error: ${msg}`);
  }
  if (!response.data) {
    throw new Error('GraphQL response contained no data');
  }
  return response.data;
}
