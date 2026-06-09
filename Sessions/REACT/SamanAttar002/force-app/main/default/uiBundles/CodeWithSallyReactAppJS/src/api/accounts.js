import { gql } from '@salesforce/sdk-data';
import { executeGraphQL } from './graphqlClient';
const GET_ACCOUNTS = gql`
  query GetAccounts($first: Int = 10) {
    uiapi {
      query {
        Account(first: $first, orderBy: { Name: { order: ASC } }) {
          edges {
            node {
              Id
              Name {
                value
              }
              Industry {
                value
              }
              AnnualRevenue {
                value
                displayValue
              }
            }
          }
        }
      }
    }
  }
`;
export function getAccounts(first = 10) {
  return executeGraphQL(GET_ACCOUNTS, {
    first,
  });
}
const UPDATE_ACCOUNT = gql`
  mutation UpdateAccount(
    $id: IdOrRef!
    $account: AccountUpdateRepresentation!
  ) {
    uiapi {
      AccountUpdate(input: { Id: $id, Account: $account }) {
        success
        Record {
          Id
          Name {
            value
          }
          Industry {
            value
          }
          AnnualRevenue {
            displayValue
          }
        }
      }
    }
  }
`;

// `account` holds the fields to change, e.g. { Name, Industry, AnnualRevenue } —
// only what UPDATE_ACCOUNT sends.
export function updateAccount(id, account) {
  return executeGraphQL(UPDATE_ACCOUNT, {
    id,
    account,
  });
}
