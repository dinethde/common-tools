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
import ballerina/http;
import ballerina/log;

# Check if the user has necessary permissions.
# 
# + requiredRoles - Required Role list
# + userRoles - Roles list, The user has
# + return - Allow or not
public isolated function checkPermissions(string[] requiredRoles, string[] userRoles) returns boolean {
    if userRoles.length() == 0 && requiredRoles.length() > 0 {
        return false;
    }

    final string[] & readonly userRolesReadOnly = userRoles.cloneReadOnly();
    return requiredRoles.every(role => userRolesReadOnly.indexOf(role) !is ());
}

# Clean up prefixes in the groups.
# 
# + groups - Array of Groups to clean up
# + return - Array of cleaned role display names
public isolated function cleanUpRoles(Groups[] groups) returns string[] {
        return groups.map(r => 
            r.display.startsWith("DEFAULT/") 
                ? r.display.substring(8) 
                : r.display
        );
}

# Clean prefix in the username.
# 
# + username - The username to clean up
# + return - The cleaned username with "DEFAULT/" prefix removed if present
public isolated function cleanUpUsername(string username) returns string {
    return username.startsWith("DEFAULT/") ? username.substring(8) : username;
}
