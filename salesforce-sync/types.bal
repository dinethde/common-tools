// Copyright (c) 2025 WSO2 LLC. (https://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License. 
import ballerina/time;

# Service supported sync types/objects
enum SyncObject {
    ACCOUNT,
    OPPORTUNITY
}

# Sync log statuses used on the log table in database
enum LogStatus {
    PROCESSING = "Processing",
    COMPLETED = "Completed",
    FAILED = "Failed"
}

// [Config record types]
# Salesforce sync configuration.
# 
# + enabled - Enable/disable sync
# + periodInHours - Time (minimum) period between sync in hours
# + soqlQuery - Salesforce SOQL sync query
type SfSyncConf record {
    boolean enabled;
    decimal periodInHours;
    string soqlQuery;
};

# Salesforce sync minimal configuration.
# 
# + enabled - Enable/disable sync
# + periodInHours - Time (minimum) period between sync in hours
type SfSyncMinimalConf record {
    boolean enabled;
    decimal periodInHours;
};

# [Configurable] Salesforce service configuration.
# 
# + refreshUrl - OAuth2 refresh token endpoint
# + refreshToken - OAuth2 refresh token
# + clientId - OAuth2 client ID
# + clientSecret - OAuth2 client secret
type SalesforceAuthConf record {|
    string refreshUrl;
    string refreshToken;
    string clientId;
    string clientSecret;
|};

# [Configurable] MySQL Database configuration.
# 
# + host - Hostname
# + user - Username
# + password - Password
# + database - Default database
type DatabaseConf record {|
    string host;
    string user;
    string password;
    string database;
|};

# [Util] Salesforce API response error record
# 
# + errorCode - Salesforce generated error code
# + message - Error message
type SalesforceResponseError record {
    string errorCode;
    string message;
};

// [Database record types]
# [Database] Sync log time retrieval record.
# 
# + id - Database row ID
# + start_time - Sync start time
# + end_time - Sync end time
type DBSyncLogTimes record {|
    int id;
    time:Utc start_time;
    time:Utc end_time;
|};

// [Salesforce record types]
# [Salesforce] Account sync query record.
# 
# + Id - Account ID
# + Name - Account name
# + BillingCountry - Billing country
# + ShippingCountry - Shipping country
# + Sales_Regions__c - Sales regions
# + Sub_Region__c - Sales sub-region
# + NAICS_Industry__c - NAICS Industry
# + Sub_Industry__c - NAICS sub-industry
# + Account_Classification__c - Account classification
# + ARR_Churn_Date__c - Churn date of the ARR account
# + Owner - Account owner details
type SFAccountSyncRecord record {
    string Id;
    string Name;
    string? BillingCountry;
    string? ShippingCountry;
    string? Sales_Regions__c;
    string? Sub_Region__c;
    string? NAICS_Industry__c;
    string? Sub_Industry__c;
    string? Account_Classification__c;
    string? ARR_Churn_Date__c;
    record {
        string Email;
        string Name;
    } Owner;
};

# [Salesforce] Opportunity sync query record.
#
# + Id - Opportunity ID
# + Name - Opportunity name
# + AccountId - Account ID
# + CloseDate - Opportunity close date
# + StageName - Opportunity stage
# + Confidence__c - 
# + Entry_Vector__c - 
# + Primary_Partner_Role__c - 
# + Renewal_Delayed__c - 
# + ARR__c - 
# + IAM_ARR__c - 
# + APIM_ARR__c -
# + Integration_ARR__c - 
# + Open_Banking_ARR__c - 
# + Delayed_ARR__c - 
# + IAM_Delayed_ARR__c - 
# + APIM_Delayed_ARR__c -
# + Integration_Delayed__c - 
# + Cloud_ARR_Opportunity__c - 
# + IAM_BU_ARR_Opportunity__c - 
# + APIM_ARR_Opportunity__c - APIM ARR opportunity amount
# + Integration_BU_ARR_Opportunity__c - 
# + Choreo_ARR_Opportunity__c - Choreo ARR opportunity amount
# + IAM_PSO__c -
# + APIM_PSO__c - APIM PSO amount
# + Integration_PSO__c - 
# + Choreo_PSO__c -Choreo PSO amount
# + Cloud_ARR__c - Cloud ARR amount
# + IAM_Cloud_ARR__c - IAM cloud ARR amount
# + Integration_Cloud_ARR__c - Integration Cloud ARR amount
# + Choreo_ARR__c - Choreo ARR amount
# + APIM_Cloud_ARR__c - APIM Cloud ARR amount
# + CL_ARR_Today__c - 
# + ARR_Cloud_ARR__c - Total Software + Cloud Products ARR value
# + IAM_ARR_AND_Cloud__c - IAM Software and Cloud ARR value
# + Integration_ARR_AND_Cloud__c - Integration Software and Cloud ARR value
# + APIM_ARR_Cloud__c - APIM Software and Cloud ARR value
# + Subs_Start_Date__c - Subscription Start Date (including cloud fields)
# + Subs_End_Date__c - Subscription End Date (including cloud fields)
# + Direct_Channel__c - Direct Channel information
# + Forecast_Type1__c - Forecast type
# + CL_Start_Date_Roll_Up__c - 
# + CL_End_Date_Roll_Up__c - 
# + PS_Support_Account_Start_Date_Roll_Up__c - 
# + PS_Support_Account_End_Date_Roll_Up__c - 
# + PS_Start_Date_Roll_Up__c - 
# + PS_End_Date_Roll_Up__c - 
# + Subscription_Start_Date__c - Subscription start date
# + Subscription_End_Date__c - Subscription end date
# + Owner - Account owner details
# + Add_to_Forecast__c - Add to forecast (True/False)
# + RecordType - Opportunity record type details
type SFOpportunitySyncRecord record {
    string Id;
    string Name;
    string AccountId;
    string CloseDate;
    string StageName;
    string? Confidence__c;
    string? Primary_Partner_Role__c;
    string? Entry_Vector__c;
    boolean Renewal_Delayed__c;
    decimal ARR__c;
    decimal IAM_ARR__c;
    decimal APIM_ARR__c;
    decimal Integration_ARR__c;
    decimal Open_Banking_ARR__c;
    decimal Delayed_ARR__c;
    decimal IAM_Delayed_ARR__c;
    decimal APIM_Delayed_ARR__c;
    decimal Integration_Delayed__c;
    decimal? Cloud_ARR_Opportunity__c;
    decimal? IAM_BU_ARR_Opportunity__c;
    decimal? APIM_ARR_Opportunity__c;
    decimal? Integration_BU_ARR_Opportunity__c;
    decimal? Choreo_ARR_Opportunity__c; 
    decimal? IAM_PSO__c;
    decimal? APIM_PSO__c;
    decimal? Integration_PSO__c;
    decimal? Choreo_PSO__c;
    decimal? Cloud_ARR__c;
    decimal? IAM_Cloud_ARR__c;
    decimal? Integration_Cloud_ARR__c;
    decimal? Choreo_ARR__c;
    decimal? APIM_Cloud_ARR__c;
    decimal CL_ARR_Today__c;
    decimal? ARR_Cloud_ARR__c;
    decimal? IAM_ARR_AND_Cloud__c;
    decimal? Integration_ARR_AND_Cloud__c;
    decimal? APIM_ARR_Cloud__c;
    string? Subs_Start_Date__c;
    string? Subs_End_Date__c;
    string? Direct_Channel__c;
    string? Forecast_Type1__c;
    string? CL_Start_Date_Roll_Up__c;
    string? CL_End_Date_Roll_Up__c;
    string? PS_Support_Account_Start_Date_Roll_Up__c;
    string? PS_Support_Account_End_Date_Roll_Up__c;
    string? PS_Start_Date_Roll_Up__c;
    string? PS_End_Date_Roll_Up__c;
    string? Subscription_Start_Date__c;
    string? Subscription_End_Date__c;
    boolean Add_to_Forecast__c;
    record {
        string Email;
        string Name;
    } Owner;
    SFRecordType? RecordType;
};

# Type representing RecordType table in SF.
#
# + Name - Name of the record type (Renewal, Expansion, First Sale etc.)
public type SFRecordType record {
    string? Name;
};
