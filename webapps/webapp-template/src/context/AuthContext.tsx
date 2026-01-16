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
import { useAsgardeo } from "@asgardeo/react";
import { useIdleTimer } from "react-idle-timer";

import React, { useContext, useEffect, useState } from "react";

import PreLoader from "@component/common/PreLoader";
import SessionWarningDialog from "@component/common/SessionWarningDialog";
import LoginScreen from "@component/ui/LoginScreen";
import { redirectUrl } from "@config/constant";
import { useLazyGetUserInfoQuery } from "@root/src/services/user.api";
import { setTokens } from "@services/BaseQuery";
import { loadPrivileges, setAuthError, setUserAuthData } from "@slices/authSlice/auth";
import { useAppDispatch } from "@slices/store";

type AuthContextType = {
  appSignIn: () => void;
  appSignOut: () => void;
};

enum AppState {
  Loading = "loading",
  Unauthenticated = "unauthenticated",
  Authenticating = "authenticating",
  Authenticated = "authenticated",
}

const AuthContext = React.createContext<AuthContextType>({} as AuthContextType);

// Session timeout: 15 minutes in milliseconds
const timeout = 15 * 60 * 1000;
// Show warning 4 seconds before session timeout
const promptBeforeIdle = 4_000;

const AppAuthProvider = (props: { children: React.ReactNode }) => {
  const [sessionWarningOpen, setSessionWarningOpen] = useState<boolean>(false);
  const [appState, setAppState] = useState<AppState>(AppState.Loading);

  const dispatch = useAppDispatch();

  // useLazyGetUserInfoQuery returns a trigger function that can be called manually
  const [triggerGetUserInfo] = useLazyGetUserInfoQuery();

  const onPrompt = () => {
    appState === AppState.Authenticated && setSessionWarningOpen(true);
  };

  useEffect(() => {
    if (!localStorage.getItem(redirectUrl)) {
      localStorage.setItem(redirectUrl, window.location.href.replace(window.location.origin, ""));
    }
  }, []);

  const { activate } = useIdleTimer({
    onPrompt,
    timeout,
    promptBeforeIdle,
    throttle: 500,
  });

  const handleContinue = () => {
    setSessionWarningOpen(false);
    activate();
  };

  const {
    signIn,
    signOut,
    getDecodedIdToken,
    user,
    signInSilently,
    getAccessToken,
    isLoading,
    isSignedIn,
  } = useAsgardeo();

  const setupAuthenticatedUser = async () => {
    const [decodedIdToken, accessToken] = await Promise.all([
      getDecodedIdToken(),
      getAccessToken(),
    ]);

    dispatch(
      setUserAuthData({
        userInfo: user,
        decodedIdToken: decodedIdToken,
      }),
    );

    console.log("decoded id token : ", decodedIdToken);

    setTokens(accessToken, refreshToken, appSignOut);
    await triggerGetUserInfo();

    await dispatch(loadPrivileges());
  };

  useEffect(() => {
    let mounted = true;

    const initializeAuth = async () => {
      try {
        setAppState(AppState.Loading);

        if (isLoading) return;

        if (isSignedIn) {
          setAppState(AppState.Authenticating);
          await setupAuthenticatedUser();

          if (mounted) setAppState(AppState.Authenticated);
        } else {
          const silentSignInSuccess = await signInSilently();

          if (mounted)
            setAppState(silentSignInSuccess ? AppState.Authenticating : AppState.Unauthenticated);
        }
      } catch (err) {
        if (mounted) {
          dispatch(setAuthError());
        }
      }
    };

    initializeAuth();

    return () => {
      mounted = false;
    };
  }, [isSignedIn, isLoading]);

  const refreshToken = async (): Promise<{ accessToken: string }> => {
    try {
      const accessToken = await getAccessToken();
      return { accessToken };
    } catch (error) {
      console.error("Token refresh failed: ", error);
      await appSignOut();
      throw error;
    }
  };

  const appSignOut = async () => {
    setAppState(AppState.Loading);
    await signOut();
    setAppState(AppState.Unauthenticated);
  };

  const appSignIn = async () => {
    await signIn();
    setAppState(AppState.Loading);
  };

  const authContext: AuthContextType = {
    appSignIn: appSignIn,
    appSignOut: appSignOut,
  };

  const renderContent = () => {
    switch (appState) {
      case AppState.Loading:
        return <PreLoader isLoading message="Authenticating ..." />;

      case AppState.Authenticating:
        return <PreLoader isLoading message="Loading User Info ..." />;

      case AppState.Authenticated:
        return <AuthContext.Provider value={authContext}>{props.children}</AuthContext.Provider>;

      case AppState.Unauthenticated:
        return (
          <AuthContext.Provider value={authContext}>
            <LoginScreen />
          </AuthContext.Provider>
        );

      default:
        return null;
    }
  };

  return (
    <>
      <SessionWarningDialog
        open={sessionWarningOpen}
        handleContinue={handleContinue}
        appSignOut={appSignOut}
      />

      {renderContent()}
    </>
  );
};

const useAppAuthContext = (): AuthContextType => useContext(AuthContext);

export { useAppAuthContext };

export default AppAuthProvider;

/*

{
    "isk": "32a2f8c16ffdefd72a2cd5db4161af3259c30674d0072bb6d119327cd9d368a2",
    "at_hash": "F-9TqrEMc8_Za-u9jBzKjQ",
    "sub": "6387963b-c0b4-4268-b77c-b27513d713b3",
    "amr": [
        "BasicAuthenticator",
        "totp"
    ],
    "iss": "https://api.asgardeo.io/t/wso2/oauth2/token",
    "sid": "f78f1157-7f90-4134-8c36-0888b0e484e3",
    "c_hash": "pENd-U74V0e2ADpLJx-19g",
    "aud": [
        "WyZdatcRw0U0QJ4Wl22Wnx_lf7Ua",
        "choreo:deployment:sandbox"
    ],
    "nbf": 1768578931,
    "azp": "WyZdatcRw0U0QJ4Wl22Wnx_lf7Ua",
    "org_id": "11737422-7078-8510-1074-820892631194",
    "org_name": "wso2",
    "exp": 1768582531,
    "iat": 1768578931,
    "jti": "4e06ad2e-6a28-45e1-8d47-70278d8a3e58",
    "org_handle": "wso2"
}
*/
