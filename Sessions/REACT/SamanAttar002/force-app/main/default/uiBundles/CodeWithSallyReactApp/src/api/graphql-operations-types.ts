export type Maybe<T> = T | null;
export type InputMaybe<T> = Maybe<T>;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]?: Maybe<T[SubKey]> };
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]: Maybe<T[SubKey]> };
export type MakeEmpty<T extends { [key: string]: unknown }, K extends keyof T> = { [_ in K]?: never };
export type Incremental<T> = T | { [P in keyof T]?: P extends ' $fragmentName' | '__typename' ? T[P] : never };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: { input: string; output: string; }
  String: { input: string; output: string; }
  Boolean: { input: boolean; output: boolean; }
  Int: { input: number; output: number; }
  Float: { input: number; output: number; }
  Base64: { input: string; output: string; }
  Currency: { input: number | string; output: number; }
  Date: { input: string; output: string; }
  DateTime: { input: string; output: string; }
  Double: { input: number | string; output: number; }
  Email: { input: string; output: string; }
  EncryptedString: { input: string; output: string; }
  /** Can be set to an ID or a Reference to the result of another mutation operation. */
  IdOrRef: { input: string; output: string; }
  Latitude: { input: number | string; output: number; }
  /** A 64-bit signed integer */
  Long: { input: number; output: number; }
  LongTextArea: { input: string; output: string; }
  Longitude: { input: number | string; output: number; }
  MultiPicklist: { input: string; output: string; }
  Percent: { input: number | string; output: number; }
  PhoneNumber: { input: string; output: string; }
  Picklist: { input: string; output: string; }
  RichTextArea: { input: string; output: string; }
  TextArea: { input: string; output: string; }
  Time: { input: string; output: string; }
  Url: { input: string; output: string; }
};

export type AccountUpdateRepresentation = {
  AccountNumber?: InputMaybe<Scalars['String']['input']>;
  AccountSource?: InputMaybe<Scalars['Picklist']['input']>;
  AnnualRevenue?: InputMaybe<Scalars['Currency']['input']>;
  BillingCity?: InputMaybe<Scalars['String']['input']>;
  BillingCountry?: InputMaybe<Scalars['String']['input']>;
  BillingGeocodeAccuracy?: InputMaybe<Scalars['Picklist']['input']>;
  BillingLatitude?: InputMaybe<Scalars['Latitude']['input']>;
  BillingLongitude?: InputMaybe<Scalars['Longitude']['input']>;
  BillingPostalCode?: InputMaybe<Scalars['String']['input']>;
  BillingState?: InputMaybe<Scalars['String']['input']>;
  BillingStreet?: InputMaybe<Scalars['TextArea']['input']>;
  CleanStatus?: InputMaybe<Scalars['Picklist']['input']>;
  DandbCompanyId?: InputMaybe<Scalars['IdOrRef']['input']>;
  Description?: InputMaybe<Scalars['LongTextArea']['input']>;
  DunsNumber?: InputMaybe<Scalars['String']['input']>;
  Fax?: InputMaybe<Scalars['PhoneNumber']['input']>;
  Industry?: InputMaybe<Scalars['Picklist']['input']>;
  Jigsaw?: InputMaybe<Scalars['String']['input']>;
  NaicsCode?: InputMaybe<Scalars['String']['input']>;
  NaicsDesc?: InputMaybe<Scalars['String']['input']>;
  Name?: InputMaybe<Scalars['String']['input']>;
  NumberOfEmployees?: InputMaybe<Scalars['Int']['input']>;
  OperatingHoursId?: InputMaybe<Scalars['IdOrRef']['input']>;
  OwnerId?: InputMaybe<Scalars['IdOrRef']['input']>;
  Ownership?: InputMaybe<Scalars['Picklist']['input']>;
  ParentId?: InputMaybe<Scalars['IdOrRef']['input']>;
  Phone?: InputMaybe<Scalars['PhoneNumber']['input']>;
  Rating?: InputMaybe<Scalars['Picklist']['input']>;
  ShippingCity?: InputMaybe<Scalars['String']['input']>;
  ShippingCountry?: InputMaybe<Scalars['String']['input']>;
  ShippingGeocodeAccuracy?: InputMaybe<Scalars['Picklist']['input']>;
  ShippingLatitude?: InputMaybe<Scalars['Latitude']['input']>;
  ShippingLongitude?: InputMaybe<Scalars['Longitude']['input']>;
  ShippingPostalCode?: InputMaybe<Scalars['String']['input']>;
  ShippingState?: InputMaybe<Scalars['String']['input']>;
  ShippingStreet?: InputMaybe<Scalars['TextArea']['input']>;
  Sic?: InputMaybe<Scalars['String']['input']>;
  SicDesc?: InputMaybe<Scalars['String']['input']>;
  Site?: InputMaybe<Scalars['String']['input']>;
  TickerSymbol?: InputMaybe<Scalars['String']['input']>;
  Tradestyle?: InputMaybe<Scalars['String']['input']>;
  Type?: InputMaybe<Scalars['Picklist']['input']>;
  Website?: InputMaybe<Scalars['Url']['input']>;
  YearStarted?: InputMaybe<Scalars['String']['input']>;
};

export enum DataType {
  Address = 'ADDRESS',
  Anytype = 'ANYTYPE',
  Base64 = 'BASE64',
  Boolean = 'BOOLEAN',
  Combobox = 'COMBOBOX',
  Complexvalue = 'COMPLEXVALUE',
  Currency = 'CURRENCY',
  Date = 'DATE',
  Datetime = 'DATETIME',
  Double = 'DOUBLE',
  Email = 'EMAIL',
  Encryptedstring = 'ENCRYPTEDSTRING',
  Int = 'INT',
  Json = 'JSON',
  Junctionidlist = 'JUNCTIONIDLIST',
  Location = 'LOCATION',
  Long = 'LONG',
  Multipicklist = 'MULTIPICKLIST',
  Percent = 'PERCENT',
  Phone = 'PHONE',
  Picklist = 'PICKLIST',
  Reference = 'REFERENCE',
  String = 'STRING',
  Textarea = 'TEXTAREA',
  Time = 'TIME',
  Url = 'URL'
}

export enum FieldExtraTypeInfo {
  ExternalLookup = 'EXTERNAL_LOOKUP',
  ImageUrl = 'IMAGE_URL',
  IndirectLookup = 'INDIRECT_LOOKUP',
  Personname = 'PERSONNAME',
  Plaintextarea = 'PLAINTEXTAREA',
  Richtextarea = 'RICHTEXTAREA',
  SwitchablePersonname = 'SWITCHABLE_PERSONNAME'
}

export enum LayoutComponentType {
  Canvas = 'CANVAS',
  CustomLink = 'CUSTOM_LINK',
  EmptySpace = 'EMPTY_SPACE',
  Field = 'FIELD',
  ReportChart = 'REPORT_CHART',
  VisualforcePage = 'VISUALFORCE_PAGE'
}

export enum LayoutMode {
  Create = 'CREATE',
  Edit = 'EDIT',
  View = 'VIEW'
}

export enum LayoutType {
  Compact = 'COMPACT',
  Full = 'FULL'
}

export enum ResultOrder {
  Asc = 'ASC',
  Desc = 'DESC'
}

export enum TabOrder {
  LeftRight = 'LEFT_RIGHT',
  TopDown = 'TOP_DOWN'
}

export enum UiBehavior {
  Edit = 'EDIT',
  Readonly = 'READONLY',
  Required = 'REQUIRED'
}

export type GetAccountsQueryVariables = Exact<{
  first?: InputMaybe<Scalars['Int']['input']>;
}>;


export type GetAccountsQuery = { uiapi: { query: { Account?: { edges?: Array<{ node?: { Id: string, Name?: { value?: string | null } | null, Industry?: { value?: string | null } | null, AnnualRevenue?: { value?: number | null, displayValue?: string | null } | null } | null } | null> | null } | null } } };

export type UpdateAccountMutationVariables = Exact<{
  id: Scalars['IdOrRef']['input'];
  account: AccountUpdateRepresentation;
}>;


export type UpdateAccountMutation = { uiapi: { AccountUpdate?: { success?: boolean | null, Record?: { Id: string, Name?: { value?: string | null } | null, Industry?: { value?: string | null } | null, AnnualRevenue?: { displayValue?: string | null } | null } | null } | null } };
