import { gql } from '@salesforce/sdk-data';
import { executeGraphQL } from './graphqlClient';
import type {
  GetAccountsQuery,
  GetAccountsQueryVariables,
  UpdateAccountMutation,
  UpdateAccountMutationVariables,
} from './graphql-operations-types';

const GET_ACCOUNTS = gql`
  query GetAccounts($first: Int = 10) {
    uiapi {
      query {
        Account(first: $first, orderBy: { Name: { order: ASC } }) {
          edges {
            node {
              Id
              Name { value }
              Industry { value }
              AnnualRevenue { value displayValue }
            }
          }
        }
      }
    }
  }
`;

export function getAccounts(first = 10) {
  return executeGraphQL<GetAccountsQuery, GetAccountsQueryVariables>(GET_ACCOUNTS, { first });
}

const UPDATE_ACCOUNT = gql`
  mutation UpdateAccount($id: IdOrRef!, $account: AccountUpdateRepresentation!) {
    uiapi {
      AccountUpdate(input: { Id: $id, Account: $account }) {
        success
        Record {
          Id
          Name { value }
          Industry { value }
          AnnualRevenue { displayValue }
        }
      }
    }
  }
`;

// The fields you can change on a row. Derived from the generated mutation variables
// so it stays in sync with the schema (only what UPDATE_ACCOUNT sends).
export type AccountUpdateFields = UpdateAccountMutationVariables['account'];

export function updateAccount(id: string, account: AccountUpdateFields) {
  return executeGraphQL<UpdateAccountMutation, UpdateAccountMutationVariables>(UPDATE_ACCOUNT, {
    id,
    account,
  });
}
